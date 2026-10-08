-- HTTP client for .http request files kept alongside a project's sources.
--
-- Those files are IntelliJ HTTP Client format -- `{{base_url}}` style
-- placeholders resolved from a http-client.env.json next to them. kulala reads
-- that format directly, so the files and env files work untouched and stay
-- shared with anyone running them from IntelliJ.
--
-- Upstream moved (2026-09): the mistweaverco repository was deleted and the
-- project came back, by the same author, as dont-be-evil-company/kulala.nvim.
return {
  {
    'dont-be-evil-company/kulala.nvim',
    -- Loaded on .http files, plus stub keys so <leader>R* works before the
    -- first http buffer is opened. Leader is ',' here, so the prefix is ',R'.
    ft = { 'http', 'rest' },
    keys = {
      { '<leader>Rs', desc = 'Send request' },
      { '<leader>Ra', desc = 'Send all requests' },
      { '<leader>Re', desc = 'Select environment' },
      { '<leader>Rb', desc = 'Open scratchpad' },
    },
    opts = {
      -- Which block of http-client.env.json to use when a buffer has no
      -- explicit selection. Change to whatever the project names its envs
      -- ("local", "stage", ...) -- ,Re switches at runtime.
      default_env = 'default',
      -- Per-buffer rather than global: you can have a local-env request and a
      -- stage-env request open at the same time without them fighting.
      environment_scope = 'b',

      -- kulala ships its own kulala-http parser and queries, built with
      -- tree-sitter-cli. Deliberately NOT adding 'http' to the parser list in
      -- plugins/treesitter.lua -- two parsers claiming the same filetype means
      -- whichever attaches last wins and highlighting flickers.
      treesitter = { enable = true },

      ui = {
        display_mode = 'split',
        split_direction = 'right',
        -- Bodies matter more than headers day to day, but the winbar keeps
        -- headers one key away.
        default_view = 'body',
        winbar = true,
        show_icons = 'on_request',
        show_request_summary = true,
        -- Reuse snacks for the env / request pickers -- snacks.picker is
        -- already enabled in snacks.lua.
        pickers = {
          snacks = {
            layout = function()
              local ok, picker = pcall(require, 'snacks.picker')
              return ok and picker.config.layout('telescope') or {}
            end,
          },
        },
      },

      -- Built-in completion for header names, variables and request names.
      -- enforce_external_script_naming_convention keeps it off ordinary .js /
      -- .lua buffers -- it only attaches to *.http.js / *.http.lua.
      lsp = {
        enable = true,
        filetypes = { 'http', 'rest' },
        enforce_external_script_naming_convention = true,
      },

      -- Full documented keymap set under the ',R' prefix, owned by the plugin
      -- so it survives upstream renames of the public methods.
      global_keymaps = true,
      global_keymaps_prefix = '<leader>R',
      -- The response pane's defaults, except tab switching: kulala puts it on
      -- <C-h>/<C-l>, which trapped you in the split (pane navigation,
      -- keymaps.lua). A table is merged over the defaults by entry name.
      kulala_keymaps = {
        ['Previous tab'] = { '<S-Tab>', function() require('kulala.ui').show_previous_tab() end, mode = { 'n' } },
        ['Next tab'] = { '<Tab>', function() require('kulala.ui').show_next_tab() end, mode = { 'n' } },
      },

      debug = false,
    },
    config = function(_, opts)
      require('kulala').setup(opts)

      local ok, wk = pcall(require, 'which-key')
      if ok then
        wk.add { { '<leader>R', group = 'REST (kulala)', icon = '' } }
      end
    end,
  },
}
