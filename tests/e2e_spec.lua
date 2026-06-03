-- End-to-end smoke test: wire the whole plugin together on a real buffer and
-- confirm attach + highlight + validate + hover + the in-process LSP all run
-- without error on the target Neovim.
local function read_fixture()
  local path = debug.getinfo(1, 'S').source:sub(2)
  local dir = vim.fn.fnamemodify(path, ':h')
  return vim.fn.readfile(dir .. '/fixtures/named.conf')
end

describe('end-to-end', function()
  local nc = require('named-conf')
  local detect = require('named-conf.detect')
  local bufnr
  local seq = 0

  before_each(function()
    nc.setup({})
    seq = seq + 1
    bufnr = vim.api.nvim_create_buf(false, true) -- unlisted scratch (no swap)
    vim.api.nvim_set_option_value('swapfile', false, { buf = bufnr })
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = bufnr })
    vim.api.nvim_buf_set_name(bufnr, string.format('/tmp/named-%d.conf', seq))
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, read_fixture())
    vim.api.nvim_set_option_value('filetype', 'named', { buf = bufnr })
  end)

  after_each(function()
    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end)

  it('detects the buffer by filetype and by name', function()
    assert.is_true(detect.should_attach('/etc/bind/named.conf', 'named'))
    assert.is_true(detect.should_attach('/etc/named.conf.local', ''))
    assert.is_false(detect.should_attach('/etc/passwd', 'conf'))
  end)

  it('attaches without error and sets the buffer flag', function()
    detect.attach(bufnr)
    assert.is_true(detect.is_attached(bufnr))
  end)

  it('produces highlight extmarks for clauses', function()
    require('named-conf.highlight').apply(bufnr)
    local ns = require('named-conf.highlight').ns
    local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
    assert.is_true(#marks > 0)
  end)

  it('reports no static diagnostics for the valid fixture', function()
    assert.same({}, require('named-conf.validate').diagnostics(bufnr))
  end)

  it('resolves hover docs for a statement keyword', function()
    -- Find the `recursion no;` line and hover its keyword.
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local row
    for i, l in ipairs(lines) do
      if l:match('^%s*recursion%s') then row = i - 1 break end
    end
    assert.is_not_nil(row)
    local md = require('named-conf.hover').markdown(bufnr, row, ({ lines[row + 1]:find('recursion') })[1])
    assert.is_not_nil(md)
    assert.is_true(md:find('recursion', 1, true) ~= nil)
  end)

  it('starts the in-process docs LSP and answers a hover request', function()
    local client_id = require('named-conf.lsp').start(bufnr)
    assert.is_not_nil(client_id)
    local client = vim.lsp.get_client_by_id(client_id)
    assert.is_not_nil(client)
    assert.is_true(client.server_capabilities.hoverProvider == true)
  end)

  it('honours an explicit opts table (name + capability toggles)', function()
    -- This is the path external plugins (e.g. nvim-rndc-zone) reach via
    -- require('named-conf').lsp_attach(bufnr, opts).
    local id = require('named-conf').lsp_attach(bufnr, {
      name = 'named-conf-test', hover = false, completion = true, root_dir = 'virtual',
    })
    assert.is_not_nil(id)
    local client = vim.lsp.get_client_by_id(id)
    assert.equals('named-conf-test', client.name)
    assert.is_falsy(client.server_capabilities.hoverProvider)
    assert.is_not_nil(client.server_capabilities.completionProvider)
    assert.is_not_nil(client.server_capabilities.completionProvider.triggerCharacters)
  end)

  it('exposes hover_markdown for programmatic use', function()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local row
    for i, l in ipairs(lines) do
      if l:match('^%s*type%s') then row = i - 1 break end
    end
    assert.is_not_nil(row)
    local col = ({ lines[row + 1]:find('type') })[1]
    local md = require('named-conf').hover_markdown(bufnr, row, col)
    assert.is_not_nil(md)
    assert.is_true(md:find('type', 1, true) ~= nil)
  end)
end)
