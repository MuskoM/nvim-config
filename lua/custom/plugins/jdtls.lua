return {
  -- Java support is started per-buffer from after/ftplugin/java.lua, not with
  -- vim.lsp.enable() in lsp.lua like your other servers.
  --
  -- Why: jdtls keeps a stateful compiled model of the project in a workspace
  -- directory on disk, one per project root. The single global client that
  -- vim.lsp.enable() creates cannot express that. nvim-jdtls provides
  -- start_or_attach, which reuses a client when the root matches.
  { 'mfussenegger/nvim-jdtls', ft = 'java' },
}
