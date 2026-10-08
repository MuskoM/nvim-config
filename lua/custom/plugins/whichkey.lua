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
      -- Central register of group labels. Individual mappings carry their own
      -- desc at the definition site; only the prefixes are named here.
      --
      -- The two trees mirror the scheme documented at the top of
      -- custom/keymaps.lua: <space> acts on this buffer, <leader> reaches out.
      wk.add({
        -- <space> -- acts on this buffer / the symbol under the cursor.
        -- <space>a / <space>v groups are registered buffer-locally with their
        -- LSP mappings in plugins/lsp.lua, so no empty submenus without a server.
        { '<space>', group = 'Buffer / LSP' },

        -- <leader> -- reaches outside the buffer
        { '<leader>s', group = 'Search' },
        { '<leader>g', group = 'Git' },
        { '<leader>c', group = 'Check / compile' },
        { '<leader>o', group = 'Options', icon = '' },
        { '<leader>w', proxy = '<c-w>', group = 'Windows' }, -- Proxy to window mappings
        { '<leader>u', icon = "󰕌" },
        -- <leader>R (REST / kulala) registers itself in plugins/kulala.lua, so
        -- the group disappears with the plugin if it is ever removed.

        -- Removed: { '<leader>l', group = 'List' } -- named a group with no
        -- mappings behind it, so which-key advertised an empty submenu.
      })
    end
  }
}
