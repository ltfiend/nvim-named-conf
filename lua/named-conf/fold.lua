-- Clause-aware folding for named.conf buffers.
--
-- Folds follow brace depth, and the fold summary names the clause instead of
-- showing a bare `{ ... }`:
--
--   ▸ zone "example.com" IN  [master]  → example.com.zone  (8 lines)
--   ▸ options  (24 lines)
--   ▸ acl "trusted"  (4 lines)
--
-- Folding uses `foldexpr` (brace depth). With `fold.nested = false` only
-- top-level clauses fold; set it true to also fold inner blocks (channels,
-- per-view zones).
local config = require('named-conf.config')
local parser = require('named-conf.parser')

local M = {}

-- Cache of the parsed block tree per buffer, keyed by changedtick, so foldexpr
-- (called once per line) and foldtext share one parse.
local cache = setmetatable({}, { __mode = 'k' })

---@param bufnr integer
---@return table  parsed result
local function parsed_for(bufnr)
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)
  local c = cache[bufnr]
  if c and c.tick == tick then
    return c.parsed
  end
  local p = parser.parse(bufnr)
  cache[bufnr] = { tick = tick, parsed = p }
  return p
end

--- Brace-depth fold level for a line. Lines that open a block increase the
--- level from that line; lines that close it keep the level until after.
---@param lnum integer 1-based
---@return string
function M.foldexpr(lnum)
  local bufnr = vim.api.nvim_get_current_buf()
  local parsed = parsed_for(bufnr)
  local nested = config.options.fold.nested

  local level, opens = 0, false
  for _, b in ipairs(parsed.all) do
    if (nested or b.depth == 0) and b.start_line <= lnum and lnum <= b.end_line then
      local d = nested and (b.depth + 1) or 1
      if d > level then
        level = d
      end
      if b.start_line == lnum then
        opens = true
      end
    end
  end

  if opens then
    return '>' .. level
  end
  return tostring(level)
end

--- The summary text shown on a closed fold.
---@return string
function M.foldtext()
  local bufnr = vim.api.nvim_get_current_buf()
  local start = vim.v.foldstart
  local parsed = parsed_for(bufnr)

  -- The block whose header is on the fold's first line.
  local block
  for _, b in ipairs(parsed.all) do
    if b.start_line == start then
      if not block or b.depth < block.depth then
        block = b
      end
    end
  end

  local n = vim.v.foldend - vim.v.foldstart + 1
  if not block then
    local line = vim.fn.getline(start)
    return string.format('▸ %s  (%d lines)', vim.trim(line):gsub('%s*{%s*$', ''), n)
  end

  if config.options.fold.text then
    local ok, custom = pcall(config.options.fold.text, {
      block = block, lines = n, foldstart = start, foldend = vim.v.foldend,
    })
    if ok and type(custom) == 'string' then
      return custom
    end
  end

  local parts = { '▸ ' .. parser.label(block) }
  if block.class then
    parts[1] = parts[1] .. ' ' .. block.class
  end
  if block.clause == 'zone' then
    if block.fields['type'] then
      parts[#parts + 1] = '[' .. block.fields['type'] .. ']'
    end
    if block.fields['file'] then
      parts[#parts + 1] = '→ ' .. block.fields['file']:gsub('^"', ''):gsub('"$', '')
    end
  end
  parts[#parts + 1] = string.format('(%d lines)', n)
  return table.concat(parts, '  ')
end

--- Configure folding for a buffer.
---@param bufnr integer
function M.setup_buffer(bufnr)
  vim.api.nvim_buf_call(bufnr, function()
    vim.opt_local.foldmethod = 'expr'
    vim.opt_local.foldexpr = "v:lua.require'named-conf.fold'.foldexpr(v:lnum)"
    vim.opt_local.foldtext = "v:lua.require'named-conf.fold'.foldtext()"
  end)
end

return M
