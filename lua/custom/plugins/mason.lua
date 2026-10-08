return {
  {
    "williamboman/mason.nvim",
    priority = 40,
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require('mason').setup {
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      }
      -- gopls is gated on the Go toolchain rather than listed unconditionally.
      -- Mason installs it with `go install`, so on a machine without `go` on
      -- PATH the install fails and Mason reports it at every startup.
      --
      -- Gated, not deleted: the same config should still set Go up on a
      -- machine that has the toolchain.
      --
      -- Only the two toolchain-dependent halves of Go support are gated this
      -- way -- here, and the gopls block in plugins/lsp.lua. The treesitter
      -- parsers, conform's goimports entry and after/ftplugin/go.lua are left
      -- ungated on purpose: parsers build with the C compiler, and the other
      -- two only fire inside a .go buffer. Reading Go needs no toolchain, and
      -- gating those too would cost highlighting for no benefit.
      local servers = {
        'lua_ls', 'pyright', 'ruff', 'ty', 'bashls',
        'jdtls', 'ts_ls', 'eslint', 'rust_analyzer',
      }
      if vim.fn.executable('go') == 1 then
        table.insert(servers, 'gopls')
      end

      require('mason-lspconfig').setup {
        ensure_installed = servers
      }
    end
  }
}
