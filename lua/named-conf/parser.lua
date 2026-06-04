-- A small, comment- and string-aware parser for BIND `named.conf` files.
--
-- named.conf is brace-delimited and statement-oriented (`;`), with `//`, `#`
-- and `/* ... */` comments. We tokenise the buffer into words / strings /
-- punctuation (discarding comments) while remembering each token's line, then
-- build a tree of blocks. Each block records its clause keyword (zone, options,
-- view, acl, key, logging, ...), its optional quoted name and class (IN/CH/HS),
-- the line range, and the simple `key value;` statements directly inside it.
--
-- This drives folding (clause-aware fold summaries), the picker (browse zones),
-- and validation (duplicate zone names). It deliberately does not validate
-- syntax — that is what `named-checkconf` is for.
local M = {}

-- Keywords that introduce a named clause block. A `keyword ... { ... }` is only
-- treated as a block in the clause tree when its keyword is one of these;
-- everything else (forwarders, allow-query, listen-on, ...) is an ordinary
-- statement whose `{ ... }` is just a value list.
M.CLAUSES = {
  acl = true,
  channel = true, -- nested in logging
  controls = true,
  dlz = true,
  ['dnssec-policy'] = true,
  dyndb = true,
  http = true,
  key = true,
  ['key-store'] = true,
  logging = true,
  ['managed-keys'] = true,
  masters = true,
  options = true,
  ['parental-agents'] = true,
  plugin = true,
  primaries = true,
  ['remote-servers'] = true,
  server = true,
  ['statistics-channels'] = true,
  tls = true,
  ['trust-anchors'] = true,
  ['trusted-keys'] = true,
  view = true,
  zone = true,
}

--- Tokenise lines, discarding comments. Returns a flat list of tokens, each:
---   { text = string, kind = 'word'|'string'|'punct', line = 1-based-line }
--- Punctuation tokens are single chars: `{`, `}`, `;`.
---@param lines string[]
---@return table[]
function M.tokenize(lines)
  local tokens = {}
  local in_block_comment = false

  for lnum, raw in ipairs(lines) do
    local i, n = 1, #raw
    while i <= n do
      local c = raw:sub(i, i)

      if in_block_comment then
        local close = raw:find('*/', i, true)
        if close then
          in_block_comment = false
          i = close + 2
        else
          i = n + 1 -- rest of line is comment
        end

      elseif c == '/' and raw:sub(i + 1, i + 1) == '*' then
        local close = raw:find('*/', i + 2, true)
        if close then
          i = close + 2
        else
          in_block_comment = true
          i = n + 1
        end

      elseif (c == '/' and raw:sub(i + 1, i + 1) == '/') or c == '#' then
        i = n + 1 -- line comment to EOL

      elseif c == '"' then
        local j = i + 1
        while j <= n and raw:sub(j, j) ~= '"' do
          j = j + 1
        end
        tokens[#tokens + 1] = { text = raw:sub(i + 1, j - 1), kind = 'string', line = lnum }
        i = j + 1

      elseif c == '{' or c == '}' or c == ';' then
        tokens[#tokens + 1] = { text = c, kind = 'punct', line = lnum }
        i = i + 1

      elseif c:match('%s') then
        i = i + 1

      else
        -- A bareword: run of non-space, non-punct, non-comment chars.
        local j = i
        while j <= n do
          local cc = raw:sub(j, j)
          if cc:match('%s') or cc == '{' or cc == '}' or cc == ';' or cc == '"' then
            break
          end
          if cc == '/' and (raw:sub(j + 1, j + 1) == '/' or raw:sub(j + 1, j + 1) == '*') then
            break
          end
          if cc == '#' then
            break
          end
          j = j + 1
        end
        tokens[#tokens + 1] = { text = raw:sub(i, j - 1), kind = 'word', line = lnum }
        i = j
      end
    end
  end

  return tokens
end

local CLASSES = { IN = true, CH = true, HS = true, CHAOS = true, HESIOD = true, ANY = true }

-- A statement node produced by parse_block:
--   { words = {token,...}, block = {statement,...}|nil, line, end_line }
-- `words` are the bareword/string tokens before the `{` (or before `;`);
-- `block` is the parsed contents of an immediately-following `{ ... }`.

--- Parse the statements between `tokens[i]` and a matching `}` (or EOF).
--- Returns the statement list and the index just past the closing `}`.
---@param tokens table[]
---@param i integer
---@return table[] statements, integer next_i
local parse_statement -- forward declaration
local function parse_block(tokens, i)
  local stmts = {}
  while i <= #tokens do
    local t = tokens[i]
    if t.kind == 'punct' and t.text == '}' then
      return stmts, i + 1
    end
    local stmt, ni = parse_statement(tokens, i)
    if stmt then
      stmts[#stmts + 1] = stmt
    end
    i = (ni > i) and ni or (i + 1) -- guard against non-advancing loops
  end
  return stmts, i
end

--- Parse a single statement starting at `tokens[i]`.
---@param tokens table[]
---@param i integer
---@return table|nil statement, integer next_i
function parse_statement(tokens, i)
  local words, block = {}, nil
  local start_line = tokens[i] and tokens[i].line
  local end_line = start_line
  while i <= #tokens do
    local t = tokens[i]
    if t.kind == 'punct' and t.text == ';' then
      end_line = t.line
      i = i + 1
      break
    elseif t.kind == 'punct' and t.text == '}' then
      break -- statement ended by an enclosing block close (no trailing ';')
    elseif t.kind == 'punct' and t.text == '{' then
      local sub, ni = parse_block(tokens, i + 1)
      block = sub
      end_line = tokens[ni - 1] and tokens[ni - 1].line or end_line
      i = ni
    else
      words[#words + 1] = t
      end_line = t.line
      i = i + 1
    end
  end
  if #words == 0 and not block then
    return nil, i
  end
  return { words = words, block = block, line = start_line, end_line = end_line }, i
end

--- Flatten all word/string token texts inside a parsed block (recursively).
---@param stmts table[]
---@return string[]
local function flatten(stmts)
  local out = {}
  for _, s in ipairs(stmts) do
    for _, w in ipairs(s.words) do
      out[#out + 1] = w.text
    end
    if s.block then
      for _, w in ipairs(flatten(s.block)) do
        out[#out + 1] = w
      end
    end
  end
  return out
end

--- The string value of a statement: its arguments joined with spaces, including
--- the contents of any brace list. e.g. `forwarders { 8.8.8.8; 1.1.1.1; }` -> "8.8.8.8 1.1.1.1".
---@param s table
---@return string
local function field_value(s)
  local parts = {}
  for idx = 2, #s.words do
    parts[#parts + 1] = s.words[idx].text
  end
  if s.block then
    for _, w in ipairs(flatten(s.block)) do
      parts[#parts + 1] = w
    end
  end
  return table.concat(parts, ' ')
end

--- Extract the optional name and class from a clause statement's words[2..].
---@param words table[]
---@return string|nil name, string|nil class
local function name_and_class(words)
  local name, class
  for idx = 2, #words do
    local w = words[idx]
    if CLASSES[w.text] then
      class = class or w.text
    elseif not name then
      name = w.text -- first non-class token (quoted or bare) is the name
    end
  end
  return name, class
end

--- Walk a statement list, turning recognised clause statements into block nodes.
---@param stmts table[]
---@param depth integer
---@param parent table|nil
---@param all table[]   flat accumulator (mutated)
---@param out table[]   children accumulator (mutated)
local function collect_clauses(stmts, depth, parent, all, out)
  for _, s in ipairs(stmts) do
    local key = s.words[1] and s.words[1].text
    if key and M.CLAUSES[key] and s.block then
      local name, class = name_and_class(s.words)
      local block = {
        clause = key,
        name = name,
        class = class,
        start_line = s.line,
        end_line = s.end_line,
        depth = depth,
        parent = parent,
        fields = {},
        blocks = {},
      }
      for _, c in ipairs(s.block) do
        local ck = c.words[1] and c.words[1].text
        if ck and block.fields[ck] == nil then
          block.fields[ck] = field_value(c)
        end
      end
      all[#all + 1] = block
      out[#out + 1] = block
      collect_clauses(s.block, depth + 1, block, all, block.blocks)
    end
  end
end

--- Parse a list of lines into a clause tree.
---@param lines string[]
---@return { tree: table[], all: table[], zones: table[] }
function M.parse_lines(lines)
  local tokens = M.tokenize(lines)
  local statements = parse_block(tokens, 1) -- top level (no enclosing braces)
  local tree, all = {}, {}
  collect_clauses(statements, 0, nil, all, tree)
  local zones = {}
  for _, b in ipairs(all) do
    if b.clause == 'zone' then
      zones[#zones + 1] = b
    end
  end
  return { tree = tree, all = all, zones = zones }
end

--- Parse a buffer.
---@param bufnr integer|nil
---@return { tree: table[], all: table[], zones: table[] }
function M.parse(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return M.parse_lines(lines)
end

--- A short human label for a block, e.g. `zone "example.com"` or `options`.
---@param b table
---@return string
function M.label(b)
  if b.name then
    return string.format('%s "%s"', b.clause or '?', b.name)
  end
  return b.clause or '?'
end

--- Find the innermost block whose line range contains `lnum` (1-based).
---@param parsed table  result of M.parse / M.parse_lines
---@param lnum integer
---@return table|nil
function M.block_at(parsed, lnum)
  local best
  for _, b in ipairs(parsed.all) do
    if b.start_line <= lnum and lnum <= b.end_line then
      if not best or b.depth > best.depth then
        best = b
      end
    end
  end
  return best
end

return M
