local set = vim.keymap.set
-- Execute lua inside neovim configs
set('n', '<space>lf', '<cmd>source %<CR>', { desc = '[L]ua [f]ile' })
set('n', '<space>lx', ':.lua<CR>', { desc = '[L]ua e[x]ecute' })
set('v', '<space>lx', ':.lua<CR>', { desc = '[L]ua e[x]ecute' })

-- Remove highlight
set('n', '<ESC>', '<cmd>nohl<CR>')

-- Move between splits easier
set('n', '<c-h>', '<c-w>h', { desc = 'Move to left pane' })
set('n', '<c-j>', '<c-w>j', { desc = 'Move to down pane' })
set('n', '<c-k>', '<c-w>k', { desc = 'Move to top pane' })
set('n', '<c-l>', '<c-w>l', { desc = 'Move to right pane' })
