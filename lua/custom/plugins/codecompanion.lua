return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      adapters = {
        ollama = function()
          return require('codecompanion.adapters').extend('ollama', {
            schema = {
              model = {
                  default = 'qwen2.5-coder:7b'
              }
            }
          })
        end
      },
      strategies = {
        chat = {
            adapter = 'ollama'
        },
        inline = {
            adapter = 'ollama'
        }
      }
    },
  }
}
