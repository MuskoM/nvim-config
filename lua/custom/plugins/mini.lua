return {
  {
    'echasnovski/mini.nvim',
    dependencies = {
      'which-key'
    },
    config = function()
      local wk = require 'which-key'
      -- Beautify

      local icons = require 'mini.icons'
      icons.setup()

      local pick = require 'mini.pick'
      pick.setup {
        window = {
          config = function()
            local height = math.floor(0.5 * vim.o.lines)
            local width = math.floor(0.5 * vim.o.columns)
            return {
              anchor = 'NW',
              height = height,
              width = width,
              row = math.floor(0.5 * (vim.o.lines - height)),
              col = math.floor(0.5 * (vim.o.columns - width)),
            }
          end
        }
      }

      local diff = require 'mini.diff'
      diff.setup()
    end
  }
}
