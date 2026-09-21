return {
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    dependencies = { { 'echasnovski/mini.icons', opts = {} } },
    -- Stays eager: oil replaces netrw, so it has to be loaded before the first
    -- buffer in case nvim is opened on a directory (`nvim .`). The keymap below
    -- is declared here rather than in config so which-key picks up the desc.
    lazy = false,
    keys = {
      { '<leader>f', '<cmd>Oil<CR>', desc = 'File manager (oil)' },
    },
    opts = {
      view_options = {
        show_hidden = true,
        is_always_hidden = function(name, _)
          return name == '.' or name == '..'
        end,
      },
    },
  },
}
