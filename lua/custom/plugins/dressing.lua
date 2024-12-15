return {
  {
    'stevearc/dressing.nvim',
    name = 'dressing',
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require('dressing').setup {
        input = {
          enabled = false
        },
        select = {
          backend = { 'telescope', 'builtin', 'nui' },
        }
      }
    end
  }
}
