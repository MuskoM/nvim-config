local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out,                            'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit()
  end
end

-- Hey! put the lazy into rtp or runtimepath
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  spec = {
    {
      "catppuccin/nvim",
      name = "catppuccin",
      priority = 1000,
      config = function()
        local color_scheme = 'catppuccin-frappe'
        vim.cmd.colorscheme(color_scheme)
      end
    },
    { import = 'custom.plugins' }
  }
})

-- Machine-local modules: every lua/custom/local/*.lua exposing setup().
-- That directory is gitignored, so helpers wrapping internal or private
-- tooling stay on disk and out of the published config. VeryLazy so startup
-- does not wait on them; a module that requires telescope loads it then.
vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  once = true,
  callback = function()
    local localdir = vim.fn.stdpath('config') .. '/lua/custom/local'
    for _, path in ipairs(vim.fn.glob(localdir .. '/*.lua', true, true)) do
      local name = vim.fn.fnamemodify(path, ':t:r')
      local ok, mod = pcall(require, 'custom.local.' .. name)
      if ok and type(mod) == 'table' and type(mod.setup) == 'function' then
        local setup_ok, err = pcall(mod.setup)
        if not setup_ok then
          vim.notify(('local module %s failed: %s'):format(name, err), vim.log.levels.WARN)
        end
      end
    end
  end,
})
