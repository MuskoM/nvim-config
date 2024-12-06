return {
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {'nvim-lua/plenary.nvim'},
    config = function()
      local builtin = require 'telescope.builtin'
      local set = vim.keymap.set

      -- Set some keymaps
      set('n', '<leader>sf', builtin.find_files, {desc = '[S]earch [f]iles - Telescope'})
      set('n', '<leader>sl', builtin.oldfiles, {desc = '[S]earch [l]ast files - Telescope'})
      set('n', '<leader><leader>', builtin.buffers, {desc = 'Open buffers - Telescope'})
      set('n', '<leader>sg', builtin.buffers, {desc = '[S]earch using [g]rep - Telescope'})
    end
  }
}
