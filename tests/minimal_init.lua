-- Minimal init for running the test suite headlessly:
--   nvim --headless --noplugin -u tests/minimal_init.lua \
--     -c "PlenaryBustedDirectory tests/ {minimal_init='tests/minimal_init.lua'}"
local repo = vim.fn.fnamemodify(vim.fn.getcwd(), ':p')
vim.opt.runtimepath:append(repo)

-- Headless test runs must not touch swap/shada (the state dir may be read-only,
-- e.g. inside the neodocker container).
vim.opt.swapfile = false
vim.opt.shadafile = 'NONE'

local plenary = vim.fn.stdpath('data') .. '/lazy/plenary.nvim'
vim.opt.runtimepath:append(plenary)

vim.cmd('runtime plugin/plenary.vim')
