-- Java / Gradle setup.
--
-- Started per-buffer rather than via vim.lsp.enable() in lsp.lua, because jdtls
-- keeps a stateful compiled project model in a workspace directory, one per
-- project root. See lua/custom/plugins/jdtls.lua.
--
-- The jdtls config (compile target, Lombok, capabilities, format profile) used
-- to be built inline here. It moved to lua/custom/java.lua so the VimEnter
-- start in plugins/jdtls.lua builds the identical config -- a drifted copy
-- would start a second server instead of reusing the first.

-- Editor basics, unrelated to the LSP. 4 spaces, no tabs.
local set = vim.opt_local
set.shiftwidth = 4
set.tabstop = 4
set.softtabstop = 4
set.expandtab = true

require('custom.java').attach()
