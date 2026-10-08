-- Loaded by plugins/luasnip.lua, and extended to typescript, javascriptreact
-- and typescriptreact there.
local ls = require('luasnip')
local s, i = ls.snippet, ls.insert_node
local fmt = require('luasnip.extras.fmt').fmt
local rep = require('luasnip.extras').rep

return {
  -- Labelled log: `console.log('user:', user)`, the label typed once.
  s('cl', fmt("console.log('{}:', {});", { i(1, 'value'), rep(1) })),

  -- Test blocks (Jest / Vitest share the API).
  s('desc', fmt([[
describe('{}', () => {{
	{}
}});
]], { i(1), i(0) })),

  s('it', fmt([[
it('{}', async () => {{
	{}
}});
]], { i(1, 'does something'), i(0) })),
}
