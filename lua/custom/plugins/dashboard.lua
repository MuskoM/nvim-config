return {
  {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    config = function()
      require('dashboard').setup {
        config = {
          week_header = {
            enable = true,
          },
          shortcut = {
            -- action can be a function type
            { desc = 'Edit nvim config', group = 'DashboardShortCutIcon', key = '?', action = 'e ~/.config/nvim/' },
          },
        },
      }
    end,
    dependencies = { { 'nvim-tree/nvim-web-devicons' } }
  }
}
