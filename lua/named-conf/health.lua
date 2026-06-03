-- :checkhealth named-conf
local config = require('named-conf.config')

local M = {}

local function start(name) (vim.health.start or vim.health.report_start)(name) end
local function ok(msg) (vim.health.ok or vim.health.report_ok)(msg) end
local function warn(msg) (vim.health.warn or vim.health.report_warn)(msg) end
local function err(msg) (vim.health.error or vim.health.report_error)(msg) end
local function info(msg) (vim.health.info or vim.health.report_info)(msg) end

function M.check()
  start('named-conf')

  if vim.fn.has('nvim-0.11') == 1 then
    ok('Neovim 0.11+ (' .. tostring(vim.version()) .. ')')
  else
    err('Neovim 0.11+ required (developed/tested on 0.12.2)')
  end

  start('named-checkconf')
  local cc = config.options.checkconf
  if vim.fn.executable(cc.cmd) == 1 then
    ok(("'%s' found"):format(cc.cmd))
    if cc.chroot and cc.chroot ~= '' then
      info('chroot: ' .. cc.chroot .. ' (passed as -t)')
    end
    if cc.args and #cc.args > 0 then
      info('extra args: ' .. table.concat(cc.args, ' '))
    end
  else
    warn(("'%s' not found — :NamedCheck disabled (set checkconf.cmd)"):format(cc.cmd))
  end

  start('Optional dependencies')
  if pcall(require, 'snacks') then
    ok('snacks.nvim found (:NamedBrowse uses its picker)')
  else
    info('snacks.nvim not found — :NamedBrowse falls back to vim.ui.select')
  end
  if pcall(require, 'blink.cmp') then
    ok('blink.cmp found (statement completion source available)')
  else
    info('blink.cmp not found — completion still available via the in-process LSP')
  end

  start('Documentation (hover/LSP)')
  if config.options.lsp.enabled then
    ok('in-process docs LSP enabled (hover via K, plus :NamedDocs)')
  else
    info('docs LSP disabled — :NamedDocs still works')
  end
  local kb = require('named-conf.knowledge')
  local n_top = vim.tbl_count(kb.top or {})
  local n_opt = vim.tbl_count((kb.options or {}).keys or {})
  local n_zone = vim.tbl_count((kb.zone or {}).keys or {})
  local n_log = vim.tbl_count((kb.logging or {}).keys or {})
  if n_top + n_opt + n_zone + n_log == 0 then
    warn('knowledge base is empty (kb/*.lua failed to load)')
  else
    ok(string.format('knowledge base: %d clauses, %d options, %d zone, %d logging statements',
      n_top, n_opt, n_zone, n_log))
  end
end

return M
