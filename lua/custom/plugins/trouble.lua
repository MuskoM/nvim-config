return {
  {
    'folke/trouble.nvim',
    cmd = "Trouble",
    opts = {
      auto_close = true,
      formatters = {
        -- Per-severity tally for a group row: `E3 W12 I1`, each in its
        -- diagnostic colour, zero counts omitted. Replaces the built-in
        -- {count}, a single total that cannot tell 200 warnings from 200
        -- errors -- which is the first thing you want to know about a folded
        -- directory. ctx.node is the group node; flatten() yields every leaf
        -- item under it, nested directories included.
        severity_counts = function(ctx)
          local n = {}
          for _, item in ipairs(ctx.node:flatten()) do
            local s = item.severity or vim.diagnostic.severity.ERROR
            n[s] = (n[s] or 0) + 1
          end
          local ret = {}
          for s, label in ipairs({ 'E', 'W', 'I', 'H' }) do
            if n[s] then
              local name = vim.diagnostic.severity[s]:lower():gsub('^%l', string.upper)
              ret[#ret + 1] = { text = ' ' .. label .. n[s], hl = 'Diagnostic' .. name }
            end
          end
          return ret
        end,
      },
      modes = {
        -- Same groups as trouble's built-in diagnostics mode (directory, then
        -- file), only the trailing {count} swapped for {severity_counts}.
        -- Merged by list index into the defaults, so the order must match.
        -- Applies to <space>d too: it is this mode plus a buffer filter.
        diagnostics = {
          groups = {
            { 'directory', format = '{directory_icon} {directory}{severity_counts}' },
            { 'filename', format = '{file_icon} {basename}{severity_counts}' },
          },
        },
      },
    },
    -- (Removed the BufWinEnter autocmd swapping every quickfix window for
    -- Trouble: it doubled views under :PRReview; callers open Trouble themselves.)

    -- LSP views (<space>v*, <space>o) are buffer-local in plugins/lsp.lua.
    -- Diagnostics stay global: vim.diagnostic is not LSP-only.
    keys = {
      {
        -- The quickfix list (check runs, greps, gitsigns' <leader>gq, :Gclog)
        -- next to the two diagnostics views. Replaces the old
        -- vim.diagnostic.setloclist mapping, which showed <space>d's content
        -- in a worse viewer.
        '<space>q',
        '<cmd>Trouble qflist toggle<cr>',
        desc = '[Q]uickfix list',
      },
      {
        '<space>D',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = 'All [D]iagnostics',
      },
      {
        '<space>d',
        '<cmd>Trouble diagnostics toggle filter.buf=0 focus=false<cr>',
        desc = 'Local [d]iagnostics',
      },
      {
        -- One key for the Trouble pane, whichever view opened it: acts on
        -- trouble's `last` mode, so it is always the most recent view. focus()
        -- rather than open() so a reopened LSP view is not re-queried
        -- (focus defaults refresh = false).
        '<space>t',
        function()
          local trouble = require('trouble')
          if vim.bo.filetype == 'trouble' then
            trouble.close('last')
          elseif trouble.last_mode then
            trouble.focus('last')
          else
            -- last_mode is nil until something opens a view, and focus() would
            -- answer that with trouble's own "No mode specified" error.
            vim.notify('No Trouble view opened yet', vim.log.levels.WARN)
          end
        end,
        desc = '[T]rouble: focus / close last view',
      },
    },
  },
}
