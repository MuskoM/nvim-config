-- Java / Gradle setup. jdtls is started per-buffer, not via vim.lsp.enable();
-- see lua/custom/java.lua.

-- Editor basics, unrelated to the LSP. 4 spaces, no tabs.
local set = vim.opt_local
set.shiftwidth = 4
set.tabstop = 4
set.softtabstop = 4
set.expandtab = true

require('custom.java').attach()
