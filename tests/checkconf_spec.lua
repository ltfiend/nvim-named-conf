local checkconf = require('named-conf.checkconf')

describe('checkconf.parse_output', function()
  it('parses file:line: message lines', function()
    local out = '/etc/named.conf:23: missing \';\' before \'}\'\n'
    local parsed = checkconf.parse_output(out)
    assert.equals(1, #parsed)
    assert.equals('/etc/named.conf', parsed[1].file)
    assert.equals(23, parsed[1].lnum)
    assert.equals("missing ';' before '}'", parsed[1].text)
  end)

  it('handles multiple lines and keeps non-matching lines as context', function()
    local out = table.concat({
      '/etc/named.conf:10: unknown option \'recurzion\'',
      'zone example.com/IN: loaded serial 2024010101',
      '/etc/named.conf:42: WARNING: deprecated option',
    }, '\n')
    local parsed = checkconf.parse_output(out)
    assert.equals(3, #parsed)
    assert.equals(10, parsed[1].lnum)
    assert.is_nil(parsed[2].file) -- the "loaded serial" line has no file:line
    assert.equals('zone example.com/IN: loaded serial 2024010101', parsed[2].text)
    assert.equals(42, parsed[3].lnum)
  end)

  it('ignores blank lines', function()
    assert.equals(0, #checkconf.parse_output('\n\n   \n'))
  end)
end)
