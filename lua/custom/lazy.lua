local lazypath = vim.fn.stdpath 'data' .. 'lazy/lazy.nvim'

if not (vim.uv or vim.loop).fs_stat(lazypath) then
        local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
        local out = vim.fn.system({'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath})
        if vim.v.shell_error ~= 0 then
                vim.api.nvim_echo({
                        {'Failed to clone lazy.nvim:\n', 'ErrorMsg'},
                        {out, 'WarningMsg'},
                        {'\nPress any key to exit...'},
                }, true, {})
                vim.fn.getchar()
                os.exit()
        end
end

-- Hey! put the lazy into rtp or runtimepath
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
    spec = {
        {'folke/tokyonight.nvim', config = function() vim.cmd.colorscheme 'tokyonight' end},
        {import = 'custom.plugins'}
    }
})
