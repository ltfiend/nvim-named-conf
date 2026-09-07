-- Zone data ("master") file support: hover docs and completion for RR types,
-- $-directives, classes, and `@`, backed by kb/records.lua. Buffers get the
-- 'zone' dialect from detect.lua; hover.lua and lsp.lua route here for it.
--
-- Master-file syntax is line-oriented, not clause-oriented, so this module has
-- its own tokenizer instead of reusing context.lua/parser.lua (which parse
-- named.conf braces and would misread a zone file).
local records = require('named-conf.kb.records')
local kb = require('named-conf.knowledge')

local M = {}

-- Owner names and record fields: letters, digits, `-`, `_`, plus `$` (so
-- `$TTL` is one token) and `@` (the origin).
local function is_word_char(ch)
  return ch:match('[%w%-_%$@]') ~= nil
end

--- The token under (byte) column `col` (0-indexed) on `line`.
---@param line string
---@param col integer 0-indexed byte column
---@return string
local function word_at(line, col)
  local c = col + 1
  if c > #line then c = #line end
  if c < 1 then c = 1 end
  local s, e = c, c
  if c >= 1 and not (line:sub(c, c) ~= '' and is_word_char(line:sub(c, c)))
    and c > 1 and is_word_char(line:sub(c - 1, c - 1)) then
    s, e = c - 1, c - 1
  end
  while s > 1 and is_word_char(line:sub(s - 1, s - 1)) do s = s - 1 end
  while e < #line and is_word_char(line:sub(e + 1, e + 1)) do e = e + 1 end
  local word = line:sub(s, e)
  if not word:match('^[%w%-_%$@]+$') then
    return ''
  end
  return word
end

--- Resolve a zone-file token to a kb entry (directive, class, RR type, or `@`).
--- RR types and directives are case-insensitive in master files.
---@param word string
---@return table|nil entry, string|nil canonical_name
function M.lookup(word)
  if not word or word == '' then
    return nil
  end
  if records.specials[word] then
    return records.specials[word], word
  end
  local upper = word:upper()
  for _, tbl in ipairs({ records.directives, records.classes, records.types }) do
    if tbl[upper] then
      return tbl[upper], upper
    end
  end
  return nil
end

--- Markdown docs for position (row, col) (0-indexed) in `bufnr`, or nil.
---@param bufnr integer
---@param row integer
---@param col integer
---@return string|nil
function M.markdown(bufnr, row, col)
  local lines = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)
  local word = word_at(lines[1] or '', col)
  local entry, name = M.lookup(word)
  if not entry then
    return nil
  end
  return kb.render(name, entry)
end

--- Completion payload for the in-process LSP (see lsp.lua): every documented
--- RR type, directive, and class. Master files have no nesting, so no
--- position-dependent scoping is needed.
---@return table  { isIncomplete = false, items = {...} }
function M.lsp_completion()
  local Kind = vim.lsp.protocol.CompletionItemKind
  local items = {}
  local function push_all(tbl, kind)
    for name, entry in pairs(tbl) do
      items[#items + 1] = {
        label = name,
        kind = kind,
        detail = entry.summary,
        documentation = { kind = 'markdown', value = kb.render(name, entry) },
      }
    end
  end
  push_all(records.types, Kind.Class)
  push_all(records.directives, Kind.Keyword)
  push_all(records.classes, Kind.EnumMember)
  return { isIncomplete = false, items = items }
end

-- Exposed for tests.
M._word_at = word_at

return M
