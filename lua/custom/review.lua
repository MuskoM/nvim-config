-- PR review: Fugitive's difftool hunks, frozen into their own Trouble list.
--
-- `:Git difftool <base>...` puts one quickfix entry per hunk, which is the
-- right shape for review -- but the quickfix list is shared. The first `gd`
-- with several results, or `gr`, or a check run, replaces it, and the qflist
-- Trouble view follows along, so the review list is gone mid-review.
--
-- So the hunks are copied out the moment difftool fills the list, served from
-- a separate Trouble source (`prhunks`), and the previous quickfix list is
-- restored with :colder. The trade-off: it is a snapshot. New commits on the
-- PR are not picked up until :PRReview is run again.
--
-- Its own module rather than keymaps.lua for the same reason as checks.lua:
-- it is a subsystem with state, not a mapping.

local M = {}

---@type trouble.Item[]
M.items = {}

-- Registered on first use rather than at startup: trouble.nvim lazy-loads on
-- `cmd`, and require('trouble.sources') below is what loads it. Registering at
-- startup would defeat that for a command used a few times a week.
--
-- Trouble's source API (trouble.sources.register, a `get(cb)` function and a
-- `config.modes` table merged into the defaults) is internal rather than
-- documented. Checked against the commit pinned in lazy-lock.json; if a
-- trouble update breaks :PRReview, look here first.
local function ensure_source()
  local sources = require('trouble.sources')
  if sources.sources.prhunks then
    return
  end
  sources.register('prhunks', {
    config = {
      modes = {
        prhunks = {
          desc = 'PR review hunks',
          source = 'prhunks',
          groups = { { 'filename', format = '{file_icon} {filename} {count}' } },
          -- No severity: hunks have none, and sorting on it would only
          -- reorder them away from file order.
          sort = { 'filename', 'pos' },
          format = '{text:ts} {pos}',
        },
      },
    },
    get = function(cb)
      cb(M.items)
    end,
  })
end

-- The remote's default branch, so repos on `master` or `develop` need no
-- argument. origin/HEAD is only set if the clone created it (or after
-- `git remote set-head origin -a`); origin/main is the fallback, not a guess
-- that is checked.
local function default_base()
  -- cwd from Fugitive, not nvim's cwd: the buffer's repo is the one to review.
  local root = vim.fn.FugitiveWorkTree()
  local res = vim.system({ 'git', 'rev-parse', '--abbrev-ref', 'origin/HEAD' },
    { text = true, cwd = root ~= '' and root or nil }):wait()
  if res.code == 0 and res.stdout ~= '' then
    return vim.trim(res.stdout)
  end
  return 'origin/main'
end

function M.review(base)
  base = (base and base ~= '') and base or default_base()
  ensure_source()

  -- Diff the merge base against the WORKING TREE, not `<base>...`: entries
  -- become real project files rather than fugitive:// blobs, so LSP (gd etc.)
  -- works in them. Includes uncommitted edits too.
  local root = vim.fn.FugitiveWorkTree()
  local mb = vim.system({ 'git', 'merge-base', 'HEAD', base },
    { text = true, cwd = root ~= '' and root or nil }):wait()
  if mb.code ~= 0 then
    vim.notify(('No merge base with %s: %s'):format(base, vim.trim(mb.stderr or '')), vim.log.levels.ERROR)
    return
  end
  vim.cmd('Git difftool ' .. vim.trim(mb.stdout))

  -- Scheduled so the snapshot is taken after everything difftool queued has
  -- run. (Originally it had to outlast a quickfix -> Trouble BufWinEnter
  -- autocmd in plugins/trouble.lua; that autocmd is gone, but the ordering
  -- guarantee is cheap to keep.)
  vim.schedule(function()
    -- Belt and braces for the fugitive:// problem above: should any entry
    -- still name a blob, repoint it at the real file, in place ('r' keeps
    -- the quickfix history that :colder walks below).
    local qf = vim.fn.getqflist()
    local rewrote = false
    local lines_of = {} -- path -> file lines, read once per file
    for _, e in ipairs(qf) do
      local name = e.bufnr > 0 and vim.api.nvim_buf_get_name(e.bufnr) or ''
      if name:match('^fugitive://') then
        name = vim.fn.FugitiveReal(name)
        e.filename, e.bufnr, rewrote = name, nil, true
      end

      -- Entry text is the hunk header's function context, which git fills
      -- from the diff driver's funcname rule (`*.java diff=java` in
      -- ~/.config/git/attributes gives method signatures). Hunks above the
      -- first match -- imports, package line -- get an empty header, and
      -- showed up in Trouble as a bare [line, col]. Fall back to the line at
      -- the hunk start. Trade-off: that is usually one of git's 3 context
      -- lines, not the changed one -- close enough to say "the imports", and
      -- avoids re-diffing to find the first `+`.
      if vim.trim(e.text or '') == '' and name ~= '' and e.lnum > 0 then
        if not lines_of[name] then
          lines_of[name] = vim.fn.filereadable(name) == 1 and vim.fn.readfile(name) or {}
        end
        local line = lines_of[name][e.lnum]
        if line then
          e.text, rewrote = vim.trim(line), true
        end
      end
    end
    if rewrote then
      vim.fn.setqflist({}, 'r', { items = qf })
    end

    -- Reuse trouble's own qf conversion instead of rebuilding Item.new calls:
    -- it handles lnum/col 0, multi-line entries and invalid rows the same way
    -- the qflist view does.
    M.items = require('trouble.sources.qf').get_list()
    if #M.items == 0 then
      vim.notify('No changes against ' .. base, vim.log.levels.INFO)
      return
    end

    local trouble = require('trouble')
    for _, mode in ipairs({ 'quickfix', 'qflist' }) do
      if trouble.is_open(mode) then
        trouble.close(mode)
      end
    end
    vim.cmd('cclose')
    -- Put back whatever was in the quickfix list before (check output, a
    -- grep). pcall: errors at the bottom of the stack when there was none.
    pcall(vim.cmd, 'silent colder')

    -- `refresh` because the source is static: without it, reopening an
    -- existing prhunks view would show the previous snapshot.
    trouble.open({ mode = 'prhunks', refresh = true })
  end)
end

vim.api.nvim_create_user_command('PRReview', function(opts)
  M.review(opts.args)
end, { nargs = '?', desc = 'Review branch hunks against base (default: origin/HEAD)' })

-- Under the Fugitive <leader>g prefix: it reaches the repo, not the buffer.
-- gR builds (or rebuilds) the snapshot; gr only shows/hides it, so toggling
-- never re-runs git or throws away where you were in the list.
vim.keymap.set('n', '<leader>gR', function()
  M.review()
end, { desc = 'PR [R]eview: build hunks (Trouble)' })

-- Not trouble.toggle('prhunks'): that would open an empty view (or, before the
-- first :PRReview, fail on an unregistered mode). With nothing built yet,
-- building is the only useful thing gr can do. Opening focuses the list
-- (trouble's default) -- you toggle it on to go read it.
vim.keymap.set('n', '<leader>gr', function()
  if #M.items == 0 then
    M.review()
    return
  end
  local trouble = require('trouble')
  if trouble.is_open('prhunks') then
    trouble.close('prhunks')
  else
    -- refresh=false: the source is static, and refreshing would reset the
    -- cursor to the top instead of where you left off.
    trouble.open({ mode = 'prhunks', refresh = false })
  end
end, { desc = 'PR [r]eview: toggle hunk list' })

return M
