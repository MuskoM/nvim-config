-- LuaSnip: the snippet engine nvim-cmp expands LSP snippets with
-- (plugins/cmp.lua), plus a short hand-picked set in snippets/<filetype>.lua.
--
-- The hand-written set is deliberately small: only things the language
-- servers do not already offer as snippet completions. jdtls, ts_ls and
-- rust_analyzer cover loops, conditionals and class bodies on their own.
return {
  {
    'L3MON4D3/LuaSnip',
    config = function()
      local ls = require('luasnip')

      require('luasnip.loaders.from_lua').lazy_load {
        paths = { vim.fn.stdpath('config') .. '/snippets' },
      }
      -- One javascript.lua serves all four web filetypes.
      for _, ft in ipairs { 'typescript', 'javascriptreact', 'typescriptreact' } do
        ls.filetype_extend(ft, { 'javascript' })
      end

      -- Jump between placeholders, in snippets from this directory and in
      -- the ones LSP completion expands (method calls with arguments, etc.).
      -- Insert and select mode: a placeholder is a select-mode selection.
      --
      -- <C-l> forward, <C-h> back. Both fall through to their normal meaning
      -- when there is nowhere to jump -- <C-h> is backspace in insert mode.
      local function jump_or_feed(direction, key)
        return function()
          if ls.jumpable(direction) then
            ls.jump(direction)
          else
            vim.api.nvim_feedkeys(vim.keycode(key), 'n', false)
          end
        end
      end
      vim.keymap.set({ 'i', 's' }, '<C-l>', jump_or_feed(1, '<C-l>'), { desc = 'Snippet: next placeholder' })
      vim.keymap.set({ 'i', 's' }, '<C-h>', jump_or_feed(-1, '<C-h>'), { desc = 'Snippet: previous placeholder' })
    end,
  },
}
