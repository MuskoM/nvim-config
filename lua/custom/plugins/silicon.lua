return {
  {
    'krivahtoo/silicon.nvim',
    build = './install.sh',
    enabled = false,
    config = function()
      local silicon = require 'silicon'
      silicon.setup {
        font = 'Cantarell',
        theme = 'Catppuccin-Macchiato',
        output = {
          clipboard = true
        }
      }
    end
  }
}
