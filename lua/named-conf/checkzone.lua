-- Run `named-checkzone` over a zone data file and surface its output as
-- diagnostics. The zone-file sibling of checkconf.lua, with one extra wrinkle:
-- named-checkzone needs the zone ORIGIN as its first argument, which we derive
-- from (in order) config, an explicit `:NamedCheck <origin>` argument, the
-- file's `$ORIGIN` directive, or the filename (`db.example.com`,
-- `example.com.zone`, `example.com.db`, or a bare `example.com`).
--
-- Like named-checkconf, the binary reads from disk: a modified buffer is
-- written to a temp file in the same directory (so `$INCLUDE` paths resolve)
-- when `use_buffer` is set.
local config = require('named-conf.config')

local M = {}

M.ns = vim.api.nvim_create_namespace('named-conf-checkzone')

---@param msg string
---@param level integer|nil
local function notify(msg, level)
  vim.schedule(function()
    vim.notify('[named] ' .. msg, level or vim.log.levels.INFO)
  end)
end

--- Derive the zone origin for a buffer, or nil when it cannot be determined.
---@param bufnr integer
---@return string|nil
function M.origin_for(bufnr)
  local cz = config.options.checkzone
  if cz.origin and cz.origin ~= '' then
    return cz.origin
  end
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    local origin = line:match('^%s*%$[Oo][Rr][Ii][Gg][Ii][Nn]%s+(%S+)')
    if origin then
      return origin
    end
  end
  return M.origin_from_name(vim.api.nvim_buf_get_name(bufnr))
end

--- The origin implied by a zone file's name, or nil.
--- `db.example.com` / `example.com.zone` / `example.com.db` -> `example.com`;
--- a bare dotted name (`example.com`) is taken as-is.
---@param path string|nil
---@return string|nil
function M.origin_from_name(path)
  local base = vim.fn.fnamemodify(path or '', ':t')
  if base == '' then
    return nil
  end
  local origin = base
    :gsub('%.signed$', '')
    :gsub('^db%.', '')
    :gsub('%.zone$', '')
    :gsub('%.db$', '')
  if origin == '' then
    return nil
  end
  -- Only trust the result when the name carried a zone-ish marker: a db.
  -- prefix, a known extension, or at least one interior dot (example.com).
  -- An extensionless single label ("hosts") is not a usable origin.
  if origin == base and not base:match('%..') then
    return nil
  end
  if not origin:match('^[%w%.%-_]+$') then
    return nil
  end
  return origin
end

--- Parse `named-checkzone` output into { file, lnum (1-based), text } rows.
--- Errors look like `dns_rdata_fromtext: /path/db.example:5: near 'x': ...` or
--- `/path/db.example:12: unknown RR type 'AAAAA'`; summary lines
--- (`zone example.com/IN: loaded serial 2024010101`) have no file:line and are
--- kept with file=nil as context.
---@param out string
---@return table[]
function M.parse_output(out)
  local results = {}
  for line in (out or ''):gmatch('[^\r\n]+') do
    local file, lnum, text = line:match('^(.-):(%d+):%s*(.*)$')
    if file and lnum then
      -- Strip a leading `routine-name: ` prefix so `file` is a real path.
      file = file:match('([^%s:]+)$') or file
      results[#results + 1] = { file = file, lnum = tonumber(lnum), text = text }
    elseif vim.trim(line) ~= '' then
      results[#results + 1] = { file = nil, lnum = nil, text = vim.trim(line) }
    end
  end
  return results
end

--- Turn parsed output into diagnostics for `bufnr`, given the path actually
--- checked. Messages about other files ($INCLUDEs) pin to line 1 with the
--- filename in the message.
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
        source = 'named-checkzone',
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
  if not (modified and config.options.checkzone.use_buffer) then
    return name, false, nil
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

--- Run named-checkzone for a buffer and publish diagnostics.
---@param bufnr integer|nil
---@param opts { silent?: boolean, origin?: string }|nil
function M.run(bufnr, opts)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  opts = opts or {}
  local cz = config.options.checkzone
  if not cz.enabled then
    return
  end

  if vim.fn.executable(cz.cmd) ~= 1 then
    if not opts.silent then
      notify(("'%s' not found (set checkzone.cmd)"):format(cz.cmd), vim.log.levels.ERROR)
    end
    return
  end

  local origin = opts.origin or M.origin_for(bufnr)
  if not origin then
    if not opts.silent then
      notify('cannot determine the zone origin — add a $ORIGIN directive or run :NamedCheck <origin>',
        vim.log.levels.ERROR)
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

  local argv = { cz.cmd }
  for _, a in ipairs(cz.args or {}) do
    argv[#argv + 1] = a
  end
  argv[#argv + 1] = origin
  argv[#argv + 1] = target

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
        local serial = out:match('loaded serial (%d+)')
        notify('named-checkzone: OK' .. (serial and (' (serial ' .. serial .. ')') or ''))
      elseif res.code == 0 then
        notify(('named-checkzone: OK (%d warning(s))'):format(#diags))
      else
        local first = diags[1] and diags[1].message or vim.trim(out)
        notify('named-checkzone failed: ' .. first, vim.log.levels.ERROR)
      end
    end)
  end)
end

--- Attach the on-save hook to a buffer.
---@param bufnr integer
function M.setup_buffer(bufnr)
  if not config.options.checkzone.on_save then
    return
  end
  local group = require('named-conf.detect').augroup
  vim.api.nvim_create_autocmd('BufWritePost', {
    buffer = bufnr, group = group,
    callback = function() M.run(bufnr, { silent = true }) end,
  })
end

return M
