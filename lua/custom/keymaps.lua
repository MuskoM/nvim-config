local set = vim.keymap.set
-- Remove highlight
set('n', '<ESC>', '<cmd>nohl<CR>')

-- Move between splits easier
set('n', '<c-h>', '<c-w>h', { desc = 'Move to left pane' })
set('n', '<c-j>', '<c-w>j', { desc = 'Move to down pane' })
set('n', '<c-k>', '<c-w>k', { desc = 'Move to top pane' })
set('n', '<c-l>', '<c-w>l', { desc = 'Move to right pane' })

-- LSP base keymaps
local lsp = vim.lsp.buf
set('n', '<space>ar', lsp.rename, { desc = '[R]ename' })
set('n', '<space>aa', lsp.code_action, { desc = '[A]ctions' })
-- set('n', '<leader>vr', lsp.references, { desc = 'View references - LSP' })
-- set('n', '<leader>vi', lsp.implementation, { desc = 'View implementation - LSP' })
--
-- Diagnostic keymaps
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' }) -- use Trouble instead
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, { desc = 'Show diagnostic modal' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Hot reload neovim (config)
vim.keymap.set("n", "<leader>or", function()
  vim.print(vim.inspect(package.loaded))
end, { desc = "Reload Neovim config" })
