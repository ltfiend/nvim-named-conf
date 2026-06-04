local kb = require('named-conf.knowledge')
local context = require('named-conf.context')

describe('knowledge base', function()
  it('documents top-level clauses', function()
    assert.is_not_nil(kb.lookup_key('zone', { clause = 'top' }))
    assert.is_not_nil(kb.lookup_key('options', { clause = 'top' }))
    assert.is_not_nil(kb.lookup_key('view', { clause = 'top' }))
  end)

  it('resolves statements by enclosing clause', function()
    assert.is_not_nil(kb.lookup_key('directory', { clause = 'options' }))
    assert.is_not_nil(kb.lookup_key('algorithm', { clause = 'key' }))
    assert.is_not_nil(kb.lookup_key('match-clients', { clause = 'view' }))
    assert.is_not_nil(kb.lookup_key('severity', { clause = 'channel' }))
  end)

  it('covers BIND 9.20 options statements (new in this release range)', function()
    for _, name in ipairs({
      'qname-minimization', 'stale-answer-enable', 'max-stale-ttl',
      'response-policy', 'catalog-zones', 'dns64', 'min-cache-ttl',
      'send-cookie', 'require-server-cookie', 'resolver-use-dns64',
      'tcp-initial-timeout', 'sig0message-checks-limit', 'fetches-per-zone',
    }) do
      assert.is_not_nil(kb.lookup_key(name, { clause = 'options' }),
        'missing options statement: ' .. name)
    end
  end)

  it('covers zone-specific statements across zone types', function()
    for _, name in ipairs({
      'checkds', 'database', 'journal', 'inline-signing', 'update-policy',
      'server-addresses', 'server-names', 'parental-agents', 'primaries',
      'in-view',
    }) do
      assert.is_not_nil(kb.lookup_key(name, { clause = 'zone' }),
        'missing zone statement: ' .. name)
    end
  end)

  it('inherits options statements inside a zone scope', function()
    -- zone scope falls through to the options table.
    assert.is_not_nil(kb.lookup_key('also-notify', { clause = 'zone' }))
    assert.is_not_nil(kb.lookup_key('masterfile-format', { clause = 'zone' }))
  end)

  it('documents the server, tls, http, key-store and dnssec-policy blocks', function()
    assert.is_not_nil(kb.lookup_key('tcp-only', { clause = 'server' }))
    assert.is_not_nil(kb.lookup_key('edns-version', { clause = 'server' }))
    assert.is_not_nil(kb.lookup_key('cert-file', { clause = 'tls' }))
    assert.is_not_nil(kb.lookup_key('protocols', { clause = 'tls' }))
    assert.is_not_nil(kb.lookup_key('endpoints', { clause = 'http' }))
    assert.is_not_nil(kb.lookup_key('pkcs11-uri', { clause = 'key-store' }))
    assert.is_not_nil(kb.lookup_key('signatures-validity', { clause = 'dnssec-policy' }))
    assert.is_not_nil(kb.lookup_key('nsec3param', { clause = 'dnssec-policy' }))
  end)

  it('documents new top-level clauses', function()
    for _, name in ipairs({ 'tls', 'http', 'key-store', 'remote-servers', 'dyndb' }) do
      assert.is_not_nil(kb.lookup_key(name, { clause = 'top' }),
        'missing top-level clause: ' .. name)
    end
  end)

  it('does not offer statements removed before 9.20 (auto-dnssec)', function()
    assert.is_nil(kb.lookup_key('auto-dnssec', { clause = 'zone' }))
  end)

  it('documents the zone type value enum', function()
    local e = kb.lookup_value('primary', 'type', { clause = 'zone' })
    assert.is_not_nil(e)
    assert.is_string(e.summary)
  end)

  it('documents severity values in a logging channel', function()
    local e = kb.lookup_value('info', 'severity', { clause = 'channel' })
    assert.is_not_nil(e)
  end)

  it('documents built-in ACL values anywhere', function()
    assert.is_not_nil(kb.lookup_value('localhost', 'allow-query', { clause = 'options' }))
  end)

  it('offers statement candidates for a clause', function()
    local names = {}
    for _, c in ipairs(kb.key_candidates({ clause = 'options' })) do
      names[c.name] = true
    end
    assert.is_true(names['recursion'])
    assert.is_true(names['forwarders'])
  end)

  it('offers ACL names as values for address-match statements', function()
    local names = {}
    for _, c in ipairs(kb.value_candidates('allow-query', { clause = 'options' })) do
      names[c.name] = true
    end
    assert.is_true(names['localhost'])
    assert.is_true(names['any'])
  end)

  it('renders markdown with the clause noted', function()
    local md = kb.render('recursion', kb.lookup_key('recursion', { clause = 'options' }), { clause = 'options' })
    assert.is_true(md:find('recursion', 1, true) ~= nil)
    assert.is_true(md:find('in options', 1, true) ~= nil)
  end)
end)

describe('context.at', function()
  local function buf(lines)
    local b = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(b, 0, -1, false, lines)
    return b
  end

  it('identifies a statement keyword as a key in its clause', function()
    local b = buf({ 'options {', '    recursion no;', '};' })
    local ctx = context.at(b, 1, 6) -- on "recursion"
    assert.equals('recursion', ctx.word)
    assert.equals('key', ctx.kind)
    assert.equals('options', ctx.clause)
  end)

  it('identifies an argument as a value', function()
    local b = buf({ 'zone "x" {', '    type primary;', '};' })
    local ctx = context.at(b, 1, 10) -- on "primary"
    assert.equals('primary', ctx.word)
    assert.equals('value', ctx.kind)
    assert.equals('type', ctx.line_key)
    assert.equals('zone', ctx.clause)
  end)

  it('treats a clause header keyword as belonging to the parent scope', function()
    local b = buf({ 'zone "x" {', '    type primary;', '};' })
    local ctx = context.at(b, 0, 0) -- on "zone"
    assert.equals('zone', ctx.word)
    assert.equals('top', ctx.clause)
  end)

  it('scopes statements inside a tls block', function()
    local b = buf({ 'tls "local" {', '    cert-file "/p/cert.pem";', '};' })
    local ctx = context.at(b, 1, 6) -- on "cert-file"
    assert.equals('cert-file', ctx.word)
    assert.equals('tls', ctx.clause)
    assert.is_not_nil(require('named-conf.knowledge').lookup_key(ctx.word, ctx))
  end)
end)
