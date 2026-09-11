-- This is an Advent of Neovim adventure
--[[
Here we will do all stufs in lua
--]]
vim.g.mapleader = ','
-- <localleader> is <space>, the same prefix as the buffer-scoped mappings, on
-- purpose: <space> means "this buffer", and localleader exists for mappings
-- that only apply to some buffers -- the same idea at two scopes rather than
-- two ideas needing two keys. Full scheme in lua/custom/keymaps.lua.
vim.g.maplocalleader = ' '

require 'custom.options'
require 'custom.keymaps'
require 'custom.autocmds'
require 'custom.lazy'
require 'custom.helpers'
