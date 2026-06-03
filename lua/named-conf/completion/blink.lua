-- blink.cmp completion source for named.conf.
--
-- The in-process LSP (lsp.lua) already provides completion via blink's `lsp`
-- source, so this is optional — register it only if you want a dedicated,
-- always-on source independent of the LSP client:
--
--   sources = {
--     default = { 'lsp', 'path', 'snippets', 'buffer', 'named' },
--     providers = {
--       named = { name = 'named', module = 'named-conf.completion.blink' },
--     },
--   }
local context = require('named-conf.context')
local kb = require('named-conf.knowledge')

local KIND = vim.lsp.protocol.CompletionItemKind

---@class NamedBlinkSource
local source = {}

function source.new(opts)
  return setmetatable({ opts = opts or {} }, { __index = source })
end

-- Only offer completions inside attached named.conf buffers.
function source:enabled()
  return vim.b.named_conf == true
end

function source:get_trigger_characters()
  return { ' ', '{', ';' }
end

function source:get_completions(_, callback)
  local bufnr = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2]
  local before = vim.api.nvim_get_current_line():sub(1, col)
  local ctx = context.at(bufnr, row, col)

  local items = {}
  local function push(name, entry, kind)
    items[#items + 1] = {
      label = name,
      kind = kind,
      documentation = { kind = 'markdown', value = kb.render(name, entry) },
    }
  end

  local line_key = before:match('^%s*([%w%-_]+)%s+%S*$')
  if line_key then
    for _, c in ipairs(kb.value_candidates(line_key, ctx)) do
      push(c.name, c.entry, KIND.EnumMember)
    end
  end
  if #items == 0 then
    for _, c in ipairs(kb.key_candidates(ctx)) do
      push(c.name, c.entry, KIND.Field)
    end
  end

  callback({
    items = items,
    is_incomplete_forward = false,
    is_incomplete_backward = false,
  })

  return function() end
end

function source:resolve(item, callback)
  callback(item)
end

return source
