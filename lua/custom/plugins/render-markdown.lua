-- In-buffer markdown rendering: heading backgrounds, bullet and checkbox
-- icons, code block borders, table alignment, callouts -- drawn with extmarks
-- and conceal over the real text.
--
-- Not a preview. The buffer stays editable, and the line under the cursor
-- un-renders back to raw markdown (anti_conceal, on by default), so editing
-- happens on what is actually in the file rather than on a rendering of it.
--
-- Chosen over markview.nvim (does more -- latex, html, typst -- at the cost of
-- a much larger surface and a history of breaking rewrites) and
-- headlines.nvim (heading and code block backgrounds only, no icons or
-- tables). Both remain reasonable; this one is the smallest thing that covers
-- reading long markdown comfortably.
--
-- Nothing here writes to the buffer, so the conform "no project config, no
-- format on save" rule in plugins/conform.lua is untouched -- markdown is
-- still not in formatters_by_ft, and rendering does not change that.

return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    -- Upstream documents lazy.nvim `ft` as a supported way to load this, and
    -- nothing it provides means anything outside a markdown buffer. If
    -- headings ever render unhighlighted on the first markdown file of a
    -- session, the knob for that is `restart_highlighter = true` -- it exists
    -- precisely for the lazy-loaded case, where treesitter highlighting has
    -- already attached by the time this plugin does.
    ft = { 'markdown' },
    dependencies = {
      -- Needs the markdown + markdown_inline parsers, which
      -- plugins/treesitter.lua already installs for noice's hover windows.
      'nvim-treesitter/nvim-treesitter',
      -- Language icon above fenced code blocks. Must stay spelled the same
      -- way as the dependency in plugins/oil.lua: lazy keys plugins by name,
      -- so 'nvim-mini/mini.icons' here and 'echasnovski/mini.icons' there
      -- would be two URLs claiming one 'mini.icons' directory.
      'nvim-mini/mini.icons',
    },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    -- file_types is left at its default of { 'markdown' }. Adding noice's
    -- hover buffers was tried and does not work, and the reason is structural
    -- rather than a missing name: noice never gives those buffers a markdown
    -- filetype. Its `hover` view sets no `lang` and no buf_options.filetype,
    -- and NoiceText:highlight applies markdown as a *range* highlighter over
    -- part of the buffer (noice/text/init.lua) instead of attaching a parser
    -- to the buffer. render-markdown attaches per buffer and wants a
    -- buffer-level markdown tree, so there is no filetype to list -- naming
    -- 'noice' would only make it attach to a buffer it cannot parse.
    --
    -- Otherwise defaults, on purpose. The plugin sets 'conceallevel' and
    -- 'concealcursor' per window as it renders and restores them after, so
    -- options.lua stays out of it and no other filetype inherits a conceal
    -- setting it did not ask for.
    opts = {},

    -- No keymap. `:RenderMarkdown buf_toggle` drops back to raw text when you
    -- need to copy a line verbatim, and `:RenderMarkdown preview` opens a
    -- rendered copy to the side; neither has earned a key yet. If one does,
    -- note that <space>m is not free in practice -- helpers.lua binds
    -- <localleader>m buffer-locally for RouterOS deploy, and localleader is
    -- <space>, so a global <space>m would silently vanish in those buffers.
  },
}
