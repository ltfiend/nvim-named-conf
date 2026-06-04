-- Semantic colour coding for named.conf buffers.
--
-- Layered over the built-in `named` syntax with extmarks, so it works whether or
-- not treesitter is installed. We colour:
--   * each clause keyword (zone / options / view / acl / key / logging / ...),
--     grouped into three palettes (zone, options-like, acl-like);
--   * the quoted name of a zone / acl / view / key / server;
--   * a zone's `type` value (master / slave / forward / hint / stub / ...);
--   * address-match "filter" statements (allow-*, match-*, listen-on, ...).
-- Optionally each top-level clause's lines get a subtle background tint.
local config = require('named-conf.config')
local parser = require('named-conf.parser')

local M = {}

M.ns = vim.api.nvim_create_namespace('named-conf-hl')

-- Clause keyword -> highlight group.
local GROUP = {
  zone = 'NamedZone',
  options = 'NamedOptions',
  logging = 'NamedOptions',
  channel = 'NamedOptions',
  category = 'NamedOptions',
  controls = 'NamedOptions',
  ['statistics-channels'] = 'NamedOptions',
  plugin = 'NamedOptions',
  dlz = 'NamedOptions',
  dyndb = 'NamedOptions',
  http = 'NamedOptions',
  acl = 'NamedAcl',
  view = 'NamedAcl',
  key = 'NamedAcl',
  ['key-store'] = 'NamedAcl',
  server = 'NamedAcl',
  masters = 'NamedAcl',
  primaries = 'NamedAcl',
  ['remote-servers'] = 'NamedAcl',
  tls = 'NamedAcl',
  ['parental-agents'] = 'NamedAcl',
  ['trusted-keys'] = 'NamedAcl',
  ['managed-keys'] = 'NamedAcl',
  ['trust-anchors'] = 'NamedAcl',
  ['dnssec-policy'] = 'NamedAcl',
}

-- Group -> background line-highlight group (used when highlight.background).
local LINE_GROUP = {
  NamedZone = 'NamedZoneLine',
  NamedOptions = 'NamedOptionsLine',
  NamedAcl = 'NamedAclLine',
}

-- Address-match-list / access-control statements — the "filters".
local FILTER = {
  ['allow-query'] = true,
  ['allow-query-cache'] = true,
  ['allow-query-cache-on'] = true,
  ['allow-query-on'] = true,
  ['allow-recursion'] = true,
  ['allow-recursion-on'] = true,
  ['allow-transfer'] = true,
  ['allow-update'] = true,
  ['allow-update-forwarding'] = true,
  ['allow-notify'] = true,
  ['allow-proxy'] = true,
  ['allow-proxy-on'] = true,
  blackhole = true,
  ['deny-answer-addresses'] = true,
  ['exempt-clients'] = true,
  ['response-padding'] = true,
  ['sig0checks-quota-exempt'] = true,
  ['match-clients'] = true,
  ['match-destinations'] = true,
  ['listen-on'] = true,
  ['listen-on-v6'] = true,
  ['also-notify'] = true,
  forwarders = true,
  ['keep-response-order'] = true,
  ['no-case-compress'] = true,
}

local hl_defined = false

--- Define the highlight groups (idempotent; safe to call on ColorScheme).
function M.define_highlights()
  local c = config.options.highlight.colors
  local function def(name, opts)
    opts.default = true
    vim.api.nvim_set_hl(0, name, opts)
  end
  def('NamedZone', { fg = c.zone, bold = true })
  def('NamedOptions', { fg = c.options, bold = true })
  def('NamedAcl', { fg = c.acl, bold = true })
  def('NamedName', { fg = c.name })
  def('NamedZoneType', { fg = c.type, bold = true })
  def('NamedFilter', { fg = c.filter, bold = true })
  def('NamedZoneLine', { bg = c.zone_bg })
  def('NamedOptionsLine', { bg = c.options_bg })
  def('NamedAclLine', { bg = c.acl_bg })
  hl_defined = true
end

--- Strip a trailing line comment so cosmetic regexes don't match commented text.
---@param line string
---@return string
local function strip_comment(line)
  local cut = #line + 1
  for _, pat in ipairs({ '//', '#', '/%*' }) do
    local s = line:find(pat)
    if s and s < cut then
      cut = s
    end
  end
  return line:sub(1, cut - 1)
end

--- Compute extmark specs for a list of lines (pure; used by apply and tests).
--- Each mark is `{ line, col, end_col, hl }` or `{ line, line_hl }` (0-indexed).
---@param lines string[]
---@param opts { background?: boolean }|nil
---@return table[]
function M.compute_lines(lines, opts)
  opts = opts or {}
  local marks = {}
  local parsed = parser.parse_lines(lines)

  for _, b in ipairs(parsed.all) do
    local grp = GROUP[b.clause]
    if grp then
      local header = lines[b.start_line] or ''
      local lnum = b.start_line - 1

      -- The clause keyword.
      local ks, ke = header:find(b.clause, 1, true)
      if ks then
        marks[#marks + 1] = { line = lnum, col = ks - 1, end_col = ke, hl = grp }
      end

      -- The quoted name (if any).
      if b.name then
        local ns = header:find('"' .. b.name .. '"', ke or 1, true)
        if ns then
          marks[#marks + 1] = { line = lnum, col = ns, end_col = ns + #b.name, hl = 'NamedName' }
        end
      end

      -- Background tint for top-level clauses.
      if opts.background and b.depth == 0 then
        local lg = LINE_GROUP[grp]
        for l = b.start_line, b.end_line do
          marks[#marks + 1] = { line = l - 1, line_hl = lg }
        end
      end

      -- A zone's `type` value.
      if b.clause == 'zone' then
        for l = b.start_line, b.end_line do
          local code = strip_comment(lines[l] or '')
          local val = code:match('^%s*type%s+([%w%-_]+)')
          if val then
            local vs = code:find(val, 1, true)
            marks[#marks + 1] = { line = l - 1, col = vs - 1, end_col = vs - 1 + #val, hl = 'NamedZoneType' }
          end
        end
      end
    end
  end

  -- Address-match "filter" statements, anywhere.
  for i, line in ipairs(lines) do
    local code = strip_comment(line)
    local ws = code:match('^%s*')
    local key = code:match('^%s*([%w%-_]+)')
    if key and FILTER[key] then
      local col = #ws
      marks[#marks + 1] = { line = i - 1, col = col, end_col = col + #key, hl = 'NamedFilter' }
    end
  end

  return marks
end

--- Re-apply colour coding to a buffer.
---@param bufnr integer
function M.apply(bufnr)
  if not config.options.highlight.enabled then
    return
  end
  if not hl_defined then
    M.define_highlights()
  end
  vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local background = config.options.highlight.background
  for _, m in ipairs(M.compute_lines(lines, { background = background })) do
    if m.line_hl then
      pcall(vim.api.nvim_buf_set_extmark, bufnr, M.ns, m.line, 0, { line_hl_group = m.line_hl })
    else
      local len = #(lines[m.line + 1] or '')
      local ec = math.min(m.end_col, len)
      if ec > m.col then
        pcall(vim.api.nvim_buf_set_extmark, bufnr, M.ns, m.line, m.col, {
          end_col = ec, hl_group = m.hl,
        })
      end
    end
  end
end

--- Attach colour coding to a buffer (re-applies on change / save).
---@param bufnr integer
function M.setup_buffer(bufnr)
  M.define_highlights()
  local group = require('named-conf.detect').augroup
  M.apply(bufnr)

  local timer
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    buffer = bufnr, group = group,
    callback = function()
      if timer then timer:stop() end
      timer = vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          M.apply(bufnr)
        end
      end, 200)
    end,
  })
  vim.api.nvim_create_autocmd('BufWritePost', {
    buffer = bufnr, group = group,
    callback = function() M.apply(bufnr) end,
  })
end

return M
