-- Keymap scheme
-- =============
--
-- Two prefixes, split by SCOPE -- what the mapping reaches, not what it does:
--
--   <leader> (`,`)  Global. Available in every buffer regardless of filetype or
--                   what is running. Reaches outside the current file: search,
--                   git, file manager, REST client, pipelines.
--
--   <space>         This buffer. What is under the cursor, or the file being
--                   edited: rename, code actions, diagnostics, format, symbol
--                   views, document outline.
--
-- <localleader> is ALSO <space> (set in init.lua). That is deliberate, not an
-- accident of configuration: <space> already means "this buffer", and
-- localleader exists precisely for mappings that only apply to certain buffers.
-- Giving them separate prefixes would have split one idea across two keys.
--
-- The consequence is that <space> mappings come from three registration sites,
-- and it is worth knowing which is which when one goes missing:
--
--   1. Global, set here            -- <space>e, <space>q (vim.diagnostic)
--   2. Global, set in a lazy spec  -- <space>d, <space>D (trouble.nvim)
--                                     <space>f (conform), <space><space>
--   3. Buffer-local, on attach     -- <space>a*, <space>v*, <space>o, gd
--                                     (LspAttach, plugins/lsp.lua)
--      Buffer-local, by filetype   -- <localleader>m (RouterOS, helpers.lua)
--
-- Tier 3 is why a <space> key can be present in a Java file and absent in a
-- text file: that is correct, not a bug. It is also the sharp edge -- a
-- buffer-local mapping silently shadows a global one on the same keys, with no
-- warning. New localleader mappings must dodge the suffixes already taken
-- globally: <space>, a, d, D, e, f, o, q, v.
--
-- One deliberate exception to the scope rule:
--
--   <space><space>  buffer switcher. Global by scope, so it belongs under
--                   <leader>s -- but it is the most-pressed key here and the
--                   double-tap is the point.
--
--   (<space>D, workspace diagnostics, looks like a second exception. It is not:
--   diagnostics are a property of buffers, and splitting it from <space>d would
--   separate a pair that is always used together.)
--
-- Plugin-owned mappings live in that plugin's spec under `keys = {}`, so lazy
-- can defer loading until first press. Everything not tied to a plugin is here.
-- which-key group labels are in plugins/whichkey.lua, except the buffer-local
-- ones, which are registered alongside their mappings in plugins/lsp.lua.

local set = vim.keymap.set
-- Remove highlight
set('n', '<ESC>', '<cmd>nohl<CR>')

-- Move between splits easier
set('n', '<c-h>', '<c-w>h', { desc = 'Move to left pane' })
set('n', '<c-j>', '<c-w>j', { desc = 'Move to down pane' })
set('n', '<c-k>', '<c-w>k', { desc = 'Move to top pane' })
set('n', '<c-l>', '<c-w>l', { desc = 'Move to right pane' })

-- LSP mappings are NOT here. <space>ar, <space>aa, <space>v* and <space>o are
-- registered buffer-locally in the LspAttach autocmd in plugins/lsp.lua, so
-- they exist only in buffers where a language server is attached. Defining
-- them globally, as they were, left dead keys in every markdown and text file.

-- Diagnostic keymaps. Global on purpose: vim.diagnostic is populated by
-- linters and other non-LSP producers too, so these mean something anywhere.
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' }) -- use Trouble instead
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, { desc = 'Show diagnostic modal' })

-- (Removed <leader>cT "TypeScript project check": subsumed by <leader>cc in
-- custom/checks.lua, which is the same jobstart -> errorformat -> quickfix ->
-- Trouble pipeline driven off a per-filetype table instead of a hardcoded
-- `yarn typecheck`. Two things changed in the move, both fixes rather than
-- refactors: it runs vim.system and merges stderr, because javac writes
-- diagnostics there and on_stdout alone would have called a failing Gradle
-- build clean; and a non-zero exit with no parseable output now reports the
-- exit code rather than an empty list that reads as success. No alias left
-- behind -- <leader>cc does the same thing from a TypeScript buffer.)

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- (Removed <leader>or "Reload Neovim config": it only printed package.loaded,
-- it never reloaded anything. A truthful reload would have to clear
-- package.loaded for custom.* and re-require, which still cannot re-run plugin
-- setup() calls -- so the honest answer is to restart. Ask if you want the
-- partial version anyway; it is useful when editing these files specifically.)

-- Fugitive. Repo-level git; hunk-level actions are set buffer-locally by
-- gitsigns (see plugins/gitsigns.lua) and share this <leader>g prefix.
vim.keymap.set('n', '<leader>gs', ':Git<CR>', { desc = 'Git status' })
vim.keymap.set('n', '<leader>gd', ':Gdiffsplit<CR>', { desc = 'Diff split' })
vim.keymap.set('n', '<leader>gc', ':Git commit<CR>', { desc = 'Commit' })
vim.keymap.set('n', '<leader>gb', ':Git blame<CR>', { desc = 'Blame buffer' })
vim.keymap.set('n', '<leader>gm', ':Git mergetool<CR>', { desc = 'Mergetool' })

-- Merge conflict resolution: take the change from theirs (//3) or ours (//2).
-- Only meaningful inside a three-way :Gdiffsplit.
vim.keymap.set('n', '<leader>gj', ':diffget //3<CR>', { desc = 'Take from theirs (right)' })
vim.keymap.set('n', '<leader>gf', ':diffget //2<CR>', { desc = 'Take from ours (left)' })
