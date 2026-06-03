-- Jump to any clause (zone / acl / view / key / ...) in the file. Uses
-- snacks.nvim when available, otherwise falls back to vim.ui.select — so it
-- works with no extra dependency.
local parser = require('named-conf.parser')

local M = {}

--- Collect navigable items from the buffer.
---@param bufnr integer
---@return table[]  { text, lnum, block }
local function items(bufnr)
  local parsed = parser.parse(bufnr)
  local out = {}
  for _, b in ipairs(parsed.all) do
    -- Skip the most deeply nested noise (channels/categories) unless top-ish.
    if b.depth <= 1 then
      local label = parser.label(b)
      if b.clause == 'zone' and b.fields['type'] then
        label = label .. '  [' .. b.fields['type'] .. ']'
      end
      out[#out + 1] = { text = label, lnum = b.start_line, block = b }
    end
  end
  return out
end

local function jump(bufnr, lnum)
  local win = vim.fn.bufwinid(bufnr)
  if win == -1 then
    win = vim.api.nvim_get_current_win()
  end
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_cursor(win, { lnum, 0 })
  vim.cmd('normal! zz')
end

--- Browse clauses and jump to the chosen one.
function M.browse()
  local bufnr = vim.api.nvim_get_current_buf()
  local list = items(bufnr)
  if #list == 0 then
    vim.notify('[named] no clauses found in this buffer', vim.log.levels.INFO)
    return
  end

  local ok, snacks = pcall(require, 'snacks')
  if ok and snacks.picker then
    snacks.picker.pick({
      title = 'named.conf clauses',
      items = vim.tbl_map(function(it)
        return { text = it.text, pos = { it.lnum, 0 }, lnum = it.lnum, buf = bufnr }
      end, list),
      format = 'text',
      confirm = function(picker, item)
        picker:close()
        if item then jump(bufnr, item.lnum) end
      end,
    })
    return
  end

  -- Fallback: vim.ui.select.
  vim.ui.select(list, {
    prompt = 'named.conf clauses',
    format_item = function(it) return string.format('%s  (line %d)', it.text, it.lnum) end,
  }, function(choice)
    if choice then jump(bufnr, choice.lnum) end
  end)
end

return M
