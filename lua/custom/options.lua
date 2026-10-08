-- Indentations as (4) spaces
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.expandtab = true

vim.o.number = true
vim.o.relativenumber = true

vim.g.have_nerd_font = true

vim.opt.mouse = 'a'

-- Mode, "recording @q" and pending keys are shown in the statusline
-- (custom/statusline.lua): noice swallows the messages these options print
-- in the command line.
vim.opt.showmode = false
vim.opt.showcmd = true
vim.opt.showcmdloc = 'statusline'

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

-- No treesitter language.register for markdown: parser and filetype are both
-- 'markdown'. Conceal is not set globally; render-markdown sets it per window,
-- so it does not leak into other filetypes.
