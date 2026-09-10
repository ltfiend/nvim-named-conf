-- named-conf.nvim — make editing BIND `named.conf` files fast and safe:
-- clause-aware folding, semantic colour coding, an in-process docs LSP (hover +
-- completion), static diagnostics, and a configurable `named-checkconf` runner.
local config = require('named-conf.config')

local M = {}

M.config = config

--- Configure and activate the plugin.
---@param opts table|nil
function M.setup(opts)
  config.setup(opts)

  local detect = require('named-conf.detect')
  detect.setup_autocmds()

  require('named-conf.commands').setup()

  -- Attach to any already-open matching buffers (e.g. lazy-loaded after open).
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local name = vim.api.nvim_buf_get_name(bufnr)
      local ft = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
      if detect.should_attach(name, ft) then
        detect.attach(bufnr)
      end
    end
  end

  return M
end

-- Convenience re-exports for users who prefer the Lua API over commands.
function M.browse(...) return require('named-conf.picker').browse(...) end
function M.validate(...) return require('named-conf.validate').run(...) end
function M.check(...) return require('named-conf.checkconf').run(...) end
function M.docs(...) return require('named-conf.hover').show(...) end
function M.man(...) return require('named-conf.man').open(...) end

-- Public API for OTHER plugins that edit named.conf syntax in their own buffers
-- (e.g. nvim-rndc-zone editing a `zone { ... }` block from `rndc showzone`).
-- These work without calling setup() — the LSP server reads the live buffer.

--- Attach the in-process docs LSP (hover + completion) to a buffer.
--- Pass a stable `name`+`root_dir` to share one client across many buffers.
---@param bufnr integer
---@param opts? { hover?: boolean, completion?: boolean, name?: string, root_dir?: string }
---@return integer|nil client_id
function M.lsp_attach(bufnr, opts) return require('named-conf.lsp').start(bufnr, opts) end

--- Resolve markdown docs for the symbol at (row, col) (0-indexed), or nil.
---@param bufnr integer
---@param row integer
---@param col integer
---@return string|nil
function M.hover_markdown(bufnr, row, col)
  return require('named-conf.hover').markdown(bufnr, row, col)
end

return M
