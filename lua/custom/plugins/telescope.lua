return {
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
    },
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
          fzf = {}
        }
      }

      -- Load extension
      require('telescope').load_extension('fzf')

      -- Owns <leader>sw and <leader>sW -- see that file for why symbol search
      -- is split into a sources-only and an include-jars variant.
      require('custom.telescope.java_symbols').setup()

      -- Machine-local pickers: every lua/custom/local/*.lua exposing setup().
      -- That directory is gitignored, so pickers wrapping internal or private
      -- tooling stay on disk and out of the published config. Loaded here
      -- rather than from init.lua so telescope is guaranteed to be set up.
      local localdir = vim.fn.stdpath('config') .. '/lua/custom/local'
      for _, path in ipairs(vim.fn.glob(localdir .. '/*.lua', true, true)) do
        local name = vim.fn.fnamemodify(path, ':t:r')
        local ok, mod = pcall(require, 'custom.local.' .. name)
        if ok and type(mod) == 'table' and type(mod.setup) == 'function' then
          local setup_ok, err = pcall(mod.setup)
          if not setup_ok then
            vim.notify(('local picker %s failed: %s'):format(name, err), vim.log.levels.WARN)
          end
        end
      end

      -- Set some keymaps
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
      -- <leader>sw / <leader>sW (symbol search) live in
      -- custom/telescope/java_symbols.lua, set up above.

      local wk = require('which-key')
      wk.add({
        { '<leader>sh', desc = 'Search in help', icon = '󰋖' },
        { '<leader>sf', desc = 'Search in files', icon = { icon = "", color = 'purple' } },
        { '<leader>s?', desc = 'Search in neovim configs', icon = { icon = '', color = 'red' } },
        { '<leader>sl', desc = 'Search last opened', icon = { icon = '', color = 'purple' }, },
        { '<space><space>', desc = 'Buffers', icon = { icon = '' } },
        { '<leader>sg', desc = 'Search text (rg)', icon = '󰦨' },
        { '<leader>ss', desc = 'Search selected text (grep)', icon = '󰦨' },
        { '<leader>sp', desc = 'Search in project (git)' },
        { '<leader>sm', desc = 'Search marks' },
        { '<leader>sr', desc = 'Resume last search' },
      })
    end
  }
}
