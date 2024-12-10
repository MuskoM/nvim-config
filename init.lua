-- This is an Advent of Neovim adventure
--[[
Here we will do all stufs in lua
--]]

print('Welcome to the Advent')

vim.g.mapleader = ','
vim.g.maplocalleader = '\\'

require 'custom.options'
require 'custom.keymaps'
require 'custom.autocmds'
require 'custom.lazy'
