return {
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    -- 'nvim-mini/mini.icons', not the older 'echasnovski/mini.icons': upstream
    -- renamed the org, and while GitHub redirects the old URL, lazy keys plugins
    -- by name -- two URLs for one 'mini.icons' directory is a conflict. Kept in
    -- sync with the dependency in plugins/render-markdown.lua.
    dependencies = { { 'nvim-mini/mini.icons', opts = {} } },
    -- Stays eager: oil replaces netrw, so it has to be loaded before the first
    -- buffer in case nvim is opened on a directory (`nvim .`). The keymap below
    -- is declared here rather than in config so which-key picks up the desc.
    lazy = false,
    keys = {
      { '<leader>f', '<cmd>Oil<CR>', desc = 'File manager (oil)' },
    },
    opts = {
      view_options = {
        show_hidden = true,
        is_always_hidden = function(name, _)
          return name == '.' or name == '..'
        end,
      },
      -- oil's defaults put split, refresh and preview on <C-h>, <C-l> and
      -- <C-p>, which shadowed pane navigation (keymaps.lua) and harpoon's
      -- previous-file in every oil buffer. Moved, not dropped:
      --   <C-x>  horizontal split -- telescope's key for the same thing, and
      --          the pair to oil's own <C-s> vertical split
      --   gR     refresh -- not `gr`, which would wait on the built-in gr* LSP
      --          maps' timeout
      --   gp     preview
      keymaps = {
        ['<C-h>'] = false,
        ['<C-l>'] = false,
        ['<C-p>'] = false,
        ['<C-x>'] = { 'actions.select', opts = { horizontal = true } },
        ['gR'] = 'actions.refresh',
        ['gp'] = 'actions.preview',
      },
    },
  },
}
