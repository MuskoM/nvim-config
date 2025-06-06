return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    opts = {
      ensure_installed = { 'lua', 'python', 'javascript', 'markdown', 'json', 'yaml' },
      sync_install = false,
      auto_install = true
    },
    config = function()
      require 'nvim-treesitter.configs'.setup({
        -- A list of parser names, or "all" (the listed parsers MUST always be installed)
        ensure_installed = { "c", "lua", "vim", "json", "yaml", "vimdoc", "query", "markdown", "markdown_inline", 'javascript', 'typescript', 'python', 'rust' },
        sync_install = false,
        auto_install = true,
        ignore_install = {},
        highlight = {
          enable = true,

          disable = function(_, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
          additional_vim_regex_highlighting = false,
        },
      })
    end
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = { 'nvim-treesitter/nvim-treesitter' }
  }
}
