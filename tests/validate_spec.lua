local validate = require('named-conf.validate')

local function msgs(lines)
  local out = {}
  for _, d in ipairs(validate.diagnostics_for(lines)) do
    out[#out + 1] = d.message
  end
  return out
end

local function has(lines, substr)
  for _, m in ipairs(msgs(lines)) do
    if m:find(substr, 1, true) then return true end
  end
  return false
end

describe('validate.diagnostics_for', function()
  it('accepts a balanced file', function()
    assert.same({}, msgs({ 'zone "x" {', '    type primary;', '};' }))
  end)

  it('flags an unclosed brace', function()
    assert.is_true(has({ 'zone "x" {', '    type primary;' }, "unclosed '{'"))
  end)

  it('flags an unmatched closing brace', function()
    assert.is_true(has({ 'zone "x" {', '};', '};' }, "unmatched '}'"))
  end)

  it('ignores braces inside comments and strings', function()
    assert.same({}, msgs({
      'options {',
      '    // a stray } in a comment',
      '    secret "abc}def";',
      '};',
    }))
  end)

  it('flags duplicate zone names in the same scope', function()
    assert.is_true(has({
      'zone "dup.example" { type primary; file "a"; };',
      'zone "dup.example" { type primary; file "b"; };',
    }, 'duplicate zone "dup.example"'))
  end)

  it('does not flag same-named zones in different views', function()
    assert.same({}, msgs({
      'view "a" { zone "x.example" { type primary; file "a"; }; };',
      'view "b" { zone "x.example" { type primary; file "b"; }; };',
    }))
  end)
end)
