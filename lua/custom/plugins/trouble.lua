return {
  {
    'folke/trouble.nvim',
    opts = {
      auto_close = true
    },
    cmd = 'Trouble',
    keys = {
      {
        '<leader>cD',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = 'All [D]iagnostics - Trouble',
      },
      {
        '<leader>cd',
        '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
        desc = 'Local [d]iagnostics - Trouble',
      },
      {
        '<leader>vr',
        '<cmd>Trouble lsp_references focus=true<cr>',
        desc = 'View references - Trouble'
      },
      {
        '<leader>vi',
        '<cmd>Trouble lsp_implementations<cr>',
        desc = 'View implementations - Trouble'
      },
      {
        '<leader>vd',
        '<cmd>Trouble lsp_definitions<cr>',
        desc = 'View definitions - Trouble'
      },
      {
        '<leader>vD',
        '<cmd>Trouble lsp_declarations<cr>',
        desc = 'View declarations - Trouble'
      },
      {
        '<leader>ts',
        '<cmd>Trouble symbols toggle focus=false<cr>',
        desc = '[T]oggle Document Symbols - Trouble',
      },
      {
        '<leader>tl',
        '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
        desc = '[T]oggle [L]SP Definitions / references / ...  - Trouble',
      },
      {
        '<leader>l',
        '<cmd>Trouble loclist toggle<cr>',
        desc = '[L]ocation List - Trouble',
      },
      {
        '<leader>q',
        '<cmd>Trouble qflist toggle<cr>',
        desc = '[Q]uickfix List - Trouble',
      },
    },
  },

}
