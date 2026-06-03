-- Static, in-process diagnostics for named.conf buffers. These are cheap checks
-- that run on every change without invoking named-checkconf (which is the
-- authoritative validator — see checkconf.lua). We deliberately only flag things
-- we can detect reliably: unbalanced braces and duplicate zone names.
local config = require('named-conf.config')
local parser = require('named-conf.parser')

local M = {}

M.ns = vim.api.nvim_create_namespace('named-conf-validate')

--- Compute diagnostics for a list of lines.
---@param lines string[]
---@return table[]  vim.Diagnostic list
function M.diagnostics_for(lines)
  local sev = vim.diagnostic.severity
  local diags = {}

  -- Brace balance (comment/string-aware via the tokenizer).
  local tokens = parser.tokenize(lines)
  local open_stack = {}
  for _, tok in ipairs(tokens) do
    if tok.kind == 'punct' and tok.text == '{' then
      open_stack[#open_stack + 1] = tok.line
    elseif tok.kind == 'punct' and tok.text == '}' then
      if #open_stack == 0 then
        diags[#diags + 1] = {
          lnum = tok.line - 1, col = 0, severity = sev.ERROR,
          message = "unmatched '}'", source = 'named',
        }
      else
        open_stack[#open_stack] = nil
      end
    end
  end
  for _, lnum in ipairs(open_stack) do
    diags[#diags + 1] = {
      lnum = lnum - 1, col = 0, severity = sev.ERROR,
      message = "unclosed '{' (missing '}')", source = 'named',
    }
  end

  -- Duplicate zone names within the same scope (same enclosing block).
  local parsed = parser.parse_lines(lines)
  local seen = {}
  for _, z in ipairs(parsed.zones) do
    if z.name then
      local scope = z.parent and tostring(z.parent) or 'top'
      local class = z.class or 'IN'
      local key = scope .. '\0' .. z.name .. '\0' .. class
      if seen[key] then
        diags[#diags + 1] = {
          lnum = z.start_line - 1, col = 0, severity = sev.ERROR,
          message = string.format('duplicate zone "%s" in this scope', z.name),
          source = 'named',
        }
      end
      seen[key] = true
    end
  end

  return diags
end

--- Compute diagnostics for a buffer.
---@param bufnr integer
---@return table[]
function M.diagnostics(bufnr)
  return M.diagnostics_for(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
end

--- Run validation now and publish diagnostics.
---@param bufnr integer|nil
function M.run(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not config.options.validate.enabled then
    return
  end
  vim.diagnostic.set(M.ns, bufnr, M.diagnostics(bufnr))
end

--- Attach validation autocmds to a buffer.
---@param bufnr integer
function M.setup_buffer(bufnr)
  local group = require('named-conf.detect').augroup
  local vcfg = config.options.validate

  if vcfg.on_save then
    vim.api.nvim_create_autocmd('BufWritePost', {
      buffer = bufnr, group = group,
      callback = function() M.run(bufnr) end,
    })
  end

  if vcfg.on_change then
    local timer = nil
    vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
      buffer = bufnr, group = group,
      callback = function()
        if timer then timer:stop() end
        timer = vim.defer_fn(function()
          if vim.api.nvim_buf_is_valid(bufnr) then
            M.run(bufnr)
          end
        end, vcfg.debounce)
      end,
    })
  end

  M.run(bufnr)
end

return M
