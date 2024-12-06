return {
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {},
    keys = {
      {
        '<leader>?',
        function()
          require('which-key').show({global = false})
        end,
        desc = 'Buffer Local Keymaps (which-key)'
      }
    },
    config = function()
      local wk = require 'which-key'
      wk.setup {
        preset = 'helix'
      }
      wk.add({
        {'<leader>s', group = 'Search' },
        {'<leader>w', proxy='<c-w>', group = 'Windows'}, -- Proxy to window mappings
      })
    end
  }
}
