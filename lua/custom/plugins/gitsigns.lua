return {
  {
    'lewis6991/gitsigns.nvim',
    -- `opts` is what makes lazy.nvim call setup(). Without it the plugin is on
    -- the runtimepath but never initialises, so there are no signs and no hunk
    -- actions -- and snacks.statuscolumn has no git state to render.
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      on_attach = function(bufnr)
        local gs = require 'gitsigns'
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- Navigation. In diff mode fall through to plain ]c/[c so the builtin
        -- behaviour still works when reviewing a merge.
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gs.nav_hunk 'next'
          end
        end, 'Next git hunk')

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gs.nav_hunk 'prev'
          end
        end, 'Previous git hunk')

        -- Under the existing <leader>g Fugitive prefix, so hunk-level actions
        -- sit next to the repo-level ones in keymaps.lua.
        map('n', '<leader>gp', gs.preview_hunk, 'Preview hunk')
        map('n', '<leader>gr', gs.reset_hunk, 'Reset hunk')
        map('v', '<leader>gr', function()
          gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') }
        end, 'Reset selected hunk')
        map('n', '<leader>gB', function()
          gs.blame_line { full = true }
        end, 'Blame line (full)')
        map('n', '<leader>gt', gs.toggle_current_line_blame, 'Toggle inline blame')
      end,
    },
  },
}
