return {
  'mbbill/undotree',
  -- `keys` rather than a keymap inside `config`: lazy registers a stub and only
  -- loads the plugin on first press, instead of at startup.
  cmd = 'UndotreeToggle',
  keys = {
    { '<leader>u', vim.cmd.UndotreeToggle, desc = 'Undotree' },
  },
}
