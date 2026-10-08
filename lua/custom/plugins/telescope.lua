-- The one picker stack. snacks.picker is disabled (plugins/snacks.lua), and
-- vim.ui.select -- code actions, kulala's env / request selectors -- goes
-- through telescope-ui-select instead.
--
-- Lazy-loaded: the stub keys below load it on first press, and config then
-- replaces them with the real mappings. Anything that require()s a telescope
-- module (java_symbols, machine-local pickers, :Noice telescope) loads it too.
-- Machine-local modules are loaded from lua/custom/lazy.lua, not here.
return {
  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      'nvim-telescope/telescope-ui-select.nvim',
    },
    keys = {
      { '<leader>sh', desc = 'Search in help' },
      { '<leader>sf', desc = 'Search in files' },
      { '<leader>s?', desc = 'Search in neovim configs' },
      { '<leader>sl', desc = 'Search last opened' },
      { '<space><space>', desc = 'Buffers' },
      { '<leader>sg', desc = 'Search text (rg)' },
      { '<leader>ss', mode = { 'n', 'x' }, desc = 'Search selected text (grep)' },
      { '<leader>sp', desc = 'Search in project (git)' },
      { '<leader>sm', desc = 'Search marks' },
      { '<leader>sr', desc = 'Resume last search' },
      { '<leader>sw', desc = 'Search symbols - project sources (LSP)' },
      { '<leader>sW', desc = 'Search symbols - incl. jars (LSP)' },
    },
    init = function()
      -- vim.ui.select can be called before anything has loaded telescope.
      -- This stub loads it; load_extension('ui-select') in config then
      -- replaces vim.ui.select, so the call below reaches telescope.
      vim.ui.select = function(...)
        require('lazy').load { plugins = { 'telescope.nvim' } }
        return vim.ui.select(...)
      end
    end,
    config = function()
      local builtin = require 'telescope.builtin'
      local set = vim.keymap.set

      require 'telescope'.setup {
        defaults = {
          path_display = {
            filename_first = { reverse_directories = true },
          }
        },
        pickers = {
          find_files = { theme = 'ivy' },
          buffers = { theme = 'ivy' },
          live_grep = { theme = 'ivy' },
          grep_string = { theme = 'ivy' },
          git_files = { theme = 'ivy' },
          marks = { theme = 'ivy' },
        },
        extensions = {
          fzf = {},
          -- Small list at the cursor: code actions are a short menu.
          ['ui-select'] = { require('telescope.themes').get_cursor() },
        }
      }

      require('telescope').load_extension('fzf')
      require('telescope').load_extension('ui-select')

      -- Owns <leader>sw and <leader>sW -- see that file for why symbol search
      -- is split into a sources-only and an include-jars variant.
      require('custom.telescope.java_symbols').setup()

      set('n', '<leader>sh', builtin.help_tags, { desc = 'Search in help' })
      set('n', '<leader>sf', builtin.find_files, { desc = 'Search in files' })
      set('n', '<leader>s?', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = 'Search in neovim configs' })
      set('n', '<leader>sl', builtin.oldfiles, { desc = 'Search last opened' })
      set('n', '<space><space>', builtin.buffers, { desc = 'Buffers' })
      set('n', '<leader>sg', builtin.live_grep, { desc = 'Search text (rg)' })
      set({ 'n', 'x' }, '<leader>ss', builtin.grep_string, { desc = 'Search selected text (grep)' })
      set('n', '<leader>sp', builtin.git_files, { desc = 'Search in project (git)' })
      -- Marks already set, across files. Pinning files to jump between is
      -- harpoon's job (plugins/harpoon.lua); this is for finding marks.
      set('n', '<leader>sm', builtin.marks, { desc = 'Search marks' })
      -- Reopen the last picker with its prompt and selection intact.
      set('n', '<leader>sr', builtin.resume, { desc = 'Resume last search' })

      local ok, wk = pcall(require, 'which-key')
      if ok then
        wk.add({
          { '<leader>sh', desc = 'Search in help', icon = '󰋖' },
          { '<leader>sf', desc = 'Search in files', icon = { icon = "", color = 'purple' } },
          { '<leader>s?', desc = 'Search in neovim configs', icon = { icon = '', color = 'red' } },
          { '<leader>sl', desc = 'Search last opened', icon = { icon = '', color = 'purple' }, },
          { '<space><space>', desc = 'Buffers', icon = { icon = '' } },
          { '<leader>sg', desc = 'Search text (rg)', icon = '󰦨' },
          { '<leader>ss', desc = 'Search selected text (grep)', icon = '󰦨' },
          { '<leader>sp', desc = 'Search in project (git)' },
          { '<leader>sm', desc = 'Search marks' },
          { '<leader>sr', desc = 'Resume last search' },
        })
      end
    end
  }
}
