-- Indentations as (4) spaces
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.expandtab = true

vim.o.number = true
vim.o.relativenumber = true

vim.g.have_nerd_font = true

vim.opt.mouse = 'a'

-- Show/hide the mode, since it's already in the status line
vim.opt.showmode = true

-- Disable/enable search count/select count etc. in bottom right corner
vim.opt.showcmd = true

vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'nosplit'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- (Removed: vim.treesitter.language.register('markdown', {}) -- registering a
-- language against an empty filetype list was a no-op. Nothing was needed in
-- its place: 'markdown' is its own filetype and the parser is named after it,
-- so the parsers/filetypes lists in plugins/treesitter.lua cover it, and
-- register() is only for the cases where the two names disagree.
--
-- An earlier version of this note claimed markdown treesitter was "handled by
-- simply not enabling it" -- stale, and the opposite of what the code does:
-- markdown highlighting is on, and markdown + markdown_inline are load-bearing
-- for noice's LSP hover windows.)
--
-- Conceal is deliberately not set here either. render-markdown.nvim sets
-- 'conceallevel' and 'concealcursor' per window while it renders and restores
-- them after, so setting them globally would leak conceal into every other
-- filetype to no benefit.
