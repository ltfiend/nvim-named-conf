-- File detection and per-buffer attach for named-conf.nvim
local config = require('named-conf.config')

local M = {}

M.augroup = vim.api.nvim_create_augroup('NamedConf', { clear = true })

--- Convert a shell-style glob (e.g. "named.conf.*") to a Lua pattern.
---@param glob string
---@return string
local function glob_to_pattern(glob)
  local pat = glob:gsub('[%(%)%.%%%+%-%[%]%^%$]', '%%%1')
  pat = pat:gsub('%*', '.*')
  pat = pat:gsub('%?', '.')
  return '^' .. pat .. '$'
end

--- Does the given filename basename match any configured detection pattern?
---@param name string  basename of the file
---@return boolean
function M.matches_name(name)
  if not name or name == '' then
    return false
  end
  for _, glob in ipairs(config.options.detect.patterns) do
    if name:match(glob_to_pattern(glob)) then
      return true
    end
  end
  return false
end

--- Does the given filetype match any configured detection filetype?
---@param ft string|nil
---@return boolean
function M.matches_ft(ft)
  if not ft or ft == '' then
    return false
  end
  return vim.tbl_contains(config.options.detect.filetypes, ft)
end

--- Decide whether a buffer (by full path + filetype) should be attached.
---@param path string  full buffer name
---@param ft string|nil  filetype
---@return boolean
function M.should_attach(path, ft)
  if M.matches_ft(ft) then
    return true
  end
  local name = vim.fn.fnamemodify(path or '', ':t')
  return M.matches_name(name)
end

--- The config dialect for a file basename: 'rndc' for rndc.conf / rndc.key
--- style files (whose options/server schema differs from named.conf), else
--- 'named'. Drives schema scoping and skips named-checkconf for rndc files.
---@param name string|nil  basename
---@return string  'rndc' | 'named'
function M.dialect_for(name)
  name = name or ''
  if name:match('^rndc%.conf') or name:match('%.rndc%.conf$') or name:match('^rndc%.key$') then
    return 'rndc'
  end
  return 'named'
end

--- Whether a buffer has been attached (opted in).
---@param bufnr integer
---@return boolean
function M.is_attached(bufnr)
  local ok, val = pcall(vim.api.nvim_buf_get_var, bufnr, 'named_conf')
  return ok and val == true
end

--- Attach named-conf features to a buffer.
---@param bufnr integer|nil
function M.attach(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if M.is_attached(bufnr) then
    return
  end
  vim.api.nvim_buf_set_var(bufnr, 'named_conf', true)

  local dialect = M.dialect_for(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t'))
  vim.api.nvim_buf_set_var(bufnr, 'named_conf_dialect', dialect)

  if config.options.fold.enabled then
    require('named-conf.fold').setup_buffer(bufnr)
  end
  if config.options.validate.enabled then
    require('named-conf.validate').setup_buffer(bufnr)
  end
  if config.options.highlight.enabled then
    require('named-conf.highlight').setup_buffer(bufnr)
  end
  -- named-checkconf validates named.conf, not rndc.conf — skip it for rndc.
  if config.options.checkconf.enabled and dialect ~= 'rndc' then
    require('named-conf.checkconf').setup_buffer(bufnr)
  end
  if config.options.lsp.enabled then
    pcall(function() require('named-conf.lsp').start(bufnr) end)
  end

  vim.api.nvim_exec_autocmds('User', { pattern = 'NamedConfAttach', data = { bufnr = bufnr } })
end

--- Register the autocmds that detect and attach named.conf files.
function M.setup_autocmds()
  vim.api.nvim_clear_autocmds({ group = M.augroup })

  -- Re-define and re-apply colour coding when the colorscheme changes (a new
  -- scheme clears highlight groups).
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = M.augroup,
    callback = function()
      if not config.options.highlight.enabled then
        return
      end
      local hl = require('named-conf.highlight')
      hl.define_highlights()
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) and M.is_attached(b) then
          hl.apply(b)
        end
      end
    end,
  })

  if not config.options.detect.enabled then
    return
  end

  -- Filetype-driven (covers Neovim's built-in named.conf/rndc.conf detection).
  vim.api.nvim_create_autocmd('FileType', {
    group = M.augroup,
    pattern = config.options.detect.filetypes,
    callback = function(args)
      M.attach(args.buf)
    end,
  })

  -- Filename-driven (covers split configs / non-standard names that don't get
  -- the `named` filetype automatically).
  vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
    group = M.augroup,
    pattern = '*',
    callback = function(args)
      local name = vim.fn.fnamemodify(args.file, ':t')
      if M.matches_name(name) then
        M.attach(args.buf)
      end
    end,
  })
end

return M
