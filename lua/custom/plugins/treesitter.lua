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
    -- Syntax-aware text objects and motions, on the `main` rewrite (the old
    -- `master` config API does not exist here: setup() takes options only,
    -- and every mapping is set by hand below). Uses the parsers above.
    --
    --   af / if   function     ac / ic   class     aa / ia   parameter
    --   ]m / [m   next / previous function start, ]M / [M   function end
    --   <space>> / <space><   swap parameter with the next / previous one
    --
    -- No class motions: ]] / [[ are snacks.words reference jumps.
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    init = function()
      -- Built-in ftplugins (python, rust, ...) map ]] [[ ]m [m buffer-locally,
      -- which would shadow both the motions below and snacks.words' ]] / [[.
      vim.g.no_plugin_maps = true
    end,
    opts = {
      select = {
        -- `daf` from anywhere before the function, like targets.vim.
        lookahead = true,
        selection_modes = {
          ['@function.outer'] = 'V',
          ['@class.outer'] = 'V',
        },
      },
      move = { set_jumps = true },
    },
    config = function(_, opts)
      require('nvim-treesitter-textobjects').setup(opts)
    end,
    keys = function()
      local function sel(query)
        return function()
          require('nvim-treesitter-textobjects.select').select_textobject(query, 'textobjects')
        end
      end
      local function move(fn, query)
        return function()
          require('nvim-treesitter-textobjects.move')[fn](query, 'textobjects')
        end
      end
      local xo, nxo = { 'x', 'o' }, { 'n', 'x', 'o' }
      return {
        { 'af', sel('@function.outer'), mode = xo, desc = 'Function' },
        { 'if', sel('@function.inner'), mode = xo, desc = 'Function body' },
        { 'ac', sel('@class.outer'), mode = xo, desc = 'Class' },
        { 'ic', sel('@class.inner'), mode = xo, desc = 'Class body' },
        { 'aa', sel('@parameter.outer'), mode = xo, desc = 'Parameter (with comma)' },
        { 'ia', sel('@parameter.inner'), mode = xo, desc = 'Parameter' },
        { ']m', move('goto_next_start', '@function.outer'), mode = nxo, desc = 'Next function start' },
        { '[m', move('goto_previous_start', '@function.outer'), mode = nxo, desc = 'Previous function start' },
        { ']M', move('goto_next_end', '@function.outer'), mode = nxo, desc = 'Next function end' },
        { '[M', move('goto_previous_end', '@function.outer'), mode = nxo, desc = 'Previous function end' },
        {
          '<space>>',
          function() require('nvim-treesitter-textobjects.swap').swap_next('@parameter.inner') end,
          desc = 'Swap parameter with next',
        },
        {
          '<space><',
          function() require('nvim-treesitter-textobjects.swap').swap_previous('@parameter.inner') end,
          desc = 'Swap parameter with previous',
        },
      }
    end,
  },
}
