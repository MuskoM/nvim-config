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
--   1. Global, set here            -- <space>e (vim.diagnostic)
--   2. Global, set in a lazy spec  -- <space>d, <space>D, <space>q, <space>t
--                                     (trouble.nvim), <space>f, <space>F
--                                     (conform), <space><space> (telescope)
--   3. Buffer-local, on attach     -- <space>a*, <space>v*, <space>o, gd
--                                     (LspAttach, plugins/lsp.lua; jdtls adds
--                                     <space>ao, <space>ae* in custom/java.lua)
--      Buffer-local, by filetype   -- <localleader>m (RouterOS, helpers.lua)
--
-- Tier 3 is why a <space> key can be present in a Java file and absent in a
-- text file: that is correct, not a bug. The LSP maps used to be global, which
-- left dead keys in every markdown and text file. It is also the sharp edge --
-- a buffer-local mapping silently shadows a global one on the same keys, with
-- no warning. New localleader mappings must dodge the suffixes already taken:
-- <space>, a, d, D, e, f, F, o, q, t, v, <, >.
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

-- Reverse f/t/F/T repeat. Leader is ',', which takes the built-in `,` with it;
-- `\` is free once it stops being the leader, and sits next to `;` on the
-- keyboard row above. Visual and operator-pending too, like the original.
set({ 'n', 'x', 'o' }, '\\', ',', { desc = 'Repeat f/t backwards' })

-- LSP mappings are buffer-local, in plugins/lsp.lua (see the header above).

-- Diagnostic keymaps. Global on purpose: vim.diagnostic is populated by
-- linters and other non-LSP producers too, so these mean something anywhere.
-- (<space>q, the quickfix list in Trouble, is in plugins/trouble.lua.)
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, { desc = 'Show diagnostic modal' })

-- Inlay hints (parameter names, inferred types) for the buffer's servers.
-- Off by default -- they reflow every line they touch -- so a toggle.
vim.keymap.set('n', '<leader>oh', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = 0 }, { bufnr = 0 })
end, { desc = 'Toggle inlay [h]ints' })

-- (Removed <leader>cT "TypeScript project check": subsumed by <leader>cc in
-- custom/checks.lua.)

-- (Removed <Esc><Esc> in terminal mode: Claude Code's terminal needs
-- double-Esc itself; <C-\><C-n> still leaves terminal mode.)

-- (Removed <leader>or "Reload Neovim config": it never reloaded anything, and
-- plugin setup() calls cannot be re-run anyway -- restart instead.)

-- Fugitive. Repo-level git; hunk-level actions are set buffer-locally by
-- gitsigns (see plugins/gitsigns.lua) and share this <leader>g prefix.
vim.keymap.set('n', '<leader>gs', ':Git<CR>', { desc = 'Git status' })
vim.keymap.set('n', '<leader>gd', ':Gdiffsplit<CR>', { desc = 'Diff split' })
vim.keymap.set('n', '<leader>gc', ':Git commit<CR>', { desc = 'Commit' })
vim.keymap.set('n', '<leader>gb', ':Git blame<CR>', { desc = 'Blame buffer' })
vim.keymap.set('n', '<leader>gm', ':Git mergetool<CR>', { desc = 'Mergetool' })
-- Every commit that touched this file, into quickfix, shown in Trouble. `!`
-- so Fugitive does not jump to the first commit.
vim.keymap.set('n', '<leader>gh', '<cmd>0Gclog!<CR><cmd>Trouble qflist open<CR>', { desc = 'File [h]istory' })

-- Merge conflict resolution: take the change from theirs (//3) or ours (//2).
-- Only meaningful inside a three-way :Gdiffsplit.
vim.keymap.set('n', '<leader>gj', ':diffget //3<CR>', { desc = 'Take from theirs (right)' })
vim.keymap.set('n', '<leader>gf', ':diffget //2<CR>', { desc = 'Take from ours (left)' })
