-- :NamedMan — render `man named.conf` into a scratch buffer wired to the
-- plugin's documentation hover: press K (or :NamedDocs) on any statement name
-- in the man page to get the same knowledge-base popup a real named.conf gets.
--
-- The buffer gets the 'man' dialect: man-page prose has no enclosing clause,
-- so hover looks the word up across every clause's statement table instead
-- (see knowledge.lookup_any). None of the clause machinery (folding, brace
-- checks, semantic colours, named-checkconf) attaches.
local M = {}

M.BUFNAME = 'named-conf://man/named.conf'

--- Strip nroff overstrike sequences (`c\bc` bold, `_\bc` underline) that some
--- man implementations emit even when piped.
---@param s string
---@return string
local function clean(s)
  while s:find('\b', 1, true) do
    local out, n = s:gsub('.\b', '')
    if n == 0 then
      out = s:gsub('\b', '')
    end
    s = out
  end
  return s
end

--- The rendered man page as a list of lines.
---@return string[]|nil lines, string|nil err
local function man_lines()
  if vim.fn.executable('man') ~= 1 then
    return nil, '`man` is not on $PATH'
  end
  local res = vim.system({ 'man', 'named.conf' }, {
    text = true,
    env = { MANPAGER = 'cat', PAGER = 'cat', MANWIDTH = '78' },
  }):wait()
  if res.code ~= 0 or not res.stdout or res.stdout == '' then
    local err = (res.stderr or ''):gsub('%s+$', '')
    return nil, err ~= '' and err or ('man exited with code ' .. res.code)
  end
  local lines = vim.split(res.stdout, '\n', { plain = true })
  if lines[#lines] == '' then
    table.remove(lines)
  end
  for i, l in ipairs(lines) do
    lines[i] = clean(l)
  end
  return lines
end

--- Markdown docs for position (row, col) (0-indexed) in a man-page buffer.
--- Called from hover.markdown for buffers with the 'man' dialect.
---@param bufnr integer
---@param row integer
---@param col integer
---@return string|nil
function M.markdown(bufnr, row, col)
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ''
  local word = require('named-conf.context')._word_at(line, col)
  if not word or word == '' then
    return nil
  end
  local kb = require('named-conf.knowledge')
  local entry, clause = kb.lookup_any(word)
  if entry then
    return kb.render(word, entry, clause and { clause = clause } or nil)
  end
  -- Built-in ACL names (any, none, localhost, localnets) still hover.
  local ventry = kb.lookup_value(word, nil, nil)
  if ventry then
    return kb.render(word, ventry, nil)
  end
  return nil
end

--- Wire the documentation hover to a buffer holding man-page text: the 'man'
--- dialect, the docs LSP (hover only), and a buffer-local K map that works
--- even when the LSP or the user's own hover keymap is absent (it also
--- overrides the K map the man ftplugin installs).
---@param bufnr integer
function M.attach(bufnr)
  vim.api.nvim_buf_set_var(bufnr, 'named_conf_dialect', 'man')
  pcall(function()
    require('named-conf.lsp').start(bufnr, { name = 'named-conf', hover = true, completion = false })
  end)
  vim.keymap.set('n', 'K', function() require('named-conf.hover').show() end,
    { buffer = bufnr, desc = 'BIND docs for the statement under the cursor' })
  vim.keymap.set('n', 'q', function() pcall(vim.cmd.close) end,
    { buffer = bufnr, nowait = true, desc = 'Close the man page' })
end

local function find_existing()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b)
      and vim.api.nvim_buf_get_name(b):find(M.BUFNAME, 1, true) then
      return b
    end
  end
  return nil
end

--- Open (or focus) `man named.conf` in a hover-enabled scratch buffer.
---@return integer|nil bufnr
function M.open()
  local existing = find_existing()
  if existing then
    local win = vim.fn.bufwinid(existing)
    if win ~= -1 then
      vim.api.nvim_set_current_win(win)
    else
      vim.cmd(('botright sbuffer %d'):format(existing))
    end
    return existing
  end

  local lines, err = man_lines()
  if not lines then
    vim.notify('[named] failed to render man named.conf: ' .. err, vim.log.levels.ERROR)
    return nil
  end

  vim.cmd('botright new')
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(bufnr, M.BUFNAME)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  local bo = vim.bo[bufnr]
  bo.buftype = 'nofile'
  bo.swapfile = false
  bo.bufhidden = 'hide'
  bo.modified = false
  -- man syntax highlighting; its ftplugin K map is overridden by attach().
  bo.filetype = 'man'
  bo.modifiable = false

  M.attach(bufnr)
  return bufnr
end

return M
