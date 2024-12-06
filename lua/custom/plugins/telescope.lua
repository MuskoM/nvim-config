return {
    {
        'nvim-telescope/telescope.nvim',
        branch = '0.1.x',
        dependencies = {'nvim-lua/plenary.nvim'},
        config = function()
            local builtin = require 'telescope.builtin'
            local set = vim.keymap.set

            -- Set some keymaps
            set('n', '<leader>ff', builtin.find_files, {desc = '[F]ind [f]iles - Telescope'})
            set('n', '<leader>fl', builtin.oldfiles, {desc = '[F]ind [l]ast files - Telescope'})
            set('n', '<leader><leader>', builtin.buffers, {desc = 'Open buffers - Telescope'})
            set('n', '<leader>fg', builtin.buffers, {desc = '[F]ind by [g]rep - Telescope'})
        end
    }
}
