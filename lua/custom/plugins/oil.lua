return {
  {
    'stevearc/oil.nvim',
    ---@module oil
    ---@type oil.SetupOpts
    opts = {},
    dependencies = { { 'echasnovski/mini.icons', opts = {} } },
    lazy = false,
    config = function()
      require('oil').setup {
        view_options = {
          show_hidden = true,
          is_always_hidden = function(name, bufnr)
            if name == '.' or name == '..' then
              return true
            end
            return false
          end
        }
      }
    end
  }
}
