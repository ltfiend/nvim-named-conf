-- Documentation hover: resolve markdown docs for the symbol under the cursor,
-- and render it either via the LSP (see lsp.lua) or directly in a float.
local context = require('named-conf.context')
local kb = require('named-conf.knowledge')

local M = {}

--- Markdown docs for position (row, col) (0-indexed) in `bufnr`, or nil.
---@param bufnr integer
---@param row integer
---@param col integer
---@return string|nil
function M.markdown(bufnr, row, col)
  local ctx = context.at(bufnr, row, col)
  if not ctx.word or ctx.word == '' then
    return nil
  end
  if ctx.kind == 'key' then
    local entry = kb.lookup_key(ctx.word, ctx)
    if entry then
      return kb.render(ctx.word, entry, ctx)
    end
    -- A keyword we don't recognise as a statement might still be a value the
    -- user is hovering (e.g. a bareword `master`); fall through.
  end
  local entry = kb.lookup_value(ctx.word, ctx.line_key, ctx)
  if entry then
    return kb.render(ctx.word, entry, ctx)
  end
  -- Final fallback: treat it as a keyword anywhere.
  local kentry = kb.lookup_key(ctx.word, ctx)
  if kentry then
    return kb.render(ctx.word, kentry, ctx)
  end
  return nil
end

--- LSP hover handler payload from hover request params.
---@param params table  { textDocument = { uri }, position = { line, character } }
---@return table|nil    { contents = { kind = 'markdown', value = ... } }
function M.lsp_hover(params)
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    vim.fn.bufload(bufnr)
  end
  local md = M.markdown(bufnr, params.position.line, params.position.character)
  if not md then
    return nil
  end
  return { contents = { kind = 'markdown', value = md } }
end

--- Show the docs for the symbol under the cursor in a floating window.
--- Used by :NamedDocs (works even when the LSP is disabled).
function M.show()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local md = M.markdown(0, cursor[1] - 1, cursor[2])
  if not md then
    vim.notify('[named] no documentation for the symbol under the cursor', vim.log.levels.INFO)
    return
  end
  vim.lsp.util.open_floating_preview(vim.split(md, '\n'), 'markdown', {
    border = 'rounded',
    focus_id = 'named-conf-docs',
    max_width = 80,
  })
end

return M
