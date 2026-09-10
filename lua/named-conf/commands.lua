-- User commands for named-conf.nvim.
local M = {}

local registered = false

function M.setup()
  if registered then
    return
  end
  registered = true

  local cmd = vim.api.nvim_create_user_command

  cmd('NamedAttach', function() require('named-conf.detect').attach() end,
    { desc = 'Attach named-conf features to the current buffer' })

  cmd('NamedBrowse', function() require('named-conf.picker').browse() end,
    { desc = 'Browse and jump to a clause (zone/acl/view/key/...)' })

  cmd('NamedDocs', function() require('named-conf.hover').show() end,
    { desc = 'Show BIND docs for the statement under the cursor' })

  cmd('NamedMan', function() require('named-conf.man').open() end,
    { desc = 'Open man named.conf in a buffer with docs hover (K / :NamedDocs)' })

  cmd('NamedCheck', function(o)
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, dialect = pcall(vim.api.nvim_buf_get_var, bufnr, 'named_conf_dialect')
    if ok and dialect == 'zone' then
      require('named-conf.checkzone').run(bufnr, { origin = o.args ~= '' and o.args or nil })
    else
      require('named-conf.checkconf').run(bufnr)
    end
  end, {
    nargs = '?',
    desc = 'Run named-checkconf (named-checkzone for zone files; optional arg = origin)',
  })

  cmd('NamedZoneCheck', function(o)
    require('named-conf.checkzone').run(nil, { origin = o.args ~= '' and o.args or nil })
  end, {
    nargs = '?',
    desc = 'Run named-checkzone on the current file (optional arg = zone origin)',
  })

  cmd('NamedValidate', function() require('named-conf.validate').run() end,
    { desc = 'Run static checks (braces, duplicate zones) on the buffer' })

  cmd('NamedSnippet', function(o)
    require('named-conf.snippets').insert(o.args)
  end, {
    nargs = 1,
    complete = function() return require('named-conf.snippets').names() end,
    desc = 'Insert a named.conf snippet (zone-primary, acl, view, ...)',
  })
end

return M
