-- Java / Gradle setup.
--
-- Started per-buffer rather than via vim.lsp.enable() in lsp.lua, because jdtls
-- keeps a stateful compiled project model in a workspace directory, one per
-- project root. See lua/custom/plugins/jdtls.lua.

-- Editor basics, unrelated to the LSP. 4 spaces, no tabs.
local set = vim.opt_local
set.shiftwidth = 4
set.tabstop = 4
set.softtabstop = 4
set.expandtab = true

local ok, jdtls = pcall(require, 'jdtls')
if not ok then
  vim.notify('nvim-jdtls not installed -- run :Lazy sync', vim.log.levels.WARN)
  return
end

-- The project root, found by walking up from this buffer. settings.gradle
-- first: it marks the root of a Gradle *build*, which is the unit jdtls
-- imports. gradlew and .git are fallbacks for odd layouts.
local root = vim.fs.root(0, { 'settings.gradle', 'settings.gradle.kts', 'gradlew', '.git' })
if not root then
  return
end

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
local function project_lombok()
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

local lombok = project_lombok()
if not lombok then
  lombok = vim.fn.stdpath('data') .. '/mason/share/jdtls/lombok.jar'
end

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

jdtls.start_or_attach({
  -- mason's wrapper script resolves the Equinox launcher jar and the
  -- OS-specific config directory, so we don't hardcode either.
  cmd = cmd,
  root_dir = root,
  capabilities = capabilities,
  settings = {
    java = {
      configuration = { runtimes = runtimes },
    },
  },
})
