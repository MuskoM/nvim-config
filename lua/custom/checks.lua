-- Project-wide checks: run whatever "does this compile" means in this project,
-- parse the output into the quickfix list, open it in Trouble.
--
-- Generalised from the old <leader>cT, which did exactly this but was hardcoded
-- to `yarn typecheck` and tsconfig.json. The shape was right; only the command
-- was specific. See the removal note in keymaps.lua.
--
-- Lives in its own module rather than keymaps.lua because it is a subsystem
-- with a lookup table, not a keymap -- same category as helpers.lua, which is
-- also a non-plugin module that registers its own mapping.
--
-- The module also exports qflist_as_text(), which is the half an AI agent
-- wants: diagnostics are the highest value-per-token context available, and a
-- model cannot generate them for itself. Deliberately no dependency on any
-- agent plugin -- the consumer calls in, so swapping plugins never touches
-- this file.

local M = {}

-- One entry per filetype that has a check worth running.
--
--   marker  what identifies the project root, passed to vim.fs.root
--   cmd     argv list (not a string -- see run() for why)
--   efm     'errorformat', how to turn the tool's output into quickfix entries
--
-- Deliberately only the two primary targets to begin with. A language earns a
-- row here when its check produces parseable positions; `stylua --check` emits
-- a diff with no line numbers, so Lua is absent rather than badly supported.
-- Candidates when needed, both plain %f:%l:%c: %m --
--   python  ruff check --output-format=concise
--   rust    cargo check --message-format short
local checks = {
  java = {
    marker = { 'settings.gradle', 'settings.gradle.kts', 'gradlew' },
    -- --console=plain: without it Gradle emits ANSI colour and progress
    -- redraws, and errorformat matches neither.
    cmd = { './gradlew', 'compileJava', '-q', '--console=plain' },
    -- javac's diagnostic is three lines: the message, the offending source
    -- line, then a caret. %-G discards the latter two along with Gradle's own
    -- chatter, so one error becomes one quickfix entry rather than three.
    efm = '%E%f:%l: error: %m,%W%f:%l: warning: %m,%-G%.%#',
  },
  typescript = {
    marker = { 'tsconfig.json' },
    cmd = { 'yarn', 'typecheck' },
    -- tsc writes `file(line,col): error TS1234: msg`. The escaped comma is
    -- required: an unescaped one separates errorformat patterns.
    efm = '%f(%l\\,%c): %trror %m,%f(%l\\,%c): %tarning %m,%f: %trror %m',
  },
}

-- typescriptreact and friends are the same project and the same command.
checks.typescriptreact = checks.typescript

---Resolve the check for a buffer's filetype, and the project root it runs in.
---@return table|nil check, string|nil root, string|nil err
local function resolve(bufnr)
  local ft = vim.bo[bufnr].filetype
  local check = checks[ft]
  if not check then
    return nil, nil, ('no check configured for filetype %q'):format(ft == '' and '[none]' or ft)
  end

  -- Walking upward from the buffer, not from cwd: in a monorepo the two are
  -- often different, and the buffer is the one that says which subproject.
  --
  -- This duplicates the marker walk in plugins/conform.lua rather than sharing
  -- it. The two ask different questions -- "does this project declare a
  -- style?" vs "what kind of project is this?" -- and the shared part is one
  -- vim.fs.root call. Worth extracting at a third call site, not at two.
  local root = vim.fs.root(bufnr, check.marker)
  if not root then
    return nil, nil, ('no %s found above this file'):format(table.concat(check.marker, ' / '))
  end

  return check, root, nil
end

---Run the check for the current buffer.
function M.run()
  local bufnr = vim.api.nvim_get_current_buf()
  local check, root, err = resolve(bufnr)
  if not check then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local label = table.concat(check.cmd, ' ')
  vim.notify(('Running %s in %s...'):format(label, vim.fn.fnamemodify(root, ':~')), vim.log.levels.INFO)

  -- vim.system rather than jobstart, and both streams merged, because javac
  -- writes diagnostics to STDERR while tsc writes them to stdout. The old
  -- <leader>cT only hooked on_stdout, so the same code against a Gradle build
  -- would have reported "no errors" for a failing compile.
  -- pcall: vim.system raises synchronously when the executable is not found,
  -- which is the ordinary case of a missing gradlew or a machine without yarn.
  -- An unhandled ENOENT stacktrace is a worse answer than saying which command
  -- could not be run.
  local spawned = pcall(vim.system, check.cmd, { cwd = root, text = true }, function(res)
    vim.schedule(function()
      local out = (res.stdout or '') .. (res.stderr or '')
      local lines = vim.split(out, '\n', { trimempty = true })

      vim.fn.setqflist({}, ' ', { title = label, lines = lines, efm = check.efm })

      -- Exit code and parsed-entry count can disagree: a build can fail for
      -- reasons errorformat does not match (no network, wrong JDK, missing
      -- task). Reporting the exit code in that case beats an empty list that
      -- reads as success.
      local n = #vim.fn.getqflist()
      if n > 0 then
        vim.cmd('Trouble qflist open')
      elseif res.code ~= 0 then
        vim.notify(('%s failed (exit %d) but produced no parseable errors -- see :copen')
          :format(label, res.code), vim.log.levels.ERROR)
      else
        vim.notify(label .. ': no errors', vim.log.levels.INFO)
      end
    end)
  end)

  if not spawned then
    vim.notify(('could not run %q -- is it installed and executable?'):format(check.cmd[1]), vim.log.levels.ERROR)
  end
end

---The current quickfix list as plain text, one `path:line:col: message` per
---line, paths relative to cwd.
---
---Relative paths on purpose: absolute ones in a monorepo are mostly repeated
---prefix, which is noise to a reader and tokens to a model.
---@return string
function M.qflist_as_text()
  local items = vim.fn.getqflist()
  if #items == 0 then
    return ''
  end

  local out = {}
  for _, e in ipairs(items) do
    local name = e.bufnr > 0 and vim.fn.fnamemodify(vim.api.nvim_buf_get_name(e.bufnr), ':.') or '?'
    table.insert(out, ('%s:%d:%d: %s'):format(name, e.lnum, e.col, vim.trim(e.text)))
  end
  return table.concat(out, '\n')
end

-- <leader>c ("Check / compile") is declared as a group in plugins/whichkey.lua,
-- so only the mapping's own desc is needed here.
vim.keymap.set('n', '<leader>cc', M.run, { desc = '[C]heck this project (compile / typecheck)' })

-- The clipboard bridge, until an agent plugin owns <leader>ad and calls
-- qflist_as_text() directly (see the module comment). Useful on its own for
-- pasting into a terminal agent, a PR comment or a Slack thread.
--
-- Explicit setreg rather than relying on `clipboard=unnamedplus`, which this
-- config does not set.
vim.keymap.set('n', '<leader>cy', function()
  local text = M.qflist_as_text()
  if text == '' then
    vim.notify('Quickfix list is empty', vim.log.levels.WARN)
    return
  end
  vim.fn.setreg('+', text)
  vim.notify(('Copied %d quickfix entries'):format(#vim.fn.getqflist()), vim.log.levels.INFO)
end, { desc = '[C]op[y] quickfix as text (for an agent / PR comment)' })

return M
