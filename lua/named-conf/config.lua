-- Configuration handling for named-conf.nvim
local M = {}

---@class NamedConfig
local defaults = {
  -- File detection. A buffer is treated as a BIND config when its filetype is
  -- one of `filetypes` (Neovim ships `named` for named.conf/rndc.conf) or its
  -- basename matches one of `patterns`. We keep the buffer's filetype intact so
  -- the built-in `named` syntax/treesitter highlighting keeps working, and
  -- attach our features on top via a buffer-local flag.
  detect = {
    enabled = true,
    filetypes = { 'named' }, -- Neovim sets `named` for named.conf / rndc.conf
    patterns = { 'named.conf', 'named.conf.*', '*.named.conf', 'rndc.conf' },
  },

  -- Clause-aware folding (zone / options / view / acl / key / logging ...).
  fold = {
    enabled = true,
    nested = false, -- also fold inner blocks (channels, nested zones in views)
    text = nil, ---@type fun(info: table): string|nil  custom foldtext formatter
  },

  -- `named-checkconf` integration. The file is checked on disk; if the buffer
  -- is modified and `use_buffer` is set, its contents are written to a temp file
  -- in the same directory (so relative `include` paths still resolve) first.
  checkconf = {
    enabled = true,
    cmd = 'named-checkconf', -- the executable to run
    args = {}, -- extra flags passed verbatim, e.g. { '-z' } to test-load zones
    chroot = nil, -- convenience: if set, passed as `-t <chroot>`
    use_buffer = true, -- check unsaved buffer contents via a temp file
    on_save = true, -- run automatically after a successful write
  },

  -- Static, in-process diagnostics (run without invoking named-checkconf):
  -- unbalanced braces, statements missing a trailing `;`, and duplicate zone
  -- names within the same scope.
  validate = {
    enabled = true,
    on_save = true,
    on_change = true, -- debounced while typing
    debounce = 400, -- ms
  },

  -- Semantic colour coding of clauses and address-match ("filter") statements,
  -- applied with extmarks on top of the normal `named` syntax. The highlight
  -- groups are defined with `default = true`, so a colorscheme that sets them
  -- wins; the `colors` table below is just the fallback.
  highlight = {
    enabled = true,
    background = false, -- also tint each clause's lines with a subtle bg
    colors = {
      zone = '#a6e3a1', -- green:  zone definitions
      options = '#89b4fa', -- blue:   options / logging / controls / channels
      acl = '#cba6f7', -- mauve:  acl / view / key / server / trust anchors
      name = '#94e2d5', -- teal:   the quoted name of a zone/acl/view/key
      type = '#fab387', -- peach:  a zone's `type` (master/slave/forward/...)
      filter = '#f38ba8', -- red:    address-match "filter" statements
      zone_bg = '#11231a',
      options_bg = '#101a2e',
      acl_bg = '#1c1426',
    },
  },

  -- Documentation popups via an in-process LSP server (pure Lua, no external
  -- binary). With it running, `K` shows BIND statement docs and completion
  -- offers documented statements/values. `:NamedDocs` works regardless.
  lsp = {
    enabled = true,
    hover = true,
    completion = true,
  },
}

---@type NamedConfig
M.options = vim.deepcopy(defaults)

M.defaults = defaults

--- Merge user options over the defaults.
---@param opts table|nil
function M.setup(opts)
  M.options = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts or {})
  return M.options
end

return M
