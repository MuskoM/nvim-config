return {
  {
    'ThePrimeagen/harpoon',
    enabled = false,
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require('harpoon')
      harpoon:setup()

      -- Keymaps
      local wk = require 'which-key'
      local bk = '<leader>h'
      wk.add({
        { bk, group = 'Harpoon', icon = '󰛢' },
        { bk .. 'a', function() harpoon:list():add() end, desc = 'Add', icon = '' },
        { bk .. 'r', function() harpoon:list():remove(harpoon:list():get(1)) end, desc = 'Remove', icon = '' },
        { bk .. 'h', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, desc = 'Quick Menu' },
        { bk .. 'p', function() harpoon:list():prev() end, desc = 'Previous', icon = '' },
        { bk .. 'n', function() harpoon:list():next() end, desc = 'Next', icon = '' },
        { bk .. '1', function() harpoon:list():select(1) end, desc = 'hook', icon = '󰬺' },
        { bk .. '2', function() harpoon:list():select(2) end, desc = 'hook', icon = '󰬻' },
        { bk .. '3', function() harpoon:list():select(3) end, desc = 'hook', icon = '󰬼' },
        { bk .. '4', function() harpoon:list():select(4) end, desc = 'hook', icon = '󰬽' },
        { bk .. '5', function() harpoon:list():select(5) end, desc = 'hook', icon = '󰬾' },

      })
    end
  }
}
