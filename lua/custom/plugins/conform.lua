-- Format on save, but only where the project has declared a style.
--
-- The rule: if no formatter config exists in the repo, saving must not rewrite
-- the file. Otherwise the formatter silently imposes its own defaults --
-- Prettier's without a .prettierrc, Eclipse's via jdtls without a profile --
-- and every file you touch carries unrelated reformatting into review.
--
-- <space>f always formats, config or not. Explicit is different from automatic.

-- Config filenames that count as "this project has a style", per tool.
local markers = {
  prettier = {
    '.prettierrc', '.prettierrc.json', '.prettierrc.json5',
    '.prettierrc.yml', '.prettierrc.yaml', '.prettierrc.toml',
    '.prettierrc.js', '.prettierrc.cjs', '.prettierrc.mjs', '.prettierrc.ts',
    'prettier.config.js', 'prettier.config.cjs', 'prettier.config.mjs',
    'prettier.config.ts',
  },
  -- Only an Eclipse profile counts. Spotless / google-java-format configure a
  -- Gradle task, not jdtls -- treating those as "configured" would let jdtls
  -- format to Eclipse defaults that actively disagree with what CI enforces.
  java = { 'eclipse-formatter.xml', 'eclipse-java-formatter.xml', 'formatter.xml' },
  lua = { '.stylua.toml', 'stylua.toml' },
  rust = { 'rustfmt.toml', '.rustfmt.toml' },
  python = { 'ruff.toml', '.ruff.toml' },
  -- Go has exactly one style (gofmt), so being inside a module is enough:
  -- there is no project config that could disagree with it.
  go = { 'go.mod', 'go.work' },
}

local ft_tool = {
  javascript = 'prettier',
  javascriptreact = 'prettier',
  typescript = 'prettier',
  typescriptreact = 'prettier',
  json = 'prettier',
  jsonc = 'prettier',
  css = 'prettier',
  scss = 'prettier',
  less = 'prettier',
  html = 'prettier',
  yaml = 'prettier',
  markdown = 'prettier',
  graphql = 'prettier',
  java = 'java',
  lua = 'lua',
  rust = 'rust',
  python = 'python',
  go = 'go',
}

---Does `dir` or any ancestor contain `file`, and does that file match `pattern`?
local function found_containing(dir, file, pattern)
  local hit = vim.fs.find(file, { upward = true, path = dir, type = 'file' })[1]
  if not hit then
    return false
  end
  if not pattern then
    return true
  end
  local fh = io.open(hit, 'r')
  if not fh then
    return false
  end
  local content = fh:read('*a')
  fh:close()
  return content:find(pattern, 1, true) ~= nil
end

-- One filesystem walk per directory per filetype, cached for the session.
-- Saving is frequent; walking to the filesystem root each time is not free.
local cache = {}

local function project_has_style(bufnr)
  -- Not a real file on disk: no project to consult, and nothing here that
  -- should be rewritten.
  --
  -- Not defensive tidiness -- this is load-bearing for claudecode.nvim.
  -- Its proposed-change diffs are `acwrite` buffers carrying a real-looking
  -- filename, and `:w` is how a diff is *accepted*. Without this guard
  -- BufWritePre fires, the walk below starts from the real directory, finds
  -- the project's markers, and reformats Claude's proposal at the exact
  -- moment you accept it.
  if vim.bo[bufnr].buftype ~= '' then
    return false
  end

  local ft = vim.bo[bufnr].filetype
  local tool = ft_tool[ft]
  if not tool then
    return false -- unknown filetype: never rewrite on save
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then
    return false -- unsaved scratch buffer, no project to consult
  end
  local dir = vim.fs.dirname(path)

  local key = tool .. '\0' .. dir
  if cache[key] ~= nil then
    return cache[key]
  end

  local ok = vim.fs.find(markers[tool], { upward = true, path = dir, type = 'file' })[1] ~= nil

  -- Tool-specific config that lives inside a shared file rather than its own.
  if not ok and tool == 'prettier' then
    ok = found_containing(dir, 'package.json', '"prettier"')
  elseif not ok and tool == 'python' then
    ok = found_containing(dir, 'pyproject.toml', '[tool.ruff]')
  end

  cache[key] = ok
  return ok
end

return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<space>f',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = { 'n', 'x' },
      desc = 'Format file',
    },
    {
      -- Answers "why did / didn't this file get formatted on save?"
      '<space>F',
      function()
        local bufnr = vim.api.nvim_get_current_buf()
        local ft = vim.bo[bufnr].filetype
        vim.notify(
          ('%s: format-on-save %s'):format(
            ft == '' and '[no filetype]' or ft,
            project_has_style(bufnr) and 'ON (project config found)'
              or 'OFF (no formatter config in project)'
          ),
          vim.log.levels.INFO
        )
      end,
      desc = 'Format-on-save status',
    },
  },
  opts = {
    -- Web filetypes go through Prettier. conform auto-discovers the
    -- project-local node_modules/.bin/prettier and Prettier itself reads the
    -- nearest .prettierrc, so formatting always matches the repo's config.
    formatters_by_ft = {
      javascript = { 'prettier' },
      javascriptreact = { 'prettier' },
      typescript = { 'prettier' },
      typescriptreact = { 'prettier' },
      json = { 'prettier' },
      jsonc = { 'prettier' },
      css = { 'prettier' },
      scss = { 'prettier' },
      less = { 'prettier' },
      html = { 'prettier' },
      yaml = { 'prettier' },
      markdown = { 'prettier' },
      graphql = { 'prettier' },
      -- goimports = gofmt + import add/remove/sort. Install with
      -- :MasonInstall goimports. If it is missing, the lsp_format fallback
      -- below lets gopls format instead (without touching imports).
      go = { 'goimports' },
      -- Lua's on-save trigger is a stylua.toml, so stylua is the formatter
      -- that honours it. Installed by plugins/mason.lua.
      lua = { 'stylua' },
    },
    -- Returning nil skips formatting for this save entirely -- including the
    -- LSP fallback, which is what was reaching jdtls for Java.
    format_on_save = function(bufnr)
      if not project_has_style(bufnr) then
        return nil
      end
      -- No LSP fallback for Lua: lua_ls formats in its own style and never
      -- reads stylua.toml, so if stylua is missing, skipping is the correct
      -- result -- the project declared a style lua_ls cannot follow.
      local fallback = vim.bo[bufnr].filetype == 'lua' and 'never' or 'fallback'
      return { timeout_ms = 2000, lsp_format = fallback }
    end,
  },
}
