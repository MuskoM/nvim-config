return {
  {
    'neovim/nvim-lspconfig',
    config = function()
      local lsp = require 'lspconfig'

      -- Lua lsp
      vim.lsp.config('lua_ls', {
        on_init = function(client)
          if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if
                path ~= vim.fn.stdpath('config')
                and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
            then
              return
            end
          end

          client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
            runtime = {
              -- Tell the language server which version of Lua you're using (most
              -- likely LuaJIT in the case of Neovim)
              version = 'LuaJIT',
              -- Tell the language server how to find Lua modules same way as Neovim
              -- (see `:h lua-module-load`)
              path = {
                'lua/?.lua',
                'lua/?/init.lua',
              },
            },
            -- Make the server aware of Neovim runtime files
            workspace = {
              checkThirdParty = false,
              library = {
                vim.env.VIMRUNTIME
                -- Depending on the usage, you might want to add additional paths
                -- here.
                -- '${3rd}/luv/library'
                -- '${3rd}/busted/library'
              }
            }
          })
        end,
        settings = {
          Lua = {}
        }

      })
      vim.lsp.enable('lua_ls')

      -- Bash lsp
      vim.lsp.enable('bashls')

      -- Python lsps
      -- Ruff
      vim.lsp.enable('ruff')

      -- Pyright
      vim.lsp.config('pyright', {
        settings = {
          pyright = {
            disableOrganizeImports = true,
          },
          python = {
            analysis = {
              ignore = { '*' } -- Leave analysis to ruff
            }
          }
        }
      })
      vim.lsp.enable('pyright')

      -- ty typechecker
      vim.lsp.enable('ty')

      -- Vue lsp
      vim.lsp.config('vue_ls', {
        -- add filetypes for typescript, javascript and vue
        filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
        init_options = {
          vue = {
            -- disable hybrid mode
            hybridMode = false,
          },
        },
      })
      vim.lsp.enable('vue_ls')


      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end

          if client.name == 'pyright' then
            client.server_capabilities.documentFormattingProvider = false -- Let ruff handle that also
          end

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
