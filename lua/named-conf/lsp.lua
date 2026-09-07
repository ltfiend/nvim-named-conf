-- An in-process LSP server (pure Lua, no external binary) that serves
-- documentation for the BIND named.conf schema. Because it runs in the editor
-- it reads the live buffer directly via the document URI.
--
-- It advertises hoverProvider + completionProvider, so the user's existing LSP
-- keymaps work out of the box: `K` shows the docs popup, and completion offers
-- documented statements/values.
local config = require('named-conf.config')
local hover = require('named-conf.hover')
local context = require('named-conf.context')
local kb = require('named-conf.knowledge')

local M = {}

local CompletionItemKind = vim.lsp.protocol.CompletionItemKind

--- Build completion items for the request.
---@param params table
---@return table  { isIncomplete = false, items = {...} }
local function completion(params)
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
  local row = params.position.line
  local col = params.position.character

  -- Zone data files complete RR types/directives/classes, not statements.
  local dok, dialect = pcall(vim.api.nvim_buf_get_var, bufnr, 'named_conf_dialect')
  if dok and dialect == 'zone' then
    return require('named-conf.zonefile').lsp_completion()
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)
  local line = lines[1] or ''
  local before = line:sub(1, col)

  local items = {}
  local function push(name, entry, kind)
    items[#items + 1] = {
      label = name,
      kind = kind,
      detail = entry.summary,
      documentation = { kind = 'markdown', value = kb.render(name, entry) },
    }
  end

  local ctx = context.at(bufnr, row, col)

  -- If there's already a leading keyword and the cursor is past it, offer values
  -- for that statement; otherwise offer statement keywords for the clause.
  local line_key = before:match('^%s*([%w%-_]+)%s+%S*$')
  if line_key then
    for _, c in ipairs(kb.value_candidates(line_key, ctx)) do
      push(c.name, c.entry, CompletionItemKind.EnumMember)
    end
    if #items > 0 then
      return { isIncomplete = false, items = items }
    end
  end

  for _, c in ipairs(kb.key_candidates(ctx)) do
    push(c.name, c.entry, CompletionItemKind.Field)
  end
  return { isIncomplete = false, items = items }
end

--- Construct the in-process RPC server object, bound to `opts` and the LSP
--- `dispatchers`. `opts` decouples the server from this plugin's config so
--- external callers (e.g. nvim-rndc-zone) can drive it with their own settings.
---@param opts { hover?: boolean, completion?: boolean, name?: string }
---@param dispatchers table
---@return table
local function new_server(opts, dispatchers)
  local closing = false
  local srv = {}

  function srv.request(method, params, callback)
    if method == 'initialize' then
      callback(nil, {
        capabilities = {
          textDocumentSync = 0, -- we read the live buffer; no sync needed
          hoverProvider = opts.hover ~= false,
          completionProvider = opts.completion ~= false
            and { triggerCharacters = { ' ', '{', ';' } } or nil,
        },
        serverInfo = { name = opts.name or 'named-conf', version = '0.1.0' },
      })
    elseif method == 'textDocument/hover' then
      callback(nil, hover.lsp_hover(params))
    elseif method == 'textDocument/completion' then
      callback(nil, completion(params))
    elseif method == 'shutdown' then
      callback(nil, nil)
    else
      callback(nil, nil)
    end
    return true, 1
  end

  function srv.notify(method, _params)
    if method == 'exit' then
      closing = true
      if dispatchers.on_exit then
        dispatchers.on_exit(0, 15)
      end
    end
    return true
  end

  function srv.is_closing()
    return closing
  end

  function srv.terminate()
    closing = true
  end

  return srv
end

--- The `cmd` factory passed to vim.lsp.start, bound to `opts`.
---@param opts table
---@return fun(dispatchers: table): table
local function make_server(opts)
  return function(dispatchers)
    return new_server(opts, dispatchers)
  end
end

--- Start (or reuse) the docs LSP for a buffer.
---
--- With no `opts`, this is the internal path used by detection: it honours
--- `config.options.lsp.*` exactly as before. When `opts` is supplied, the config
--- gate is skipped and the given capabilities/name/root are used — this is the
--- entry point external plugins reach via `require('named-conf').lsp_attach()`.
---@param bufnr integer
---@param opts? { hover?: boolean, completion?: boolean, name?: string, root_dir?: string }
---@return integer|nil client_id
function M.start(bufnr, opts)
  if opts == nil then
    if not config.options.lsp.enabled then
      return nil
    end
    opts = {
      name = 'named-conf',
      hover = config.options.lsp.hover ~= false,
      completion = config.options.lsp.completion ~= false,
    }
  end
  local root = opts.root_dir
  if not root then
    local name = vim.api.nvim_buf_get_name(bufnr)
    root = (name ~= '' and vim.fs.dirname(name)) or (vim.uv or vim.loop).cwd()
  end
  return vim.lsp.start({
    name = opts.name or 'named-conf',
    cmd = make_server(opts),
    root_dir = root,
  }, { bufnr = bufnr })
end

-- Exposed for tests.
M._completion = completion

return M
