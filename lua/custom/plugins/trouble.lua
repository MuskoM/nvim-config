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
    -- Removed: a `config` function adding a BufWinEnter autocmd that swapped
    -- every quickfix window for `:Trouble quickfix`. It fired during :PRReview
    -- too, so <leader>gR opened two Trouble views (qflist, then prhunks). The
    -- callers that want Trouble already open it themselves -- checks.lua and
    -- review.lua -- so the global hook bought nothing. Trade-off: anything
    -- else that opens the quickfix window (:copen, :grep + :cwindow) now gets
    -- the plain window; `:Trouble qflist` is one command away. Without a
    -- `config`, lazy.nvim calls setup(opts) itself.

    -- Only the diagnostic lists live here. The LSP-dependent views
    -- (<space>v* references/implementations/calls, and <space>o for the
    -- document outline) are registered buffer-locally in the LspAttach autocmd
    -- in plugins/lsp.lua, so they exist only where a server is attached. They
    -- are issued as :Trouble commands, which still triggers the `cmd` lazy-load
    -- above.
    --
    -- Diagnostics stay global: vim.diagnostic is not LSP-only -- linters and
    -- other producers populate it too -- so these are meaningful in any buffer.
    keys = {
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
        -- One key for the Trouble pane, whichever view opened it.
        --
        -- <space>d / <space>D / <space>o are `toggle`, so they dismiss what
        -- they opened. The <space>v* views (references, implementations, call
        -- hierarchy) are plain `open`, so closing one meant <C-w>j onto it and
        -- ZZ -- and <C-w>j is a guess as soon as more than one split is up.
        --
        -- No window scanning needed: trouble.nvim records the mode of the most
        -- recent view as `last_mode` and accepts the pseudo-mode "last", which
        -- api.lua resolves against it. So this stays correct with several
        -- Trouble views open -- it always acts on the most recent one.
        --
        -- focus() rather than open(): both reopen a closed view, but focus()
        -- goes through _action(), which defaults refresh = false. That matters
        -- for the LSP views -- coming back to a call hierarchy should return
        -- you to the list you were reading, not re-run the query.
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
