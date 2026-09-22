return {
  {
    'neovim/nvim-lspconfig',
    config = function()
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

      -- -- Vue lsp
      -- vim.lsp.config('vue_ls', {
      --   -- add filetypes for typescript, javascript and vue
      --   filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
      --   init_options = {
      --     vue = {
      --       -- disable hybrid mode
      --       hybridMode = false,
      --     },
      --   },
      -- })
      -- vim.lsp.enable('vue_ls')

      vim.lsp.enable('ts_ls')

      vim.lsp.enable('eslint')

      -- Underscore, not hyphen: nvim-lspconfig ships lsp/rust_analyzer.lua, and
      -- vim.lsp.enable() on a name with no matching file fails silently.
      vim.lsp.config('rust_analyzer', { filetypes = { 'rust' } })
      vim.lsp.enable('rust_analyzer')

      -- Go. gopls needs the Go toolchain on PATH. Formatting and import
      -- organising are conform's job (goimports, plugins/conform.lua); gopls is
      -- the fallback when goimports is not installed.
      vim.lsp.config('gopls', {
        settings = {
          gopls = {
            -- staticcheck's extra analyses; the ones below are off by default.
            staticcheck = true,
            analyses = {
              unusedparams = true,
              unusedvariable = true,
              unusedwrite = true,
              useany = true,
            },
          },
        },
      })
      vim.lsp.enable('gopls')


      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end

          if client.name == 'pyright' then
            client.server_capabilities.documentFormattingProvider = false -- Let ruff handle that also
          end

          -- conform.nvim owns format-on-save now (prettier for web filetypes,
          -- LSP fallback for the rest). Stop ts_ls from offering its own
          -- formatter so it never overrides prettier / the repo .prettierrc.
          if client.name == 'ts_ls' then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end

          -- Every mapping below is buffer-local, so it exists only where a
          -- server is attached. That is the point: these used to be global in
          -- keymaps.lua, which left them present-but-dead in a markdown or
          -- plain-text buffer.
          --
          -- Deliberately NOT gated on client:supports_method(). jdtls registers
          -- most capabilities dynamically after initialize, so at LspAttach
          -- time server_capabilities.definitionProvider is still nil and the
          -- check returns false even though definition works fine. The
          -- vim.lsp.buf.* functions already no-op with a warning when no
          -- attached client can answer, so the gate bought nothing.
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc })
          end

          -- Vim's built-in `gd` means "go to local declaration" -- a textual
          -- search within the current file. On a Java type that lands on the
          -- import statement, not the class. Buffers with no server keep the
          -- built-in behaviour.
          map('n', 'gd', vim.lsp.buf.definition, 'Goto definition (LSP)')

          -- <space>a -- act on the symbol
          map('n', '<space>ar', vim.lsp.buf.rename, '[R]ename symbol')
          -- Visual mode too: with a selection, jdtls offers the extract
          -- refactorings (method, variable, constant) that it cannot infer
          -- from a bare cursor position.
          map({ 'n', 'v' }, '<space>aa', vim.lsp.buf.code_action, '[A]ctions')

          -- <space>v -- view the symbol's relationships, via Trouble.
          -- Sent as :Trouble commands rather than function calls so trouble.nvim
          -- stays lazy-loaded on its `cmd` trigger.
          map('n', '<space>vr', '<cmd>Trouble lsp_references focus=true<cr>', 'List [r]eferences')
          map('n', '<space>vi', '<cmd>Trouble lsp_implementations<cr>', '[I]mplementations')
          map('n', '<space>vd', '<cmd>Trouble lsp_definitions<cr>', '[D]efinition')
          map('n', '<space>vD', '<cmd>Trouble lsp_declarations<cr>', '[D]eclaration')
          -- Call hierarchy. In a large Spring codebase this is the main tool
          -- for answering "how does execution actually reach this method?" --
          -- follow incoming calls up until you hit a @RestController.
          map('n', '<space>vc', '<cmd>Trouble lsp_incoming_calls<cr>', 'Incoming [c]alls (who calls this)')
          map('n', '<space>vC', '<cmd>Trouble lsp_outgoing_calls<cr>', 'Outgoing [C]alls (what this calls)')

          -- Document outline for the current buffer.
          map('n', '<space>o', '<cmd>Trouble symbols toggle focus=false win.size=0.3<cr>',
            'Toggle document [o]utline')

          -- Group labels registered against this buffer only, so the <space>
          -- menu does not advertise an empty "View symbol" submenu in files
          -- with no language server.
          local wk_ok, wk = pcall(require, 'which-key')
          if wk_ok then
            wk.add {
              { '<space>a', group = 'Actions', buffer = args.buf },
              { '<space>v', group = 'View symbol', buffer = args.buf },
            }
          end
        end
      })
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
