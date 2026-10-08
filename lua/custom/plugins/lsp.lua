return {
  {
    'neovim/nvim-lspconfig',
    config = function()
      -- Lua lsp
      -- Neovim runtime, LuaJIT and plugin types for this config come from
      -- lazydev (dependency below). (Removed: kickstart's on_init block that
      -- injected the same runtime into lua_ls by hand.)
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

      -- Go. Formatting and import organising are conform's job (goimports,
      -- plugins/conform.lua); gopls is the fallback when goimports is absent.
      --
      -- Gated on the toolchain, matching the gopls entry in plugins/mason.lua
      -- -- see the longer note there for why only these two places are gated.
      -- Without the guard, opening a .go file on a machine with no Go would
      -- try to spawn a gopls that Mason was never able to build.
      if vim.fn.executable('go') == 1 then
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
      end


      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end

          -- Python: ty is primary, pyright is the fallback.
          --
          -- Compared by the capabilities each server reports (headless, ty
          -- 0.0.37): ty covers everything pyright does except call
          -- hierarchy, and adds inlay hints, semantic tokens, folding and
          -- type hierarchy -- and it is the faster of the two (Rust vs Node).
          -- Running both unfiltered gave duplicate completions, two hovers
          -- and doubled <space>v* results.
          --
          -- So pyright keeps only callHierarchyProvider (<space>vc / vC).
          -- Without ty on PATH pyright keeps everything and is the Python LSP.
          -- Formatting stays ruff's either way.
          if client.name == 'pyright' then
            client.server_capabilities.documentFormattingProvider = false
            if vim.fn.executable('ty') == 1 then
              for key in pairs(client.server_capabilities) do
                if key:match('Provider$') and key ~= 'callHierarchyProvider' then
                  client.server_capabilities[key] = nil
                end
              end
            end
          end

          -- conform.nvim owns format-on-save now (prettier for web filetypes,
          -- LSP fallback for the rest). Stop ts_ls from offering its own
          -- formatter so it never overrides prettier / the repo .prettierrc.
          if client.name == 'ts_ls' then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end

          -- Every mapping below is buffer-local; see the custom/keymaps.lua header.
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
          map({ 'n', 'x' }, '<space>aa', vim.lsp.buf.code_action, '[A]ctions')

          -- <space>v -- view the symbol's relationships, via Trouble.
          -- Sent as :Trouble commands rather than function calls so trouble.nvim
          -- stays lazy-loaded on its `cmd` trigger.
          --
          -- One pane for all of them. Trouble keys views by mode, so each
          -- lsp_* mode gets its own split: <space>vr then <space>vc used to
          -- stack a second pane on the first instead of reusing it. Close the
          -- other <space>v modes before opening. The same mode is left alone,
          -- since Trouble already reuses its own view. The diagnostics and
          -- outline panes stay open; they are toggles with their own keys.
          --
          -- package.loaded check: if trouble has not loaded yet, no view can
          -- be open, and require()-ing it here would undo the lazy-load.
          local view_modes = {
            'lsp_references', 'lsp_implementations', 'lsp_definitions',
            'lsp_declarations', 'lsp_incoming_calls', 'lsp_outgoing_calls',
          }
          local function view(mode, extra)
            return function()
              local trouble = package.loaded['trouble']
              if trouble then
                for _, m in ipairs(view_modes) do
                  if m ~= mode and trouble.is_open(m) then
                    trouble.close(m)
                  end
                end
              end
              vim.cmd('Trouble ' .. mode .. (extra and (' ' .. extra) or ''))
            end
          end
          map('n', '<space>vr', view('lsp_references', 'focus=true'), 'List [r]eferences')
          map('n', '<space>vi', view('lsp_implementations'), '[I]mplementations')
          map('n', '<space>vd', view('lsp_definitions'), '[D]efinition')
          map('n', '<space>vD', view('lsp_declarations'), '[D]eclaration')
          -- Call hierarchy. In a large Spring codebase this is the main tool
          -- for answering "how does execution actually reach this method?" --
          -- follow incoming calls up until you hit a @RestController.
          map('n', '<space>vc', view('lsp_incoming_calls'), 'Incoming [c]alls (who calls this)')
          map('n', '<space>vC', view('lsp_outgoing_calls'), 'Outgoing [C]alls (what this calls)')

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
