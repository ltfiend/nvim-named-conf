-- Integration test against the real `named-checkconf` binary. Skipped when the
-- binary isn't installed, so the suite still passes on machines without BIND.
local checkconf = require('named-conf.checkconf')

local have = vim.fn.executable('named-checkconf') == 1

describe('named-checkconf (real binary)', function()
  if not have then
    pending('named-checkconf not installed — skipping live integration test')
    return
  end

  it('reports a file:line diagnostic for a broken config', function()
    local path = vim.fn.tempname() .. '.conf'
    vim.fn.writefile({ 'options {', '    recursion yes', '};' }, path) -- missing ';'
    local res = vim.system({ 'named-checkconf', path }, { text = true }):wait()
    assert.is_true(res.code ~= 0)

    local parsed = checkconf.parse_output((res.stdout or '') .. '\n' .. (res.stderr or ''))
    local hit
    for _, p in ipairs(parsed) do
      if p.file and p.lnum and p.text:find('missing', 1, true) then
        hit = p
      end
    end
    os.remove(path)
    assert.is_not_nil(hit)
    assert.equals(3, hit.lnum) -- the error is reported on the `};` line
  end)

  it('accepts a syntactically valid config', function()
    local path = vim.fn.tempname() .. '.conf'
    vim.fn.writefile({ 'options {', '    recursion no;', '};' }, path)
    local res = vim.system({ 'named-checkconf', path }, { text = true }):wait()
    os.remove(path)
    assert.equals(0, res.code)
  end)
end)
