-- Go is formatted with real tabs (gofmt), so undo the global 4-space
-- expandtab from options.lua for Go buffers.
vim.opt_local.expandtab = false
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 0

-- Every indent is a tab, so the global listchars would draw a '» ' on every
-- indented line. Keep the trailing-space marker, hide the tab marker.
vim.opt_local.listchars = { tab = '  ', trail = '·', nbsp = '␣' }
