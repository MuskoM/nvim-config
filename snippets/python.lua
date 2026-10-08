-- Loaded by plugins/luasnip.lua.
local ls = require('luasnip')
local s, i = ls.snippet, ls.insert_node
local fmt = require('luasnip.extras.fmt').fmt

return {
  s('main', fmt([[
def main() -> None:
	{}


if __name__ == "__main__":
	main()
]], { i(0) })),

  -- pytest test function.
  s('test', fmt([[
def test_{}() -> None:
	{}
]], { i(1, 'name'), i(0) })),
}
