return {
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
    },
    config = function()
      local builtin = require 'telescope.builtin'
      local set = vim.keymap.set

      require 'telescope'.setup {
        pickers = {
          find_files = { theme = 'ivy' },
          buffers = { theme = 'ivy' },
          live_grep = { theme = 'ivy' },
          grep_string = { theme = 'ivy' },
          git_files = { theme = 'ivy' },
        },
        extensions = {
          fzf = {}
        }
      }

      -- Load extension
      require('telescope').load_extension('fzf')

      -- Set some keymaps
      set('n', '<leader>sh', builtin.help_tags, { desc = 'Search in help' })
      set('n', '<leader>sf', builtin.find_files, { desc = 'Search in files' })
      set('n', '<leader>s?', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = 'Search in neovim configs' })
      set('n', '<leader>sl', builtin.oldfiles, { desc = 'Search last opened' })
      set('n', '<space><space>', builtin.buffers, { desc = 'Buffers' })
      set('n', '<leader>sg', builtin.live_grep, { desc = 'Search text (rg)' })
      set({ 'n', 'v' }, '<leader>ss', builtin.grep_string, { desc = 'Search selected text (grep)' })
      set('n', '<leader>sp', builtin.git_files, { desc = 'Search in project (git)' })

      local wk = require('which-key')
      wk.add({
        { '<leader>sh', desc = 'Search in help', icon = '󰋖' },
        { '<leader>sf', desc = 'Search in files', icon = { icon = "", color = 'purple' } },
        { '<leader>s?', desc = 'Search in neovim configs', icon = { icon = '', color = 'red' } },
        { '<leader>sl', desc = 'Search last opened', icon = { icon = '', color = 'purple' }, },
        { '<space><space>', desc = 'Buffers', icon = { icon = '' } },
        { '<leader>sg', desc = 'Search text (rg)', icon = '󰦨' },
        { '<leader>ss', desc = 'Search selected text (grep)', icon = '󰦨' },
        { '<leader>sp', desc = 'Search in project (git)' },
      })
    end
  }
}
