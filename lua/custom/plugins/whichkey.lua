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
        { '<leader>s', group = 'Search' },
        { '<space>l',  group = 'Lua' },
        { '<leader>f', group = 'Files' },
        { '<leader>w', proxy = '<c-w>', group = 'Windows' }, -- Proxy to window mappings
      })
    end
  }
}
