-- nvim-treesitter, `main` branch.
--
-- This is a full rewrite, not a version bump: `ensure_installed`,
-- `auto_install` and `sync_install` no longer exist, and the plugin no longer
-- turns highlighting on for you. Parsers are installed with install(), and
-- highlighting is opted into per filetype with vim.treesitter.start().
--
-- Requires Neovim 0.12+, a C compiler, and tree-sitter-cli >= 0.26.1 installed
-- via a system package manager (brew install tree-sitter) -- explicitly NOT the
-- npm build, which is a different, older artefact.

-- Parser names.
local parsers = {
  'bash',
  'c',
  'go',
  'gomod',
  'gowork',
  -- No 'http' here, deliberately: kulala.nvim ships its own kulala-http
  -- parser for that filetype, and two parsers on one filetype make
  -- highlighting flicker. (Briefly added for rest.nvim, 2026-09; removed when
  -- the config went back to kulala.)
  'java',
  'javascript',
  'json',
  'lua',
  -- markdown_inline handles the spans inside a markdown document (code, links,
  -- emphasis); the markdown parser injects into it. Both are needed for LSP
  -- hover windows, which noice renders through treesitter -- see the
  -- lsp.override block in noice.lua.
  'markdown',
  'markdown_inline',
  'python',
  'query',
  'rust',
  'typescript',
  'vim',
  'vimdoc',
  'yaml',
}

-- Filetypes to start highlighting for. Not the same list as the parsers above:
-- the vimdoc parser serves the `help` filetype, bash serves `sh`, and
-- markdown_inline has no filetype of its own -- it is reached by injection
-- from the markdown parser.
local filetypes = {
  'bash',
  'c',
  'go',
  'gomod',
  'gowork',
  'help',
  'java',
  'javascript',
  'json',
  'lua',
  'markdown',
  'python',
  'query',
  'rust',
  'sh',
  'typescript',
  'vim',
  'yaml',
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    -- Upstream states the rewrite does not support lazy-loading.
    lazy = false,
    build = ':TSUpdate',
    config = function()
      -- Asynchronous, and a no-op for parsers already present.
      require('nvim-treesitter').install(parsers)

      vim.api.nvim_create_autocmd('FileType', {
        desc = 'Start treesitter highlighting',
        group = vim.api.nvim_create_augroup('custom-treesitter', { clear = true }),
        pattern = filetypes,
        callback = function()
          -- pcall: the install above is async, so on a first run the parser for
          -- this buffer may not have landed yet. Failing quietly beats an error
          -- on every buffer until the download finishes.
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
  {
    -- Was `enable = false`, which is not a lazy.nvim key -- the correct spelling
    -- is `enabled`, so this had been installing despite the intent to disable.
    -- Note the textobjects plugin has its own separate `main` rewrite, so this
    -- needs revisiting rather than just flipping back on.
    'nvim-treesitter/nvim-treesitter-textobjects',
    enabled = false,
  },
}
