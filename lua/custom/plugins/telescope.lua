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
        }
      }

      -- Set some keymaps
      set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [h]elp - Telescope' })
      set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [f]iles - Telescope' })
      set('n', '<space>en', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[E]dit [N]eovim' })
      set('n', '<leader>sl', builtin.oldfiles, { desc = '[S]earch [l]ast files - Telescope' })
      set('n', '<space><space>', builtin.buffers, { desc = 'Open buffers - Telescope' })
      set('n', '<leader>sgl', builtin.live_grep, { desc = '[S]earch using [g]rep [l]ive - Telescope' })
      set('n', '<leader>sgs', builtin.grep_string, { desc = '[S]earch selected [s]tring - Telescope' })
      set('n', '<leader>sp', builtin.git_files, { desc = '[S]earch in [p]roject (git) - Telescope' })
    end
  }
}
