-- This is an Advent of Neovim adventure
--[[
    Here we will do all stufs in lua
--]] 

print('Welcome to the Advent')

vim.g.mapleader = ','

require('custom.lazy')

vim.keymap.set('n', '<space><space>x', '<cmd>source %<CR>')
vim.keymap.set('n', '<space>x', ':.lua<CR>')
vim.keymap.set('v', '<space>x', ':.lua<CR>')

vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking text',
    group = vim.api.nvim_create_augroup('advent-highlight-yank', {clear = true}),
    callback = function()
        vim.highlight.on_yank {timeout = 300}
    end
})

vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.et = true

