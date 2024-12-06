return {
  {
    'echasnovski/mini.nvim',
    dependencies = {
      'which-key'
    },
    config = function() 
      local wk = require 'which-key'
      -- Beautify

      local statusline = require 'mini.statusline'
      statusline.setup {use_icons = true}

      local icons = require 'mini.icons'
      icons.setup()

      local notify = require 'mini.notify'
      notify.setup()

      local pick = require 'mini.pick'
      pick.setup{
        window = {
          config = function ()
            local height = math.floor(0.5 * vim.o.lines)
            local width = math.floor(0.5 * vim.o.columns)
            return {
              anchor = 'NW', height = height, width = width,
              row = math.floor(0.5 * (vim.o.lines - height)),
              col = math.floor(0.5 * (vim.o.columns - width)),
            }
          end
        }
      }

      -- Workflow improved
      -- Easier file browsing
      local files = require 'mini.files'
      files.setup {
         windows = {preview = true}, 
         options = {
             use_as_default_explorer = false
         }
      }
      -- Setup mapping for opening the explorer
      wk.add({
        {'<leader>fe', files.open, desc = '[E]xplore [f]iles'}
      })

      local diff = require 'mini.diff'
      diff.setup()

      -- Editing improved

      -- Extended a & i objects
      local ai = require 'mini.ai'
      ai.setup()

      local surround = require 'mini.surround'
      surround.setup()
    end
  }
}
