-- Symbol search, in two scopes, sharing one picker and one display.
--
-- Why this exists rather than builtin.lsp_dynamic_workspace_symbols:
--
-- nvim-jdtls advertises classFileContentsSupport = true (see
-- lua/jdtls/capabilities.lua), which is what lets `gd` decompile into Spring
-- and JDK source. The side effect is that plain `workspace/symbol` returns
-- symbols from every jar on the classpath -- tens of thousands on a large
-- project -- and
-- a dynamic picker re-queries that on every keystroke, so it crawls.
--
-- Rather than turn the flag off and lose decompiling, split at the query
-- level. jdtls's `java/searchSymbols` extension takes a sourceOnly flag:
--
--   <leader>sw  java/searchSymbols, sourceOnly  -- project sources, fast
--   <leader>sW  workspace/symbol                -- jars too, for deep dives
--
-- Same client, no restart, nothing lost.
--
-- Both modes go through this module rather than one here and one builtin,
-- because the builtin routes results through vim.lsp.util.symbols_to_items,
-- which throws away containerName -- the only thing distinguishing the twelve
-- identically-named classes in a Spring codebase. Handling the raw response
-- keeps it, and keeps the two lists formatted identically.

local M = {}

local channel = require('plenary.async.control').channel
local conf = require('telescope.config').values
local entry_display = require 'telescope.pickers.entry_display'
local finders = require 'telescope.finders'
local pickers = require 'telescope.pickers'
local sorters = require 'telescope.sorters'
local telescope_actions = require 'telescope.actions'

-- Set this if omitting projectName turns out to scope the search wrongly on a
-- multi-project Gradle build. Eclipse project names for Gradle subprojects are
-- the subproject names, not the repo name.
M.project_name = nil

local displayer = entry_display.create {
  separator = ' ',
  items = {
    { width = 1 },        -- jar marker, blank for project sources
    { width = 11 },       -- [Kind]
    { width = 40 },       -- symbol name
    { remaining = true }, -- container (package / enclosing type)
  },
}

local kind_hl = {
  Class = 'Type',
  Interface = 'Type',
  Enum = 'Type',
  Struct = 'Type',
  Method = 'Function',
  Constructor = 'Function',
  Function = 'Function',
  Field = 'Identifier',
  Property = 'Identifier',
  Constant = 'Constant',
  EnumMember = 'Constant',
}

local function entry_maker(item)
  return {
    value = item,
    ordinal = item.container .. ' ' .. item.name,
    filename = item.filename,
    lnum = item.lnum,
    col = item.col,
    display = function()
      return displayer {
        -- Leading marker so jar symbols form a scannable column rather than
        -- hiding mid-row. Blank, not absent, for project sources -- the
        -- fixed-width slot keeps every following column aligned.
        { item.external and '󰏗' or ' ', 'DiagnosticWarn' },
        { '[' .. item.kind .. ']',      kind_hl[item.kind] or 'TelescopeResultsComment' },
        item.name,
        { item.container,               'TelescopeResultsComment' },
      }
    end,
  }
end

---Normalise a SymbolInformation-shaped response into telescope items.
---
---Handles both file:// (project sources) and jdt:// (symbols inside jars).
---A jdt URI is not a real path, but nvim-jdtls registers a BufReadCmd for the
---scheme, so keeping it verbatim as `filename` means <CR> still opens the
---decompiled buffer.
local function to_items(symbols)
  local items = {}
  for _, s in ipairs(symbols or {}) do
    local loc = s.location or {}
    local uri = loc.uri
    if uri then
      local is_file = vim.startswith(uri, 'file://')
      local start = (loc.range or {}).start or { line = 0, character = 0 }
      table.insert(items, {
        filename = is_file and vim.uri_to_fname(uri) or uri,
        external = not is_file,
        lnum = start.line + 1,
        col = start.character + 1,
        kind = vim.lsp.protocol.SymbolKind[s.kind] or 'Unknown',
        name = s.name,
        container = s.containerName or '',
      })
    end
  end
  return items
end

local modes = {
  sources = {
    title = 'Java Symbols (sources only)',
    method = 'java/searchSymbols',
    -- jdtls treats the query as a pattern with `*` as wildcard, and an empty
    -- prompt matches nothing, so seed the initial list with everything.
    seed_wildcard = true,
    client = function(bufnr)
      return vim.lsp.get_clients({ bufnr = bufnr, name = 'jdtls' })[1]
    end,
    params = function(query)
      local params = { query = query, sourceOnly = true }
      if M.project_name then
        params.projectName = M.project_name
      end
      return params
    end,
  },
  all = {
    title = 'Workspace Symbols (incl. jars)',
    method = 'workspace/symbol',
    -- No wildcard seeding here: standard workspace/symbol takes a plain
    -- substring, where '*' is a literal that matches nothing.
    seed_wildcard = false,
    client = function(bufnr)
      -- Deliberately NOT filtering with `method = 'workspace/symbol'`.
      -- get_clients() resolves that through client:supports_method(), and
      -- jdtls registers most capabilities dynamically after initialize, so the
      -- check reports false for a method that works fine -- the same reason
      -- `gd` is un-gated in lsp.lua. Prefer a client that admits to supporting
      -- it, but fall back to any attached client and just ask.
      local clients = vim.lsp.get_clients { bufnr = bufnr }
      for _, c in ipairs(clients) do
        if c:supports_method('workspace/symbol') then
          return c
        end
      end
      return clients[1]
    end,
    params = function(query)
      return { query = query }
    end,
  },
}

---Mirrors telescope's own dynamic symbol requester: one in-flight request at a
---time, cancelled and reissued on each keystroke.
local function requester(mode, client, bufnr)
  local cancel = function() end

  return function(prompt)
    local tx, rx = channel.oneshot()
    cancel()

    local query = prompt or ''
    if query == '' and mode.seed_wildcard then
      query = '*'
    end

    local ok, request_id = client:request(mode.method, mode.params(query), tx, bufnr)
    if not ok then
      return {}
    end
    cancel = function()
      if request_id then
        client:cancel_request(request_id)
      end
    end

    local err, res = rx()
    if err then
      -- notify_once: this runs per keystroke, so a persistent server error
      -- would otherwise bury the screen in duplicate messages.
      vim.notify_once(
        mode.method .. ' failed: ' .. (type(err) == 'table' and (err.message or vim.inspect(err)) or tostring(err)),
        vim.log.levels.WARN
      )
      return {}
    end
    return to_items(res)
  end
end

---@param name 'sources'|'all'
local function symbol_picker(name, opts)
  opts = opts or {}
  local mode = assert(modes[name], 'unknown symbol mode: ' .. tostring(name))
  local bufnr = vim.api.nvim_get_current_buf()

  local client = mode.client(bufnr)
  -- Sources mode needs jdtls specifically. In a Lua or Python buffer, degrade
  -- to the generic scope rather than leaving the key dead.
  if not client and name == 'sources' then
    mode = modes.all
    client = mode.client(bufnr)
  end
  if not client then
    vim.notify('No attached client answers ' .. mode.method, vim.log.levels.INFO)
    return
  end

  pickers.new(opts, {
    prompt_title = mode.title,
    finder = finders.new_dynamic {
      entry_maker = opts.entry_maker or entry_maker,
      fn = requester(mode, client, bufnr),
    },
    previewer = conf.qflist_previewer(opts),
    -- highlighter_only preserves the server's own relevance ordering instead
    -- of re-sorting the result set on every keystroke. <C-space> switches to
    -- local fuzzy filtering over whatever is currently listed.
    sorter = sorters.highlighter_only(opts),
    attach_mappings = function(_, map)
      map('i', '<c-space>', telescope_actions.to_fuzzy_refine)
      return true
    end,
    push_cursor_on_edit = true,
    push_tagstack_on_edit = true,
  }):find()
end

M.source_symbols = function(opts)
  symbol_picker('sources', opts)
end

M.all_symbols = function(opts)
  symbol_picker('all', opts)
end

---Diagnostic: fire both symbol methods for one query and report what comes
---back, broken down by URI scheme. `jdt=` counts symbols living inside jars.
---
---   :JavaSymbolsDebug SpringApplication
---
---Pick a type that exists ONLY in a dependency -- SpringApplication,
---ResponseEntity, ObjectMapper, ArrayList. One of your own classes proves
---nothing, since both methods return project sources.
function M.debug(query)
  query = (query and query ~= '') and query or 'SpringApplication'
  local bufnr = vim.api.nvim_get_current_buf()

  local probes = {
    { 'workspace/symbol',   { query = query } },
    { 'java/searchSymbols', { query = query, sourceOnly = true } },
    { 'java/searchSymbols', { query = query, sourceOnly = false } },
  }

  for _, probe in ipairs(probes) do
    local method, params = probe[1], probe[2]
    local label = method
    if params.sourceOnly ~= nil then
      label = label .. ' sourceOnly=' .. tostring(params.sourceOnly)
    end

    local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'jdtls' })[1]
    if not client then
      vim.notify('No jdtls client attached to this buffer', vim.log.levels.WARN)
      return
    end

    client:request(method, params, function(err, res)
      if err then
        print(('%-38s ERROR %s'):format(label, err.message or vim.inspect(err)))
        return
      end
      local schemes, total = {}, 0
      local sample
      for _, s in ipairs(res or {}) do
        total = total + 1
        local uri = (s.location or {}).uri or '<no uri>'
        local scheme = uri:match('^(%a[%w+.-]*)://') or '<none>'
        schemes[scheme] = (schemes[scheme] or 0) + 1
        if scheme == 'jdt' and not sample then
          sample = s.name .. '  ' .. uri:sub(1, 90)
        end
      end
      local parts = {}
      for scheme, n in pairs(schemes) do
        table.insert(parts, scheme .. '=' .. n)
      end
      table.sort(parts)
      print(('%-38s total=%-5d %s'):format(label, total, table.concat(parts, ' ')))
      if sample then
        print('    first jar hit: ' .. sample)
      end
    end, bufnr)
  end
end

M.setup = function()
  local set = vim.keymap.set

  vim.api.nvim_create_user_command('JavaSymbolsDebug', function(cmd)
    M.debug(cmd.args)
  end, { nargs = '?', desc = 'Probe jdtls symbol methods for a query' })

  set('n', '<leader>sw', M.source_symbols,
    { desc = 'Search symbols - project sources (LSP)' })
  set('n', '<leader>sW', M.all_symbols,
    { desc = 'Search symbols - incl. jars (LSP)' })

  local ok, wk = pcall(require, 'which-key')
  if ok then
    wk.add {
      { '<leader>sw', desc = 'Search symbols - project sources (LSP)', icon = '󰎠' },
      { '<leader>sW', desc = 'Search symbols - incl. jars (LSP)', icon = '󰏗' },
    }
  end
end

return M
