return {
  {
    'neovim/nvim-lspconfig',
    config = function()
      local lsp = require 'lspconfig'
      lsp.lua_ls.setup {}
      lsp.ruff.setup {}
      lsp.volar.setup {}
      lsp.ts_ls.setup {
        init_options = {
          plugins = {
            {
              name = "@vue/typescript-plugin",
              location = "~/.bun/install/cache/@vue/typescript-plugin",
              languages = { "javascript", "typescript", "vue" },
            },
          },
        },
        filetypes = {
          "javascript",
          "typescript",
          "vue",
        },
      }

      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end

          -- Setup autoformatting
          if client.supports_method('textDocument/formatting') then
            vim.api.nvim_create_autocmd('BufWritePre', {
              buffer = args.buf,
              callback = function()
                vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
              end
            })
          end
        end
      })

      -- Keymaps
      vim.keymap.set('n', "<space>f", vim.lsp.buf.format, { desc = 'Format file' })
    end,
    dependencies = {
      {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
          library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
    }
  }
}
