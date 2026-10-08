-- Loaded by plugins/luasnip.lua. Only what jdtls does not offer itself.
local ls = require('luasnip')
local s, i, f = ls.snippet, ls.insert_node, ls.function_node
local fmt = require('luasnip.extras.fmt').fmt

-- Class name from the file name, which Java requires to match.
local function class_name()
  return vim.fn.expand('%:t:r')
end

return {
  -- JUnit 5 test with the given / when / then skeleton.
  s('test', fmt([[
@Test
void {}() {{
	// given
	{}

	// when

	// then
}}
]], { i(1, 'shouldDoSomething'), i(0) })),

  -- SLF4J logger, for classes not using Lombok's @Slf4j.
  s('log', fmt('private static final Logger log = LoggerFactory.getLogger({}.class);', {
    f(class_name),
  })),
}
