local set = vim.keymap.set
-- Execute lua inside neovim configs
set('n', '<space><space>x', '<cmd>source %<CR>')
set('n', '<space>x', ':.lua<CR>')
set('v', '<space>x', ':.lua<CR>')

-- Remove highlight
set('n', '<ESC>', '<cmd>nohl<CR>')
