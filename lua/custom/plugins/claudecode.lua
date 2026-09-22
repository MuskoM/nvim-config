-- Claude Code inside Neovim: WebSocket bridge (diffs, file opening,
-- diagnostics, selection/context sending) plus a terminal the plugin owns.
--
-- Provider is snacks, as a FLOAT rather than a split: splits here are for
-- editing several files side by side, so Claude overlays the layout instead of
-- resizing it. snacks.nvim is already loaded eagerly (plugins/snacks.lua).
--
-- Trade-off of an in-editor terminal: the claude process dies with nvim. The
-- conversation does not -- Claude Code stores transcripts on disk, so
-- <leader>ar (--resume) / <leader>aC (--continue) bring it back.
--
-- Keymaps live under <leader>a ("AI"), global by scope: Claude reaches outside
-- the current buffer. <space>a* is the buffer-local LSP rename/code-action
-- prefix; the two do not overlap (different leader keys).
return {
  {
    'coder/claudecode.nvim',
    dependencies = { 'folke/snacks.nvim' },
    -- Group label registered here, not in whichkey.lua, so it goes away with
    -- the plugin (same convention as kulala's <leader>R). VeryLazy because
    -- which-key itself loads then.
    init = function()
      vim.api.nvim_create_autocmd('User', {
        pattern = 'VeryLazy',
        once = true,
        callback = function()
          require('which-key').add({ { '<leader>a', group = 'AI / Claude' } })
        end,
      })
    end,
    cmd = {
      'ClaudeCode', 'ClaudeCodeFocus', 'ClaudeCodeSelectModel',
      'ClaudeCodeAdd', 'ClaudeCodeSend', 'ClaudeCodeSendText',
      'ClaudeCodeTreeAdd', 'ClaudeCodeStatus',
      'ClaudeCodeDiffAccept', 'ClaudeCodeDiffDeny', 'ClaudeCodeCloseAllDiffs',
    },
    keys = {
      -- Focus rather than plain toggle: it opens Claude when hidden and
      -- focuses it when visible but unfocused, which is what a float wants.
      { '<leader>aa', '<cmd>ClaudeCodeFocus<cr>',           desc = 'Claude (open / focus)' },
      -- One-press in/out from anywhere. Out again is the buffer-local <C-f>
      -- in snacks_win_opts.keys below (terminal mode), so the same key flips
      -- between editor and Claude. Shadows normal-mode <C-f> (page down;
      -- <C-d> still scrolls) and insert-mode <C-f> (reindent, rarely used).
      { '<C-f>', '<cmd>ClaudeCodeFocus<cr>', mode = { 'n', 'i', 'x' }, desc = 'Claude (open / focus)' },
      { '<leader>ar', '<cmd>ClaudeCode --resume<cr>',       desc = 'Resume session' },
      { '<leader>aC', '<cmd>ClaudeCode --continue<cr>',     desc = 'Continue last session' },
      { '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>',     desc = 'Select model' },
      { '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>',           desc = 'Add current buffer' },
      { '<leader>as', '<cmd>ClaudeCodeSend<cr>',            mode = 'v', desc = 'Send selection to Claude' },
      {
        -- Same keys as the visual mapping above, but in file-tree buffers
        -- (oil is the one used here) it adds the file under the cursor.
        '<leader>as', '<cmd>ClaudeCodeTreeAdd<cr>',
        ft = { 'oil', 'netrw', 'snacks_picker_list' },
        desc = 'Add file to Claude',
      },
      { '<leader>ac', '<cmd>ClaudeCodeDiffAccept<cr>',      desc = 'Confirm (accept) diff' },
      { '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>',        desc = 'Deny diff' },
    },
    opts = {
      -- Jump into the Claude window after sending a selection / file, so the
      -- next thing typed is the prompt. Only works with in-editor providers.
      focus_after_send = true,

      -- Set to the output of `which claude` if nvim ever can't find the
      -- binary (GUI-launched nvim on macOS has a thinner PATH).
      -- terminal_cmd = '~/.local/bin/claude',

      terminal = {
        provider = 'snacks',
        auto_close = true,
        snacks_win_opts = {
          position = 'float',
          width = 0.7,
          height = 0.7,
          border = 'rounded',
          keys = {
            -- snacks' default double-<Esc> "go to normal mode" would eat the
            -- double-Esc that Claude Code itself uses (rewind / clear input).
            -- <C-\><C-n> still leaves terminal mode.
            term_normal = false,
            -- Hide (not kill) from inside the terminal, on the same key that
            -- opens it from the editor. Buffer-local, so it wins over the
            -- global <C-f> mapping above; it also means <C-f> never reaches
            -- Claude Code itself.
            claude_hide = {
              '<C-f>',
              function(self) self:hide() end,
              mode = 't',
              desc = 'Hide Claude',
            },
          },
        },
      },

      -- Diffs get their own tab with the terminal hidden, so they are never
      -- underneath the float. Accept with :w / <leader>ac, reject with :q /
      -- <leader>ad.
      diff_opts = {
        layout = 'vertical',
        open_in_new_tab = true,
        hide_terminal_in_new_tab = true,
      },
    },
  },
}
