return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<space>f',
      function()
        require('conform').format({ async = true, lsp_format = 'fallback' })
      end,
      mode = '',
      desc = 'Format file',
    },
  },
  opts = {
    -- Web filetypes go through Prettier. conform auto-discovers the
    -- project-local node_modules/.bin/prettier and Prettier itself reads the
    -- nearest .prettierrc, so formatting always matches the repo's config.
    formatters_by_ft = {
      javascript = { 'prettier' },
      javascriptreact = { 'prettier' },
      typescript = { 'prettier' },
      typescriptreact = { 'prettier' },
      json = { 'prettier' },
      jsonc = { 'prettier' },
      css = { 'prettier' },
      scss = { 'prettier' },
      less = { 'prettier' },
      html = { 'prettier' },
      yaml = { 'prettier' },
      markdown = { 'prettier' },
      graphql = { 'prettier' },
    },
    -- Single source of truth for format-on-save. Filetypes without a formatter
    -- above fall back to the attached LSP (lua_ls, ruff, ...).
    format_on_save = {
      timeout_ms = 2000,
      lsp_format = 'fallback',
    },
  },
}
