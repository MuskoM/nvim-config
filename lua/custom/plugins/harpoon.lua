-- Harpoon (v2): a short, ordered list of pinned files per project, one key
-- per slot.
--
-- Why not plain marks: lowercase marks are per-file, so they cannot jump
-- between files. Uppercase marks can, but there are 26 of them shared across
-- every project, they remember a line rather than "the file", and setting one
-- silently overwrites what was there. Harpoon solves the "the 3-5 files I am
-- working in" case (controller / service / repository / test), and the
-- Telescope marks picker (<leader>sm, plugins/telescope.lua) handles finding
-- marks that are already set.
--
-- The list is keyed by cwd (harpoon's default), so each project keeps its own
-- pins. Trade-off: opening nvim from a subdirectory of a repo gives you a
-- different list than opening it from the root.
--
-- Keys are global by scope -- they jump to other files -- so <leader>, not
-- <space>:
--   <leader>ha       pin the current file
--   <leader>hh       menu. It is an ordinary buffer: reorder lines to reorder
--                    slots, `dd` to unpin, then :w or close it.
--   <leader>1..4     jump to slot. Top-level rather than <leader>h1 because
--                    speed is the whole point of the plugin.
--   <C-n> / <C-p>    cycle next / previous pinned file, wrapping at the ends.
--                    Normal mode only. In normal mode these are just
--                    duplicates of j / k, so nothing is lost; insert-mode
--                    <C-n>/<C-p> (cmp) are untouched. <C-h>/<C-H> were the
--                    first idea, but <C-h> is move-to-left-split
--                    (keymaps.lua), and terminals send <C-H> as the same
--                    byte as <C-h>, so it cannot be a separate key.
return {
  {
    'ThePrimeagen/harpoon',
    -- v2 lives on this branch. master is the unmaintained v1, which has a
    -- different API (require('harpoon.mark')), so do not drop this line.
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    -- Group label registered here, not in whichkey.lua, so it goes away with
    -- the plugin (same convention as kulala and claudecode).
    init = function()
      vim.api.nvim_create_autocmd('User', {
        pattern = 'VeryLazy',
        once = true,
        callback = function()
          local ok, wk = pcall(require, 'which-key')
          if ok then
            wk.add { { '<leader>h', group = 'Harpoon' } }
          end
        end,
      })
    end,
    config = function()
      require('harpoon'):setup {
        settings = {
          -- Edits made in the menu are kept when it is closed without :w.
          save_on_toggle = true,
        },
      }

      -- The menu is a normal-mode buffer, so the global <C-n>/<C-p> below
      -- fired inside it: instead of moving through the list, it jumped to
      -- another file from under the open menu. Buffer-local maps win over
      -- global ones, so give them back their list-navigation meaning there.
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'harpoon',
        group = vim.api.nvim_create_augroup('custom-harpoon-menu', { clear = true }),
        callback = function(args)
          vim.keymap.set('n', '<C-n>', 'j', { buffer = args.buf, desc = 'Next entry' })
          vim.keymap.set('n', '<C-p>', 'k', { buffer = args.buf, desc = 'Previous entry' })
        end,
      })
    end,
    keys = {
      { '<leader>ha', function() require('harpoon'):list():add() end, desc = 'Harpoon: pin file' },
      {
        '<leader>hh',
        function()
          local harpoon = require('harpoon')
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = 'Harpoon: menu',
      },
      { '<leader>1', function() require('harpoon'):list():select(1) end, desc = 'Harpoon: file 1' },
      { '<leader>2', function() require('harpoon'):list():select(2) end, desc = 'Harpoon: file 2' },
      { '<leader>3', function() require('harpoon'):list():select(3) end, desc = 'Harpoon: file 3' },
      { '<leader>4', function() require('harpoon'):list():select(4) end, desc = 'Harpoon: file 4' },
      {
        '<C-n>',
        function() require('harpoon'):list():next { ui_nav_wrap = true } end,
        desc = 'Harpoon: next file',
      },
      {
        '<C-p>',
        function() require('harpoon'):list():prev { ui_nav_wrap = true } end,
        desc = 'Harpoon: previous file',
      },
    },
  },
}
