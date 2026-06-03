# nvim-named-conf

A Neovim plugin that makes editing BIND `named.conf` files fast and safe.

`named.conf` is brace-delimited and statement-oriented, and a real config is a
wall of `zone "..." { ... };` blocks interleaved with `options`, `view`, `acl`,
`key` and `logging` clauses. This plugin adds structure on top of the built-in
`named` syntax: clause-aware folding, semantic colour coding (including the
address-match "filters"), an in-process documentation LSP, static diagnostics,
and a configurable `named-checkconf` runner.

It layers on top of Neovim's built-in `named` filetype — your syntax
highlighting and any treesitter/LSP setup keep working.

## Features

- **Clause-aware folding** — fold summaries name the clause instead of showing a
  bare `{ … }`:

  ```
  ▸ zone "example.com" IN  [primary]  → example.com.zone  (6 lines)
  ▸ options  (24 lines)
  ▸ acl "trusted"  (4 lines)
  ```

- **Semantic colour coding** — clause keywords are grouped into three palettes
  (zone / options-like / acl-like), the quoted name of a zone/acl/view/key is
  tinted, a zone's `type` value stands out, and **address-match "filter"
  statements** (`allow-query`, `allow-transfer`, `match-clients`, `listen-on`,
  `forwarders`, …) get their own colour. See [Colour coding](#colour-coding).

- **Documentation popups** — an in-process LSP (pure Lua, no external binary)
  serves docs for the `named.conf` schema. Press `K` on a statement like
  `recursion`, `allow-transfer`, `type`, or `severity`, or a value like
  `primary` / `auto` / `localhost`, to see what it does. See
  [Documentation popups](#documentation-popups).

- **`named-checkconf` integration** — `:NamedCheck` runs the configured
  `named-checkconf` and turns its `file:line: message` output into diagnostics.
  The command, its flags, and a chroot directory are all configurable. See
  [Checking the config](#checking-the-config).

- **Static diagnostics** — cheap, always-on checks that don't need the binary:
  unbalanced braces and duplicate zone names within a scope.

- **Navigation** — `:NamedBrowse` jumps to any clause by name (uses
  `snacks.nvim` when present, otherwise `vim.ui.select`).

- **Snippets** — `:NamedSnippet zone-primary` (and `acl`, `view`, `key`,
  `options`, `logging`, `zone-secondary`, `zone-forward`) insert ready-to-edit
  skeletons.

## Requirements

- **Neovim 0.11+** (developed and tested on **0.12.2**; runs on 0.13 nightly).
- `named-checkconf` on `$PATH` for `:NamedCheck` (optional — everything else
  works without it).
- Optional: `snacks.nvim` (nicer `:NamedBrowse`), `blink.cmp` (a dedicated
  completion source, though the in-process LSP already feeds completion).

## Install

<details><summary>lazy.nvim</summary>

```lua
{
  'ltfiend/nvim-named-conf',
  ft = 'named',
  opts = {
    checkconf = {
      cmd = 'named-checkconf',
      -- chroot = '/var/named/chroot',   -- becomes `-t /var/named/chroot`
      -- args = { '-z' },                -- also test-load every zone
    },
  },
}
```
</details>

Files with the `named` filetype (Neovim already maps `named.conf` and
`rndc.conf`) are detected automatically, as are basenames matching
`named.conf`, `named.conf.*`, `*.named.conf`, and `rndc.conf`.

## Configuration

See `:help named-conf` for everything. Defaults:

```lua
require('named-conf').setup({
  detect = {
    enabled = true,
    filetypes = { 'named' },
    patterns  = { 'named.conf', 'named.conf.*', '*.named.conf', 'rndc.conf' },
  },
  fold = { enabled = true, nested = false, text = nil },
  checkconf = {
    enabled    = true,
    cmd        = 'named-checkconf',
    args       = {},        -- extra flags passed verbatim, e.g. { '-z' }
    chroot     = nil,       -- convenience: becomes `-t <chroot>`
    use_buffer = true,      -- check unsaved buffer contents via a temp file
    on_save    = true,      -- run automatically after a successful write
  },
  validate = { enabled = true, on_save = true, on_change = true, debounce = 400 },
  highlight = { enabled = true, background = false }, -- see "Colour coding"
  lsp = { enabled = true, hover = true, completion = true },
})
```

### Checking the config

`:NamedCheck` shells out to `named-checkconf` and publishes its findings as
diagnostics. Configure it under `checkconf`:

- **`cmd`** — the executable (e.g. an absolute path, or a wrapper script).
- **`args`** — a list of extra flags passed verbatim. Add whatever your BIND
  build supports, for example `{ '-z' }` to test-load every zone.
- **`chroot`** — convenience for chrooted installs; becomes `-t <chroot>`.
- **`use_buffer`** — when the buffer has unsaved changes, write them to a temp
  file *in the same directory* (so relative `include` paths still resolve) and
  check that. With a `chroot` set, a temp file outside the chroot isn't visible,
  so the on-disk file is checked instead and you're told so.
- **`on_save`** — re-run automatically (quietly) after each successful write.

Diagnostics for `include`d files are pinned to line 1 with the filename in the
message, so you still see them.

Examples:

```lua
-- Chrooted BIND, also test-loading zones:
checkconf = { chroot = '/var/named/chroot', args = { '-z' } }

-- A custom binary / container wrapper:
checkconf = { cmd = '/usr/local/sbin/named-checkconf' }
```

### Colour coding

Applied with extmarks on top of the `named` syntax. The groups use
`default = true`, so a colorscheme that defines them wins; otherwise the
`highlight.colors` fallback is used.

| Group | Default | Meaning |
|---|---|---|
| `NamedZone` | green | `zone` clauses |
| `NamedOptions` | blue | `options` / `logging` / `controls` / `channel` |
| `NamedAcl` | mauve | `acl` / `view` / `key` / `server` / trust anchors |
| `NamedName` | teal | the quoted name of a zone/acl/view/key |
| `NamedZoneType` | peach | a zone's `type` (primary/secondary/forward/…) |
| `NamedFilter` | red | address-match statements (allow-\*, match-\*, listen-on, …) |

Set `highlight.background = true` to also tint each top-level clause's lines
(`NamedZoneLine` / `NamedOptionsLine` / `NamedAclLine`). Override colours in
`highlight.colors`, or theme-first by defining the groups yourself:

```lua
vim.api.nvim_set_hl(0, 'NamedZone', { fg = '#a6e3a1', bold = true })
```

### Documentation popups

A tiny **in-process LSP server** (Lua — nothing to install) attaches to
`named.conf` buffers and serves `textDocument/hover` and
`textDocument/completion` from a built-in knowledge base of the BIND schema:
top-level clauses, the common `options`/`zone`/`view`/`key`/`server` statements,
the `logging` channel options, zone `type` values, severities, TSIG algorithms,
and the built-in ACLs.

Because it's a real LSP, your existing keymaps just work:

- **`K`** shows the docs for the symbol under the cursor.
- Completion suggests documented statements/values for the current clause.
- **`:NamedDocs`** shows the same popup directly — handy if you keep the LSP off.

Set `lsp.enabled = false` to disable the server (`:NamedDocs` still works). Run
`:checkhealth named-conf` to see how many schema entries loaded.

### Example keymaps (optional)

The plugin ships **no keymaps**. Drop-in examples, scoped to attached buffers:

```lua
vim.api.nvim_create_autocmd('User', {
  pattern = 'NamedConfAttach',
  callback = function(args)
    local b = args.data.bufnr
    local map = function(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = b, desc = desc })
    end
    map('<leader>nc', '<cmd>NamedCheck<cr>',    'named-checkconf')
    map('<leader>nb', '<cmd>NamedBrowse<cr>',   'Browse clauses')
    map('<leader>nd', '<cmd>NamedDocs<cr>',     'Docs under cursor')
    map('<leader>nv', '<cmd>NamedValidate<cr>', 'Static validate')
  end,
})
```

## Commands

| Command | Description |
|---|---|
| `:NamedCheck` | Run `named-checkconf` on the current file |
| `:NamedValidate` | Re-run static checks (braces, duplicate zones) |
| `:NamedBrowse` | Browse and jump to a clause |
| `:NamedDocs` | Show docs for the statement under the cursor |
| `:NamedSnippet {name}` | Insert a skeleton (`zone-primary`, `acl`, `view`, …) |
| `:NamedAttach` | Attach features to the current buffer manually |

## Health

```vim
:checkhealth named-conf
```

## Development

Tests run against the project's target Neovim (0.12.2) inside the neodocker
image — not whatever is on the host:

```bash
tests/run.sh                      # whole suite
tests/run.sh tests/parser_spec.lua  # one file
```

`tests/run.sh` mirrors the essential mounts from `~/.neodocker.rc` headlessly.
Override the image with `NEODOCKER_IMAGE` or the config dir with `NVIMCONFDIR`.
The live `named-checkconf` integration test is skipped automatically when the
binary isn't installed.
