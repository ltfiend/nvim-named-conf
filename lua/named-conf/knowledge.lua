-- Knowledge-base index: loads kb/* and resolves documentation for a statement
-- keyword or an argument value given a context (see context.lua).
local M = {}

local function safe_require(name)
  local ok, mod = pcall(require, name)
  if ok and type(mod) == 'table' then
    return mod
  end
  return {}
end

local top = safe_require('named-conf.kb.top')
local options = safe_require('named-conf.kb.options')
local zone = safe_require('named-conf.kb.zone')
local logging = safe_require('named-conf.kb.logging')
local misc = safe_require('named-conf.kb.misc')

M.top = top
M.options = options
M.zone = zone
M.logging = logging
M.misc = misc

local function merge(...)
  local out = {}
  for _, t in ipairs({ ... }) do
    if type(t) == 'table' then
      for k, v in pairs(t) do
        if out[k] == nil then
          out[k] = v
        end
      end
    end
  end
  return out
end

-- Per-clause statement tables (name -> entry).
local options_keys = options.keys or {}
local zone_keys = merge({ type = zone.type }, zone.keys or {})
local logging_keys = logging.keys or {}
local view_keys = merge(misc.view or {}, options_keys)
local key_keys = misc.key or {}
local key_store_keys = misc.key_store or {}
local server_keys = misc.server or {}
local controls_keys = misc.controls or {}
local tls_keys = misc.tls or {}
local http_keys = misc.http or {}
local dlz_keys = misc.dlz or {}
local dnssec_policy_keys = misc.dnssec_policy or {}

-- Statement tables searched (in order) for a given enclosing clause.
local function scope_tables(clause)
  if clause == 'options' then
    return { options_keys, top }
  elseif clause == 'zone' then
    return { zone_keys, options_keys, top }
  elseif clause == 'view' then
    return { view_keys, top }
  elseif clause == 'logging' or clause == 'channel' or clause == 'category' then
    return { logging_keys, top }
  elseif clause == 'key' then
    return { key_keys, top }
  elseif clause == 'key-store' then
    return { key_store_keys, top }
  elseif clause == 'server' then
    return { server_keys, top }
  elseif clause == 'controls' then
    return { controls_keys, top }
  elseif clause == 'tls' then
    return { tls_keys, top }
  elseif clause == 'http' then
    return { http_keys, top }
  elseif clause == 'dlz' then
    return { dlz_keys, top }
  elseif clause == 'dnssec-policy' then
    return { dnssec_policy_keys, top }
  end
  return { top }
end

--- Resolve documentation for a statement KEYWORD within a context.
---@param name string
---@param ctx { clause: string }|nil
---@return table|nil entry
function M.lookup_key(name, ctx)
  local clause = ctx and ctx.clause or 'top'
  for _, t in ipairs(scope_tables(clause)) do
    if type(t[name]) == 'table' and t[name].summary then
      return t[name]
    end
  end
  -- Last resort: any clause keyword (so `zone`/`options`/... always hover).
  if top[name] then
    return top[name]
  end
  return nil
end

--- The entry that "owns" the value-list on a given line (so we can document its
--- enum values), e.g. the `type` entry, the `severity` entry, etc.
---@param line_key string|nil
---@param ctx { clause: string }|nil
---@return table|nil
local function owner_entry(line_key, ctx)
  if not line_key then
    return nil
  end
  return M.lookup_key(line_key, ctx)
end

--- Resolve documentation for a VALUE within a context.
---@param value string
---@param line_key string|nil  the statement keyword on the value's line
---@param ctx { clause: string }|nil
---@return table|nil entry
function M.lookup_value(value, line_key, ctx)
  local owner = owner_entry(line_key, ctx)
  if owner and owner.values and owner.values[value] then
    return { summary = owner.values[value] }
  end
  -- Built-in ACLs / booleans usable in address-match lists.
  if misc.values and misc.values[value] then
    return misc.values[value]
  end
  return nil
end

--- Render an entry to a markdown string for a hover popup.
---@param name string
---@param entry table
---@param ctx { clause: string }|nil
---@return string
function M.render(name, entry, ctx)
  local lines = {}
  local where = ''
  if ctx and ctx.clause and ctx.clause ~= 'top' then
    where = ('  *(in %s)*'):format(ctx.clause)
  end
  table.insert(lines, ('**`%s`**%s'):format(name, where))
  table.insert(lines, '')
  if entry.summary then
    table.insert(lines, entry.summary)
    table.insert(lines, '')
  end
  if entry.doc then
    table.insert(lines, entry.doc)
    table.insert(lines, '')
  end
  if entry.values then
    table.insert(lines, '**Values:**')
    local keys = {}
    for k in pairs(entry.values) do
      keys[#keys + 1] = k
    end
    table.sort(keys)
    for _, k in ipairs(keys) do
      table.insert(lines, ('- `%s` — %s'):format(k, entry.values[k]))
    end
  end
  return (table.concat(lines, '\n'):gsub('%s+$', ''))
end

--- Candidate statement keywords to offer for completion in the given context.
---@param ctx { clause: string }
---@return table[]  list of { name, entry }
function M.key_candidates(ctx)
  local out, seen = {}, {}
  for _, t in ipairs(scope_tables(ctx and ctx.clause or 'top')) do
    for k, v in pairs(t) do
      if type(v) == 'table' and v.summary and not seen[k] then
        seen[k] = true
        out[#out + 1] = { name = k, entry = v }
      end
    end
  end
  return out
end

--- Candidate values for the current statement keyword (enum values, plus the
--- built-in ACLs when this looks like an address-match list).
---@param line_key string|nil
---@param ctx { clause: string }|nil
---@return table[]  list of { name, entry }
function M.value_candidates(line_key, ctx)
  local out = {}
  local owner = owner_entry(line_key, ctx)
  if owner and owner.values then
    for k, v in pairs(owner.values) do
      out[#out + 1] = { name = k, entry = { summary = v } }
    end
  end
  -- Address-match contexts (allow-*, match-*, blackhole, ...) accept ACL names.
  if line_key and (line_key:match('^allow%-') or line_key:match('^match%-')
    or line_key == 'blackhole' or line_key == 'listen-on' or line_key == 'listen-on-v6') then
    for k, v in pairs(misc.values or {}) do
      if k ~= 'yes' and k ~= 'no' then
        out[#out + 1] = { name = k, entry = v }
      end
    end
  end
  return out
end

return M
