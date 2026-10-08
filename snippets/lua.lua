-- Loaded by plugins/luasnip.lua.
local ls = require('luasnip')
local s, i, f = ls.snippet, ls.insert_node, ls.function_node
local fmt = require('luasnip.extras.fmt').fmt

return {
  -- `local telescope = require('telescope')`: the local is named after the
  -- last segment of the module path as you type it.
  s('req', fmt("local {} = require('{}')", {
    f(function(args)
      local last = (args[1][1] or ''):match('([%w_-]+)$') or 'mod'
      local name = last:gsub('-', '_')
      return name
    end, { 1 }),
    i(1),
  })),

  -- Module skeleton.
  s('mod', fmt([[
local M = {{}}

{}

return M
]], { i(0) })),
}
