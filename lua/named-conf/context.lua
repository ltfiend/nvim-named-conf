-- Determine the schema context at a cursor position inside a named.conf buffer:
-- the word under the cursor, whether it is a statement keyword (key) or an
-- argument (value), the statement's leading keyword, and the enclosing clause
-- (options / zone / view / logging / channel / acl / ...). This feeds hover and
-- completion (see knowledge.lua).
local parser = require('named-conf.parser')

local M = {}

-- BIND statement keywords use hyphens (allow-query, max-cache-size); treat
-- letters, digits, `-` and `_` as word characters.
local function is_word_char(ch)
  return ch:match('[%w%-_]') ~= nil
end

--- The identifier under (byte) column `col` (0-indexed) on `line`.
---@param line string
---@param col integer 0-indexed byte column
---@return string word, 'key'|'value' kind, string|nil line_key
local function word_at(line, col)
  local c = col + 1 -- to 1-indexed
  if c > #line then c = #line end
  if c < 1 then c = 1 end
  local s, e = c, c
  -- If cursor sits on a non-word char, try the char just before it.
  if c >= 1 and not (line:sub(c, c) ~= '' and is_word_char(line:sub(c, c)))
    and c > 1 and is_word_char(line:sub(c - 1, c - 1)) then
    s, e = c - 1, c - 1
  end
  while s > 1 and is_word_char(line:sub(s - 1, s - 1)) do s = s - 1 end
  while e < #line and is_word_char(line:sub(e + 1, e + 1)) do e = e + 1 end
  local word = line:sub(s, e)
  if not word:match('^[%w%-_]+$') then
    word = ''
  end

  -- The statement's leading keyword: the first bareword on the line.
  local line_key = line:match('^%s*([%w%-_]+)')

  -- Key vs value: the cursor word is the key only if it *is* the leading keyword
  -- and the cursor sits within that first token's span.
  local kind = 'value'
  if line_key and word == line_key then
    local ks, ke = line:find(line_key, 1, true)
    if ks and s >= ks and e <= ke then
      kind = 'key'
    end
  end
  return word, kind, line_key
end

--- The enclosing clause that statements on line `row` belong to.
--- For a clause header line (`zone "x" {`) the statements conceptually belong to
--- the parent scope, so we return the parent's clause (or 'top').
---@param parsed table
---@param row integer 0-indexed
---@return string clause, table|nil block
local function enclosing(parsed, row)
  local lnum = row + 1
  local block = parser.block_at(parsed, lnum)
  if not block then
    return 'top', nil
  end
  if block.start_line == lnum then
    local parent = block.parent
    return (parent and parent.clause) or 'top', parent
  end
  return block.clause or 'top', block
end

--- The config dialect of a buffer: 'rndc' for rndc.conf-style files, else
--- 'named'. Set by detect.attach; defaults to 'named' when unset.
---@param bufnr integer
---@return string
local function dialect_of(bufnr)
  local ok, val = pcall(vim.api.nvim_buf_get_var, bufnr, 'named_conf_dialect')
  if ok and val == 'rndc' then
    return 'rndc'
  end
  return 'named'
end

--- Full context at a position.
---@param bufnr integer
---@param row integer 0-indexed line
---@param col integer 0-indexed byte column
---@return { word: string, kind: string, line_key: string|nil, clause: string, dialect: string, block: table|nil }
function M.at(bufnr, row, col)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local line = lines[row + 1] or ''
  local word, kind, line_key = word_at(line, col)
  local parsed = parser.parse_lines(lines)
  local clause, block = enclosing(parsed, row)
  return {
    word = word,
    kind = kind,
    line_key = line_key,
    clause = clause,
    dialect = dialect_of(bufnr),
    block = block,
  }
end

-- Exposed for tests.
M._word_at = word_at

return M
