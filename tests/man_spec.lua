local kb = require('named-conf.knowledge')
local hover = require('named-conf.hover')
local man = require('named-conf.man')

describe('man page browser', function()
  describe('kb.lookup_any', function()
    it('resolves statements without clause context', function()
      local e, clause = kb.lookup_any('allow-query')
      assert.is_not_nil(e)
      assert.equals('options', clause)

      e, clause = kb.lookup_any('zone')
      assert.is_not_nil(e)
      assert.equals('top', clause)

      e, clause = kb.lookup_any('signatures-validity')
      assert.is_not_nil(e)
      assert.equals('dnssec-policy', clause)

      e, clause = kb.lookup_any('severity')
      assert.is_not_nil(e)
      assert.equals('logging', clause)
    end)

    it('returns nil for unknown words', function()
      assert.is_nil(kb.lookup_any('definitely-not-a-statement'))
    end)
  end)

  describe('hover in a man-dialect buffer', function()
    local function man_buf(lines)
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_var(bufnr, 'named_conf_dialect', 'man')
      return bufnr
    end

    it('documents statement names in prose', function()
      local bufnr = man_buf({
        'OPTIONS',
        '   allow-query { address_match_list };',
        '      Specifies which hosts may query the server.',
      })
      local md = hover.markdown(bufnr, 1, 5) -- on "allow-query"
      assert.is_not_nil(md)
      assert.truthy(md:find('allow%-query'))
      assert.truthy(md:find('in options'))
    end)

    it('documents built-in ACL names', function()
      local bufnr = man_buf({ 'The default is localhost only.' })
      local md = hover.markdown(bufnr, 0, 18) -- on "localhost"
      assert.is_not_nil(md)
      assert.truthy(md:find('localhost'))
    end)

    it('stays silent on undocumented prose words', function()
      local bufnr = man_buf({ '      Specifies which hosts may query the server.' })
      assert.is_nil(hover.markdown(bufnr, 0, 8)) -- on "Specifies"
    end)
  end)

  describe(':NamedMan open', function()
    it('renders the man page into a hover-enabled scratch buffer', function()
      if vim.fn.executable('man') ~= 1 then
        pending('man not installed')
        return
      end
      -- `man -w` must resolve to a real page file (Ubuntu's minimized-system
      -- stub exits 0 while printing a notice instead of a path).
      local path = vim.trim(vim.fn.system({ 'man', '-w', 'named.conf' }))
      if vim.v.shell_error ~= 0 or vim.fn.filereadable(path) ~= 1 then
        pending('named.conf man page not installed')
        return
      end

      local bufnr = man.open()
      assert.is_not_nil(bufnr)
      assert.equals('nofile', vim.bo[bufnr].buftype)
      assert.is_false(vim.bo[bufnr].modifiable)
      assert.equals('man', vim.api.nvim_buf_get_var(bufnr, 'named_conf_dialect'))
      local text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, 10, false), '\n')
      assert.truthy(text:lower():find('named'))
      assert.is_nil(text:find('\b', 1, true))

      -- Reopening focuses the existing buffer instead of rendering again.
      assert.equals(bufnr, man.open())
    end)
  end)
end)
