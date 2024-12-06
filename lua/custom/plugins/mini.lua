return {
  {
    'echasnovski/mini.nvim',
    config = function() 
      -- Beautify

      local statusline = require 'mini.statusline'
      statusline.setup {use_icons = true}

      local icons = require 'mini.icons'
      icons.setup()

      local notify = require 'mini.notify'
      notify.setup()

      -- Workflow improved
      local files = require 'mini.files'
      files.setup {
         windows = {preview = true}, 
         options = {
             use_as_default_explorer = false
         }
      }
      -- Setup mapping for opening the explorer
      vim.keymap.set('n', '<leader>bf', files.open, {desc = '[B]rowse [f]iles'})

      -- Editing improved

      -- Extended a & i objects
      local ai = require 'mini.ai'
      ai.setup()

      local surround = require 'mini.surround'
      surround.setup()
    end
  }
}
