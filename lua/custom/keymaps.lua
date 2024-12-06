local set = vim.keymap.set
-- Execute lua inside neovim configs
set('n', '<space><space>x', '<cmd>source %<CR>')
set('n', '<space>x', ':.lua<CR>')
set('v', '<space>x', ':.lua<CR>')

-- Remove highlight
set('n', '<ESC>', '<cmd>nohl<CR>')

-- Move between splits easier
set('n', '<c-h>', '<c-w>h', {desc = 'Move to left pane'})
set('n', '<c-j>', '<c-w>j', {desc = 'Move to down pane'})
set('n', '<c-k>', '<c-w>k', {desc = 'Move to top pane'})
set('n', '<c-l>', '<c-w>l', {desc = 'Move to right pane'})
