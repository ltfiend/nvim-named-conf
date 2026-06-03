local highlight = require('named-conf.highlight')

local function marks(lines)
  return highlight.compute_lines(lines, {})
end

--- Find a mark covering (0-indexed) line `l` with highlight group `hl`.
local function find(ms, l, hl)
  for _, m in ipairs(ms) do
    if m.line == l and m.hl == hl then
      return m
    end
  end
  return nil
end

describe('highlight.compute_lines', function()
  it('colours a zone clause keyword and its quoted name', function()
    local lines = { 'zone "example.com" IN {', '    type primary;', '};' }
    local ms = marks(lines)
    local kw = find(ms, 0, 'NamedZone')
    assert.is_not_nil(kw)
    assert.equals(0, kw.col)
    assert.equals(4, kw.end_col) -- "zone"
    local name = find(ms, 0, 'NamedName')
    assert.is_not_nil(name)
    -- name spans the chars inside the quotes
    assert.equals(#'example.com', name.end_col - name.col)
    assert.equals(lines[1]:sub(name.col + 1, name.end_col), 'example.com')
  end)

  it('colours a zone type value', function()
    local lines = { 'zone "x" {', '    type secondary;', '};' }
    local ms = marks(lines)
    local t = find(ms, 1, 'NamedZoneType')
    assert.is_not_nil(t)
    assert.equals(#'secondary', t.end_col - t.col)
    assert.equals(lines[2]:sub(t.col + 1, t.end_col), 'secondary')
  end)

  it('groups options-like and acl-like clauses distinctly', function()
    local ms = marks({ 'options {', '};' })
    assert.is_not_nil(find(ms, 0, 'NamedOptions'))
    local ms2 = marks({ 'acl "trusted" {', '};' })
    assert.is_not_nil(find(ms2, 0, 'NamedAcl'))
  end)

  it('colours address-match "filter" statements', function()
    local ms = marks({ '    allow-query { localhost; };' })
    local f = find(ms, 0, 'NamedFilter')
    assert.is_not_nil(f)
    assert.equals(4, f.col)
    assert.equals(4 + #'allow-query', f.end_col)
  end)

  it('does not colour a filter keyword that is only in a comment', function()
    local ms = marks({ '    // allow-query here is just prose' })
    assert.is_nil(find(ms, 0, 'NamedFilter'))
  end)

  it('emits background line marks only for top-level clauses when enabled', function()
    local lines = { 'options {', '    recursion no;', '};' }
    local ms = highlight.compute_lines(lines, { background = true })
    local bg = 0
    for _, m in ipairs(ms) do
      if m.line_hl == 'NamedOptionsLine' then bg = bg + 1 end
    end
    assert.equals(3, bg) -- lines 1..3
  end)
end)
