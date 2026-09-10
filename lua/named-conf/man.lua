-- :NamedMan — load the named.conf(5) man page shipped with the installed BIND
-- into an immutable scratch buffer wired to the plugin's documentation hover.
-- The page is a complete enumeration of the configuration grammar, so it
-- doubles as a browsable index: press K (or :NamedDocs) on any statement name
-- to get the knowledge-base popup a real named.conf gets.
--
-- The buffer gets the 'man' dialect: man-page prose has no enclosing clause,
-- so hover looks the word up across every clause's statement table instead
-- (see knowledge.lookup_any). None of the clause machinery attaches.
local M = {}

M.BUFNAME = 'named-conf://man/named.conf'

-- Rendered page lines, cached for the session (the installed page is static).
local cache

--- Strip nroff overstrike sequences (`c\bc` bold, `_\bc` underline).
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

--- Locate the named.conf(5) page file installed with BIND. Uses `man -w`,
--- verifying it names a real file (Ubuntu's minimized-system stub exits 0
--- while printing a notice), then falls back to the standard man dirs.
---@return string|nil path
function M.page_path()
  if vim.fn.executable('man') == 1 then
    local out = vim.trim(vim.fn.system({ 'man', '-w', 'named.conf' }))
    if vim.v.shell_error == 0 and vim.fn.filereadable(out) == 1 then
      return out
    end
  end
  for _, pat in ipairs({
    '/usr/share/man/man5/named.conf.5*',
    '/usr/local/share/man/man5/named.conf.5*',
  }) do
    local hits = vim.fn.glob(pat, true, true)
    if hits[1] then
      return hits[1]
    end
  end
  return nil
end

--- The installed page rendered to text lines (cached per session).
---@return string[]|nil lines, string|nil err
local function page_lines()
  if cache then
    return cache
  end
  local path = M.page_path()
  if not path then
    return nil, 'named.conf(5) man page not found — is BIND installed?'
  end
  local res = vim.system({ 'man', '-l', path }, {
    text = true,
    env = { MANWIDTH = '78', MANPAGER = 'cat', PAGER = 'cat' },
  }):wait()
  if res.code ~= 0 or not res.stdout or res.stdout == '' then
    local err = (res.stderr or ''):gsub('%s+$', '')
    return nil, err ~= '' and err or ('man -l ' .. path .. ' exited with code ' .. res.code)
  end
  local lines = vim.split(res.stdout, '\n', { plain = true })
  if lines[#lines] == '' then
    table.remove(lines)
  end
  for i, l in ipairs(lines) do
    lines[i] = clean(l)
  end
  cache = lines
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

local function find_existing()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b)
      and vim.api.nvim_buf_get_name(b):find(M.BUFNAME, 1, true) then
      return b
    end
  end
  return nil
end

--- Open (or focus) the installed named.conf(5) page in an immutable buffer
--- with docs hover attached.
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

  local lines, err = page_lines()
  if not lines then
    vim.notify('[named] ' .. err, vim.log.levels.ERROR)
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
  -- man syntax highlighting; the ftplugin's K map is overridden just below.
  bo.filetype = 'man'
  bo.modifiable = false
  bo.readonly = true

  vim.api.nvim_buf_set_var(bufnr, 'named_conf_dialect', 'man')
  pcall(function()
    require('named-conf.lsp').start(bufnr, { name = 'named-conf', hover = true, completion = false })
  end)
  vim.keymap.set('n', 'K', function() require('named-conf.hover').show() end,
    { buffer = bufnr, desc = 'BIND docs for the statement under the cursor' })

  return bufnr
end

return M
