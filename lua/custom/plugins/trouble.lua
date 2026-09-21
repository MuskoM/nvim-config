return {
  {
    'folke/trouble.nvim',
    opts = {
      auto_close = true,
    },
    cmd = 'Trouble',
    -- Only the diagnostic lists live here. The LSP-dependent views
    -- (<space>v* references/implementations/calls, and <space>o for the
    -- document outline) are registered buffer-locally in the LspAttach autocmd
    -- in plugins/lsp.lua, so they exist only where a server is attached. They
    -- are issued as :Trouble commands, which still triggers the `cmd` lazy-load
    -- above.
    --
    -- Diagnostics stay global: vim.diagnostic is not LSP-only -- linters and
    -- other producers populate it too -- so these are meaningful in any buffer.
    keys = {
      {
        '<space>D',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = 'All [D]iagnostics',
      },
      {
        '<space>d',
        '<cmd>Trouble diagnostics toggle filter.buf=0 focus=false<cr>',
        desc = 'Local [d]iagnostics',
      },
    },
  },
}
