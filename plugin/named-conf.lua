-- Plugin entry point. Guards against double-loading. The heavy lifting happens
-- in lua/named-conf/*; this only ensures detection works even if the user never
-- calls setup() explicitly (sensible zero-config defaults).
if vim.g.loaded_named_conf then
  return
end
vim.g.loaded_named_conf = true

if vim.fn.has('nvim-0.11') == 0 then
  vim.schedule(function()
    vim.notify('named-conf.nvim requires Neovim 0.11+ (developed on 0.12.2)', vim.log.levels.WARN)
  end)
  return
end

-- Zero-config: register detection + commands using defaults. A later explicit
-- setup() call simply re-applies with user options.
require('named-conf.detect').setup_autocmds()
require('named-conf.commands').setup()
