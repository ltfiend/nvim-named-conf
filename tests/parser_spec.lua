-- Run with: nvim --headless -c "PlenaryBustedDirectory tests/" -c qa
local parser = require('named-conf.parser')

local function read_fixture()
  local path = debug.getinfo(1, 'S').source:sub(2)
  local dir = vim.fn.fnamemodify(path, ':h')
  return vim.fn.readfile(dir .. '/fixtures/named.conf')
end

describe('tokenizer', function()
  it('discards // line comments', function()
    local toks = parser.tokenize({ 'recursion no; // a comment with ; and {' })
    local texts = vim.tbl_map(function(t) return t.text end, toks)
    assert.same({ 'recursion', 'no', ';' }, texts)
  end)

  it('discards # line comments', function()
    local toks = parser.tokenize({ 'file "x"; # trailing { } ;' })
    local texts = vim.tbl_map(function(t) return t.text end, toks)
    assert.same({ 'file', 'x', ';' }, texts)
  end)

  it('discards /* ... */ block comments, including across lines', function()
    local toks = parser.tokenize({ 'a /* one', 'two { ; } */ b;' })
    local texts = vim.tbl_map(function(t) return t.text end, toks)
    assert.same({ 'a', 'b', ';' }, texts)
  end)

  it('keeps braces inside string literals out of the token stream as punct', function()
    local toks = parser.tokenize({ 'secret "abc{}; def";' })
    local kinds = vim.tbl_map(function(t) return t.kind end, toks)
    -- word(secret), string(abc{}; def), punct(;)
    assert.same({ 'word', 'string', 'punct' }, kinds)
  end)
end)

describe('parser', function()
  local parsed
  before_each(function()
    parsed = parser.parse_lines(read_fixture())
  end)

  it('finds the top-level clauses', function()
    local clauses = {}
    for _, b in ipairs(parsed.tree) do
      clauses[#clauses + 1] = b.clause
    end
    assert.same({ 'options', 'acl', 'key', 'zone', 'zone', 'view', 'logging' }, clauses)
  end)

  it('captures zone name, class, type and file', function()
    local z = parsed.zones[1]
    assert.equals('example.com', z.name)
    assert.equals('IN', z.class)
    assert.equals('primary', z.fields['type'])
    assert.equals('example.com.zone', z.fields['file']) -- quotes stripped by the tokenizer
  end)

  it('finds all zones including the one nested in a view', function()
    assert.equals(3, #parsed.zones)
    local names = vim.tbl_map(function(z) return z.name end, parsed.zones)
    assert.is_true(vim.tbl_contains(names, 'internal.example'))
  end)

  it('records nesting depth (view zone is deeper)', function()
    local internal
    for _, z in ipairs(parsed.zones) do
      if z.name == 'internal.example' then internal = z end
    end
    assert.equals(1, internal.depth)
  end)

  it('is not fooled by braces/semicolons inside comments and strings', function()
    -- options block must close at its real `};`, not inside the /* */ comment.
    local options = parsed.tree[1]
    assert.equals('options', options.clause)
    assert.is_true(options.end_line > options.start_line)
    -- The forwarders line lives inside options.
    assert.equals('8.8.8.8 1.1.1.1', options.fields['forwarders'])
  end)

  it('labels blocks readably', function()
    assert.equals('zone "example.com"', parser.label(parsed.zones[1]))
    assert.equals('options', parser.label(parsed.tree[1]))
  end)

  it('locates the innermost block at a line', function()
    -- Line 1 is a comment, outside every block.
    assert.is_nil(parser.block_at(parsed, 1))
    -- The innermost block containing a `type primary;` line is its zone.
    local z = parsed.zones[1]
    local inner = parser.block_at(parsed, z.start_line + 1)
    assert.equals('zone', inner.clause)
    assert.equals('example.com', inner.name)
  end)
end)
