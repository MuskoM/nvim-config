return {
  {
    'krivahtoo/silicon.nvim',
    init = ' install.sh',
    enabled = false,
    config = function()
      local silicon = require 'silicon'
      silicon.setup {
        font = 'FiraCode Nerd Font Mono',
        theme = 'Catppuccin-Macchiato'
      }
    end
  }
}
