-- Run `named-checkconf` over the buffer and surface its output as diagnostics.
--
-- The command, its flags, and a chroot directory are all user-configurable
-- (config.checkconf): `cmd` is the executable, `args` are extra flags passed
-- verbatim (e.g. `{ '-z' }` to test-load zones), and `chroot` is a convenience
-- that becomes `-t <dir>` for chrooted installs.
--
-- named-checkconf reads the config from disk, so when the buffer is modified and
-- `use_buffer` is set we write its contents to a temp file *in the same
-- directory* (so relative `include` paths still resolve) and check that. A
-- chroot can't see that temp file, so with both a chroot and unsaved changes we
-- fall back to the on-disk file and say so.
local config = require('named-conf.config')

local M = {}

M.ns = vim.api.nvim_create_namespace('named-conf-checkconf')

---@param msg string
---@param level integer|nil
local function notify(msg, level)
  vim.schedule(function()
    vim.notify('[named] ' .. msg, level or vim.log.levels.INFO)
  end)
end

--- Build the argv for the configured command checking `target` (a file path).
---@param target string
---@return string[]
local function build_argv(target)
  local cc = config.options.checkconf
  local argv = { cc.cmd }
  if cc.chroot and cc.chroot ~= '' then
    argv[#argv + 1] = '-t'
    argv[#argv + 1] = cc.chroot
  end
  for _, a in ipairs(cc.args or {}) do
    argv[#argv + 1] = a
  end
  argv[#argv + 1] = target
  return argv
end

--- Parse `named-checkconf` output into a list of { file, lnum (1-based), text }.
--- Recognises `file:line: message` (the standard error format). Lines that do
--- not match are returned with file=nil so callers can show them as context.
---@param out string
---@return table[]
function M.parse_output(out)
  local results = {}
  for line in (out or ''):gmatch('[^\r\n]+') do
    local file, lnum, text = line:match('^(.-):(%d+):%s*(.*)$')
    if file and lnum then
      results[#results + 1] = { file = file, lnum = tonumber(lnum), text = text }
    elseif vim.trim(line) ~= '' then
      results[#results + 1] = { file = nil, lnum = nil, text = vim.trim(line) }
    end
  end
  return results
end

--- Turn parsed output into diagnostics for `bufnr`, given the path that was
--- actually checked (`target`). Messages about other files (includes) are
--- pinned to line 1 with the filename in the message.
---@param parsed table[]
---@param target string
---@return table[]
local function to_diagnostics(parsed, target)
  local sev = vim.diagnostic.severity
  local target_real = vim.fn.fnamemodify(target, ':p')
  local diags = {}
  for _, p in ipairs(parsed) do
    if p.file and p.lnum then
      local same = vim.fn.fnamemodify(p.file, ':p') == target_real
        or vim.fn.fnamemodify(p.file, ':t') == vim.fn.fnamemodify(target, ':t')
      local severity = p.text:lower():match('warning') and sev.WARN or sev.ERROR
      diags[#diags + 1] = {
        lnum = (same and p.lnum or 1) - 1,
        col = 0,
        severity = severity,
        message = same and p.text or string.format('%s:%d: %s', p.file, p.lnum, p.text),
        source = 'named-checkconf',
      }
    end
  end
  return diags
end

--- Resolve the path to check; returns (path, is_temp, note).
---@param bufnr integer
---@return string|nil path, boolean is_temp, string|nil note
local function resolve_target(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' then
    return nil, false, 'buffer has no file name'
  end
  local modified = vim.api.nvim_get_option_value('modified', { buf = bufnr })
  local cc = config.options.checkconf
  if not (modified and cc.use_buffer) then
    return name, false, nil
  end
  if cc.chroot and cc.chroot ~= '' then
    -- A temp file outside the chroot wouldn't be visible; check on-disk.
    return name, false, 'buffer modified — checked the saved file (chroot set)'
  end
  local dir = vim.fs.dirname(name)
  local base = vim.fn.fnamemodify(name, ':t')
  local tmp = dir .. '/.' .. base .. '.nvim-named-check'
  local ok = pcall(vim.fn.writefile, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), tmp)
  if not ok then
    return name, false, 'could not write temp file — checked the saved file'
  end
  return tmp, true, nil
end

--- Run named-checkconf for a buffer and publish diagnostics.
---@param bufnr integer|nil
---@param opts { silent?: boolean }|nil
function M.run(bufnr, opts)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  opts = opts or {}
  if not config.options.checkconf.enabled then
    return
  end

  local cc = config.options.checkconf
  if vim.fn.executable(cc.cmd) ~= 1 then
    if not opts.silent then
      notify(("'%s' not found (set checkconf.cmd)"):format(cc.cmd), vim.log.levels.ERROR)
    end
    return
  end

  local target, is_temp, note = resolve_target(bufnr)
  if not target then
    if not opts.silent then
      notify(note or 'nothing to check', vim.log.levels.WARN)
    end
    return
  end
  if note and not opts.silent then
    notify(note, vim.log.levels.WARN)
  end

  local argv = build_argv(target)
  vim.system(argv, { text = true }, function(res)
    if is_temp then
      pcall(vim.fn.delete, target)
    end
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end
      local out = (res.stdout or '') .. '\n' .. (res.stderr or '')
      local parsed = M.parse_output(out)
      local diags = to_diagnostics(parsed, target)
      vim.diagnostic.set(M.ns, bufnr, diags)

      if opts.silent then
        return
      end
      if res.code == 0 and #diags == 0 then
        notify('named-checkconf: OK')
      elseif res.code == 0 then
        notify(('named-checkconf: OK (%d warning(s))'):format(#diags))
      else
        local first = diags[1] and diags[1].message or vim.trim(out)
        notify('named-checkconf failed: ' .. first, vim.log.levels.ERROR)
      end
    end)
  end)
end

--- Attach the on-save hook to a buffer.
---@param bufnr integer
function M.setup_buffer(bufnr)
  if not config.options.checkconf.on_save then
    return
  end
  local group = require('named-conf.detect').augroup
  vim.api.nvim_create_autocmd('BufWritePost', {
    buffer = bufnr, group = group,
    callback = function() M.run(bufnr, { silent = true }) end,
  })
end

return M
