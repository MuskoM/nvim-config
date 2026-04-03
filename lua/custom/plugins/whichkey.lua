return {
  {
    'folke/which-key.nvim',
    name = 'which-key',
    event = 'VeryLazy',
    opts = {},
    keys = {
      {
        '<leader>?',
        function()
          require('which-key').show({ global = false })
        end,
        desc = 'Buffer Local Keymaps (which-key)'
      }
    },
    config = function()
      local wk = require 'which-key'
      wk.setup {
        preset = 'helix',
        win = {
          padding = { 2, 3 }
        },
        icons = {
          group = '|'
        }
      }
      wk.add({
        { '<space>', group = 'Code' },
        { '<space>v', group = 'View' },
        { '<space>a', group = 'Actions' },
        { '<leader>l', group = 'List', icon = '' },
        { '<leader>s', group = 'Search' },
        { '<leader>o', group = 'Options', icon = '' },
        { '<leader>w', proxy = '<c-w>', group = 'Windows' }, -- Proxy to window mappings
        { '<leader>u', icon = "󰕌" },

      })
    end
  }
}
