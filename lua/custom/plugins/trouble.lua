return {
  {
    'folke/trouble.nvim',
    opts = {
      auto_close = true
    },
    cmd = 'Trouble',
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
      {
        '<space>vr',
        '<cmd>Trouble lsp_references focus=true<cr>',
        desc = 'List [R]eferences'
      },
      {
        '<space>vi',
        '<cmd>Trouble lsp_implementations<cr>',
        desc = '[V]iew [I]mplementations of a interface'
      },
      {
        '<space>vd',
        '<cmd>Trouble lsp_definitions<cr>',
        desc = '[V]iew [d]efinition'
      },
      {
        '<space>vD',
        '<cmd>Trouble lsp_declarations<cr>',
        desc = '[V]iew [D]eclaration'
      },
      {
        '<leader>os',
        '<cmd>Trouble symbols toggle focus=false<cr>',
        desc = 'Toggle Document Symbols',
      },
    },
  },

}
