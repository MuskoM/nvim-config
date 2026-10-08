-- jdtls config and startup, shared by two entry points:
--
--   after/ftplugin/java.lua   a Java buffer opened -- start or attach to it.
--   plugins/jdtls.lua (init)  nvim opened in a Gradle project with no Java file
--                             -- start the server up front, attached to nothing.
--
-- Why the second one exists: jdtls takes a long time to import a Gradle build,
-- and it only began once the first Java buffer opened. Opening nvim in the
-- project and going straight to a picker meant waiting on that import, and
-- <leader>sw had no server to ask at all. Starting at VimEnter overlaps the
-- import with whatever you do first.
--
-- Both paths must build the SAME config. vim.lsp.start reuses a client only
-- when name and root match, so a config that drifted between the two would
-- start a second jdtls on the same workspace directory -- two JVMs fighting
-- over one -data dir. That is why this is one module rather than a copy.
--
-- Started per-buffer rather than via vim.lsp.enable() in lsp.lua, because jdtls
-- keeps a stateful compiled project model in a workspace directory on disk, one
-- per project root. The single global client that vim.lsp.enable() creates
-- cannot express that; nvim-jdtls's start_or_attach reuses a client when the
-- root matches.
local M = {}

-- The project root, found by walking up from `source` (a buffer number or a
-- path). settings.gradle first: it marks the root of a Gradle *build*, which is
-- the unit jdtls imports. gradlew and .git are fallbacks for odd layouts.
M.root_markers = { 'settings.gradle', 'settings.gradle.kts', 'gradlew', '.git' }

function M.root(source)
  return vim.fs.root(source, M.root_markers)
end

-- M2.2 -- the Lombok agent.
--
-- Lombok generates constructors, accessors and builders at compile time by
-- hooking into the compiler as a javaagent. jdtls runs its own compiler, so it
-- needs the same agent or none of that generated code exists as far as the
-- editor is concerned -- hence "blank final field may not have been
-- initialized" and "x cannot be resolved or is not a field".
--
-- The project also sets accessors.fluent=true in lombok.config, so accessors are
-- session() rather than getSession().
--
-- Mason bundles its own lombok.jar, which is usually older than what the
-- project pins. Version skew between the editor's agent and the build's
-- annotation processor causes errors that do not reproduce in Gradle, so
-- prefer the exact jar the project declares -- read the version out of
-- build.gradle and find it in the Gradle cache. Falls back to Mason's.
local function project_lombok(root)
  local gradle_build = root .. '/build.gradle'
  local f = io.open(gradle_build, 'r')
  if not f then
    return nil
  end
  local content = f:read('*a')
  f:close()

  local version = content:match("versionProjectLombok%s*=%s*['\"]([%d%.]+)['\"]")
  if not version then
    return nil
  end

  -- Gradle caches jars under a content-hash directory, hence the middle glob.
  local pattern = ('%s/.gradle/caches/modules-2/files-2.1/org.projectlombok/lombok/%s/*/lombok-%s.jar')
      :format(vim.env.HOME, version, version)
  local hit = vim.fn.glob(pattern, true, true)[1]
  return hit, version
end

-- Formatting profile.
--
-- Left unset, jdtls formats with Eclipse's built-in defaults -- which are
-- nobody's house style, and rewrap lines and move braces on every save.
-- conform.lua refuses to format-on-save for Java unless one of these files
-- exists; this hands the same file to jdtls so that when formatting does
-- happen, it follows the project rather than Eclipse.
--
-- Keep the filename list in sync with `markers.java` in plugins/conform.lua.
-- Checked as explicit paths rather than vim.fs.find with upward=false: that
-- does a recursive walk downward, which on a large monorepo means crawling the
-- whole tree on every Java buffer open, and finding nothing is the slow case.
local function format_settings_for(root)
  local profile_xml
  for _, subdir in ipairs { '', 'config/', 'build-tools/', 'gradle/', '.config/' } do
    for _, name in ipairs { 'eclipse-formatter.xml', 'eclipse-java-formatter.xml', 'formatter.xml' } do
      local candidate = root .. '/' .. subdir .. name
      if vim.uv.fs_stat(candidate) then
        profile_xml = candidate
        break
      end
    end
    if profile_xml then
      break
    end
  end
  if not profile_xml then
    return nil
  end
  local format_settings = { url = profile_xml }
  -- Eclipse XML can hold several named profiles; jdtls picks the first unless
  -- told otherwise. Read the name out rather than hardcoding it.
  local fh = io.open(profile_xml, 'r')
  if fh then
    local content = fh:read('*a')
    fh:close()
    local profile = content:match('<profile[^>]-name=["\']([^"\']+)["\']')
    if profile then
      format_settings.profile = profile
    end
  end
  return format_settings
end

function M.config(root)
  -- One workspace per project. jdtls writes its compiled project model here, so
  -- it must not be shared between projects. Deleting this directory is the
  -- standard "turn it off and on again" for a confused jdtls.
  local workspace = vim.fn.stdpath('cache') .. '/jdtls-workspace/' .. vim.fn.fnamemodify(root, ':p:h:t')

  -- M2.1 -- which JDK to COMPILE AGAINST.
  --
  -- Distinct from the JDK jdtls itself runs on. `java` on your PATH resolves to
  -- Corretto 25; the project declares a Gradle toolchain and bytecode target of
  -- 21. So jdtls runs on 25 but must compile against 21, and it only knows that
  -- if we tell it here.
  --
  -- Globbed rather than hardcoded so a 21.0.13 patch update doesn't break it.
  -- Note this lives under $HOME/Library, not /Library -- that is where the
  -- Corretto installer put it.
  local jdk21 = vim.fn.glob(vim.env.HOME .. '/Library/Java/JavaVirtualMachines/corretto-21*/Contents/Home', true, true)[1]

  local runtimes = {}
  if jdk21 then
    runtimes = { { name = 'JavaSE-21', path = jdk21, default = true } }
  else
    vim.notify('No Corretto 21 found -- jdtls will compile against the wrong JDK', vim.log.levels.WARN)
  end

  local lombok = project_lombok(root)
  if not lombok then
    lombok = vim.fn.stdpath('data') .. '/mason/share/jdtls/lombok.jar'
  end

  -- mason's wrapper script resolves the Equinox launcher jar and the
  -- OS-specific config directory, so we don't hardcode either.
  local cmd = { vim.fn.stdpath('data') .. '/mason/bin/jdtls', '-data', workspace }
  if vim.uv.fs_stat(lombok) then
    table.insert(cmd, '--jvm-arg=-javaagent:' .. lombok)
  else
    vim.notify('No lombok.jar found -- expect unresolved accessors', vim.log.levels.WARN)
  end

  -- Completion capabilities. start_or_attach bypasses vim.lsp.config entirely,
  -- so the `vim.lsp.config('*', ...)` default set in cmp.lua does not reach
  -- jdtls -- it has to be handed over here. Without it Java completion runs on
  -- Neovim's defaults: no snippetSupport, so selecting a method inserts a bare
  -- name instead of expanding with its parameter list.
  local caps_ok, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
  local capabilities = caps_ok
      and cmp_lsp.default_capabilities()
      or vim.lsp.protocol.make_client_capabilities()

  local format_settings = format_settings_for(root)

  return {
    cmd = cmd,
    root_dir = root,
    capabilities = capabilities,
    -- jdtls refactors that are not code actions, under the buffer-local
    -- <space>a Actions group from plugins/lsp.lua. Visual forms extract the
    -- selection; `<Esc>` first so nvim-jdtls reads the '< '> marks.
    on_attach = function(_, bufnr)
      local jdtls = require('jdtls')
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end
      map('n', '<space>ao', jdtls.organize_imports, '[O]rganize imports')
      map('n', '<space>aev', jdtls.extract_variable, 'Extract [v]ariable')
      map('x', '<space>aev', "<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>", 'Extract [v]ariable')
      map('n', '<space>aec', jdtls.extract_constant, 'Extract [c]onstant')
      map('x', '<space>aec', "<Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>", 'Extract [c]onstant')
      map('x', '<space>aem', "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", 'Extract [m]ethod')
      local ok, wk = pcall(require, 'which-key')
      if ok then
        wk.add { { '<space>ae', group = 'Extract', buffer = bufnr } }
      end
    end,
    -- Diagnostics only for <root>/src/main and <root>/src/test/java; jdtls
    -- publishes for the whole workspace (generated sources, sibling
    -- subprojects), which drowns real problems in <space>D. Filtered here
    -- rather than with `java.import.exclusions`, so references into generated
    -- code still resolve for gd and completion. Trade-off: errors elsewhere are
    -- hidden (Gradle still reports them). The list is emptied rather than the
    -- notification dropped, so stale diagnostics for a hidden file are cleared.
    handlers = {
      ['textDocument/publishDiagnostics'] = function(err, result, ctx)
        if result and result.uri then
          local path = vim.uri_to_fname(result.uri)
          local rel = vim.fs.relpath(root, path) or ''
          -- src/test/java only, not all of src/test: other test source dirs
          -- (e.g. Groovy/Kotlin) hold code jdtls cannot compile, which
          -- produced false "cannot be resolved" errors.
          if not (rel:find('^src/main/') or rel:find('^src/test/java/')) then
            result.diagnostics = {}
          end
        end
        return vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
      end,
    },
    settings = {
      java = {
        configuration = { runtimes = runtimes },
        format = {
          -- No profile found: turn jdtls formatting off outright, so neither
          -- <space>f nor a stray code action can reformat to Eclipse defaults.
          enabled = format_settings ~= nil,
          settings = format_settings,
        },
      },
    },
  }
end

local function running_for(root)
  for _, client in ipairs(vim.lsp.get_clients { name = 'jdtls' }) do
    if client.root_dir == root then
      return true
    end
  end
  return false
end

-- Entry point 1: from after/ftplugin/java.lua, for the current buffer.
function M.attach()
  local ok, jdtls = pcall(require, 'jdtls')
  if not ok then
    vim.notify('nvim-jdtls not installed -- run :Lazy sync', vim.log.levels.WARN)
    return
  end
  local root = M.root(0)
  if not root then
    return
  end
  jdtls.start_or_attach(M.config(root))
end

-- Entry point 2: at VimEnter, from the startup directory (`nvim dir`, or the
-- cwd for a bare `nvim`), attached to no buffer.
--
-- Narrower than M.attach on purpose: only a settings.gradle counts here, not
-- the gradlew / .git fallbacks. Opening nvim in any git repo must not boot a
-- JVM; opening a Java *file* in one still does, via the ftplugin.
--
-- Trade-off: this root comes from a directory, the ftplugin's from the file. If the
-- file sits under a nested settings.gradle (an included build) the two
-- disagree and that file gets its own client. That is the same thing that
-- would have happened without this, just with one extra idle server.
function M.start_for_dir(dir)
  local root = vim.fs.root(vim.fs.normalize(vim.fn.fnamemodify(dir, ':p')),
    { 'settings.gradle', 'settings.gradle.kts' })
  if not root or running_for(root) then
    return
  end
  local ok, jdtls = pcall(require, 'jdtls')
  if not ok then
    return
  end

  -- start_or_attach insists on a buffer with a file:// URI -- it refuses
  -- scratch buffers, and its language/status handler stops reporting once
  -- that buffer is gone. The empty startup buffer has no name, so hand it an
  -- unloaded, unlisted buffer for the build file instead. Nothing is read
  -- from disk and it never shows in <space><space>.
  local anchor_path = vim.fs.joinpath(root, 'settings.gradle')
  if not vim.uv.fs_stat(anchor_path) then
    anchor_path = anchor_path .. '.kts'
  end
  local anchor = vim.fn.bufadd(anchor_path)
  vim.bo[anchor].buflisted = false

  -- attach = false: start the server, attach to nothing. The first Java buffer
  -- then goes through M.attach, and vim.lsp.start's default reuse_client
  -- matches this client on name + root_dir rather than starting another.
  jdtls.start_or_attach(M.config(root), nil, { bufnr = anchor, attach = false })
end

return M
