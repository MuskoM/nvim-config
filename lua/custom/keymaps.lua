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

-- LSP base keymaps
local lsp = vim.lsp.buf
set('n', '<leader>cr', lsp.rename, { desc = 'Rename - LSP' })
set('n', '<leader>ca', lsp.code_action, { desc = 'Code actions - LSP' })
-- set('n', '<leader>vr', lsp.references, { desc = 'View references - LSP' })
-- set('n', '<leader>vi', lsp.implementation, { desc = 'View implementation - LSP' })
--
-- Diagnostic keymaps
-- vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' }) -- use Trouble instead
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Op[e]n diagnostic in float' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')
