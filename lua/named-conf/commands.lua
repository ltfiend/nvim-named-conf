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

  cmd('NamedCheck', function() require('named-conf.checkconf').run() end,
    { desc = 'Run named-checkconf on the current file' })

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
