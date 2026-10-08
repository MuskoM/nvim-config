-- In-buffer markdown rendering (headings, bullets, checkboxes, code blocks,
-- tables, callouts) via extmarks and conceal over the real text. Not a
-- preview: the buffer stays editable and the cursor line un-renders to raw
-- markdown (anti_conceal).
--
-- Chosen over markview.nvim (more features, larger surface, breaking
-- rewrites) and headlines.nvim (backgrounds only, no icons or tables).
--
-- Nothing here writes to the buffer. Formatting is conform's: markdown goes
-- through prettier, on save only when the project has a prettier config.

return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    -- `ft` lazy-loading is upstream-supported. If the first markdown file of
    -- a session renders unhighlighted, set `restart_highlighter = true`.
    ft = { 'markdown' },
    dependencies = {
      -- Needs the markdown + markdown_inline parsers, which
      -- plugins/treesitter.lua already installs for noice's hover windows.
      'nvim-treesitter/nvim-treesitter',
      -- Language icon above fenced code blocks. Spelling must match
      -- plugins/oil.lua (see the note there).
      'nvim-mini/mini.icons',
    },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    -- file_types stays at its default: noice hover buffers have no markdown
    -- filetype (noice highlights markdown as a range), so there is nothing to add.
    -- Conceal is set per window by the plugin, so options.lua stays out of it.
    opts = {},

    -- No keymap; `:RenderMarkdown buf_toggle` shows raw text. (<space>m is
    -- taken buffer-locally by helpers.lua if one is ever added.)
  },
}
