-- Skeleton snippets for common named.conf blocks. Inserted at the cursor with
-- correct indentation; a fresh buffer gets a sensible starting point.
local M = {}

-- name -> array of lines (no trailing newline).
local TEMPLATES = {
  ['zone-primary'] = {
    'zone "example.com" IN {',
    '    type primary;',
    '    file "example.com.zone";',
    '    allow-transfer { key "transfer-key"; };',
    '    notify yes;',
    '};',
  },
  ['zone-secondary'] = {
    'zone "example.com" IN {',
    '    type secondary;',
    '    primaries { 192.0.2.1; };',
    '    file "secondary/example.com.zone";',
    '};',
  },
  ['zone-forward'] = {
    'zone "example.com" IN {',
    '    type forward;',
    '    forward only;',
    '    forwarders { 192.0.2.53; };',
    '};',
  },
  acl = {
    'acl "trusted" {',
    '    localhost;',
    '    192.0.2.0/24;',
    '};',
  },
  view = {
    'view "internal" {',
    '    match-clients { "trusted"; };',
    '    recursion yes;',
    '',
    '    zone "example.com" IN {',
    '        type primary;',
    '        file "internal/example.com.zone";',
    '    };',
    '};',
  },
  key = {
    'key "transfer-key" {',
    '    algorithm hmac-sha256;',
    '    secret "REPLACE_WITH_BASE64_SECRET";',
    '};',
  },
  options = {
    'options {',
    '    directory "/var/named";',
    '    listen-on port 53 { 127.0.0.1; };',
    '    allow-query { localhost; };',
    '    recursion no;',
    '    dnssec-validation auto;',
    '};',
  },
  logging = {
    'logging {',
    '    channel default_log {',
    '        file "named.log" versions 3 size 20m;',
    '        severity info;',
    '        print-time yes;',
    '    };',
    '    category default { default_log; };',
    '};',
  },
}

--- The available snippet names (for command completion).
---@return string[]
function M.names()
  local out = {}
  for k in pairs(TEMPLATES) do
    out[#out + 1] = k
  end
  table.sort(out)
  return out
end

--- Insert a named snippet at the cursor, matching the current indentation.
---@param name string
function M.insert(name)
  local tmpl = TEMPLATES[name]
  if not tmpl then
    vim.notify('[named] unknown snippet: ' .. tostring(name)
      .. ' (try: ' .. table.concat(M.names(), ', ') .. ')', vim.log.levels.WARN)
    return
  end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local cur = vim.api.nvim_get_current_line()
  local indent = cur:match('^(%s*)') or ''
  local lines = {}
  for i, l in ipairs(tmpl) do
    lines[i] = (l == '') and '' or (indent .. l)
  end
  vim.api.nvim_buf_set_lines(0, row, row, false, lines)
  vim.api.nvim_win_set_cursor(0, { row + 1, #indent })
end

return M
