return { {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  keys = {
    -- snacks.words highlights every reference to the word under the cursor;
    -- these jump between them. Shadows the built-in ]] / [[ section motions,
    -- which only mean something for C-style `{` in column 0.
    { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'Next reference' },
    { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'Previous reference' },
    -- Open the file (or the visual line range) on the git host.
    { '<leader>go', function() Snacks.gitbrowse() end, mode = { 'n', 'x' }, desc = 'Open in browser' },
  },
  init = function()
    -- Renaming a file in oil sends the LSP willRenameFiles request, so jdtls
    -- and ts_ls update imports and Java package declarations to match.
    vim.api.nvim_create_autocmd('User', {
      pattern = 'OilActionsPost',
      callback = function(event)
        local action = event.data.actions[1]
        if action and action.type == 'move' then
          Snacks.rename.on_rename_file(action.src_url, action.dest_url)
        end
      end,
    })
  end,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = { enabled = false },
    indent = { enabled = false, animate = { duration = { step = 15 } } },
    input = { enabled = true },
    picker = { enabled = true },
    notifier = { enabled = false },
    quickfile = { enabled = true },
    scope = { enabled = false },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
  },
} }
