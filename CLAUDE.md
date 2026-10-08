# CLAUDE.md

Personal Neovim configuration. Java/Spring is the primary target, alongside
TypeScript, Python, Lua, Rust and Go. `README.md` describes what the config
*does* (requirements, keymap tables, plugin list); this file records only the
constraints and invariants that are easy to violate. Don't copy README content
here — link to it.

When something here and the code disagree, the code wins — fix this file.

---

## Hard requirements

| | |
|---|---|
Full list in README. The ones that constrain changes:

| | |
|---|---|
| Neovim | **0.12+**. Do not suggest patterns that only work on 0.10/0.11 |
| `tree-sitter-cli` | from a system package manager — **not** the npm build, a different and older artefact |
| Plugin manager | lazy.nvim, bootstrapped in `lua/custom/lazy.lua` |
| Completion | **nvim-cmp**, not blink.cmp. Do not migrate without being asked |

`vim.lsp.config()` / `vim.lsp.enable()` (the 0.11+ native API) is used
throughout `plugins/lsp.lua`. Do not reintroduce
`require('lspconfig').<server>.setup{}`.

### Current APIs that look wrong to older training data

This config tracks 0.12. A model whose knowledge predates a rename will try to
"fix" these back — don't.

| Used here | Not this |
|---|---|
| `vim.hl.hl_op()` (handles `TextYankPost` *and* `TextPutPost`) | `vim.hl.on_yank()`, deprecated in 0.12 |
| `vim.hl.*` | `vim.highlight.*`, deprecated |
| `vim.lsp.config()` / `vim.lsp.enable()` | `lspconfig.<server>.setup{}` |
| `vim.fs.root()`, `vim.uv`, `vim.system()` | `vim.fn.systemlist`, `vim.loop`, bare `jobstart` |

If a change here is justified by "that function is deprecated", check against
the *current* `:h deprecated` before making it, not from memory.

---

## Layout

```
init.lua                  leaders, then requires the custom.* modules in order
lua/custom/
  options.lua             editor settings
  keymaps.lua             keymap scheme (authoritative) + all non-plugin mappings
  autocmds.lua            yank highlight, transparent background
  helpers.lua             RouterOS/MikroTik deploy
  checks.lua              per-project compile/typecheck -> quickfix -> Trouble
  review.lua              :PRReview -- difftool hunks snapshotted into a Trouble `prhunks` list
  java.lua                jdtls config + both start paths (ftplugin, VimEnter)
  statusline.lua          default statusline + mode / macro-recording prefix
  lazy.lua                bootstrap + `{ import = 'custom.plugins' }`
  plugins/*.lua           ONE FILE PER PLUGIN, returning a lazy spec
  telescope/*.lua         custom pickers
  local/*.lua             machine-local, gitignored
after/ftplugin/
  java.lua                indent + calls custom.java.attach()
  lua.lua                 2-space indent
  go.lua                  tabs (gofmt)
snippets/<filetype>.lua   LuaSnip snippets, loaded by plugins/luasnip.lua
docs/                     notes, not config -- do not lint, format or refactor
```

`snippets/` stays small on purpose: only what the language servers do not
already offer as completion snippets.

**One file per plugin** in `lua/custom/plugins/`. New plugin means a new file;
`lazy.lua` imports the directory, so nothing needs registering.

---

## Keymap scheme

`<leader>` (`,`) is global scope, `<space>` is this buffer, and
`<localleader>` is also `<space>`. The authoritative version is the comment
block at the top of `lua/custom/keymaps.lua`; read it before adding any
mapping. Current keys are tabled in README.

### The sharp edge

Because localleader is `<space>`, a buffer-local mapping **silently shadows** a
global one on the same keys, with no warning. New `<localleader>` mappings must
avoid the suffixes already taken globally:

```
<space>  a  d  D  e  f  F  o  q  t  v  <  >
```

(See `helpers.lua` for a worked example: RouterOS deploy is `<localleader>m`
rather than `<localleader>d` precisely because `<space>d` is Trouble's.)

Taken under `<leader>`: `a c f g h o s u w R ? 1 2 3 4` (`h`, `1`–`4` are
harpoon; `a` is Claude Code).

Also taken outside both leaders: `\` (reverse `;`), `]]` / `[[` (snacks.words),
`ih` (gitsigns text object), `af` `if` `ac` `ic` `aa` `ia` and `]m` `[m` `]M` `[M`
(treesitter textobjects), and `<C-l>` / `<C-h>` in insert and select mode
(snippet jumps, falling through to the default when there is nothing to jump
to). `<C-h/j/k/l>` in normal mode are pane navigation — plugin buffer maps
that shadow them get moved (see the `keymaps` overrides in `plugins/oil.lua`
and `kulala_keymaps` in `plugins/kulala.lua`).

A `<space>` mapping existing in one filetype and not another is **correct, not a
bug** — the LSP mappings are registered buffer-locally on `LspAttach`, so they
are absent where no server is attached.

Visual-mode mappings use `'x'`, never `'v'` or `''`: those include select mode,
which is what snippet placeholders are, so typing into a placeholder would fire
the mapping.

### Where a mapping goes

- Plugin-owned → that plugin's spec, under `keys = {}`, so lazy can defer
  loading until first press. Prefer `<cmd>Command<cr>` strings over function
  calls when the plugin lazy-loads on `cmd`.
- Not tied to a plugin → `lua/custom/keymaps.lua`.
- LSP → the `LspAttach` autocmd in `plugins/lsp.lua`, buffer-local.

Every mapping carries a `desc`. which-key **group labels** live in
`plugins/whichkey.lua`, except buffer-local ones, which are registered next to
their mappings so the menu never advertises an empty submenu.

Never declare a which-key group with no mappings behind it.

---

## Formatting policy — do not weaken this

`plugins/conform.lua` enforces one rule:

> **If the project declares no formatter config, saving must not rewrite the
> file.** Otherwise the formatter imposes its own defaults — Prettier's without
> a `.prettierrc`, Eclipse's via jdtls without a profile — and every touched
> file carries unrelated reformatting into review.

Implementation: `project_has_style()` walks upward for per-tool marker files
(cached per directory per session). `format_on_save` returns `nil` when none is
found, which skips formatting entirely *including the LSP fallback*.
`<space>f` always formats, config or not — explicit is different from automatic.

Consequences to respect:

- Do not add a filetype to `formatters_by_ft` without also adding its marker
  files to `markers`.
- For Java, **only an Eclipse profile counts**. Spotless and
  google-java-format configure a Gradle task, not jdtls — treating those as
  "configured" would let jdtls format to Eclipse defaults that disagree with
  what CI enforces.
- `markers.java` must stay in sync with the profile filename list in
  `lua/custom/java.lua`.
- **Lua has no LSP fallback on save.** Its trigger is a `stylua.toml`, which
  lua_ls's formatter ignores, so with stylua missing, skipping is correct.
  `stylua` is installed by `plugins/mason.lua`.

### Style inside this repo

**This repo itself declares no formatter config** (no `.stylua.toml`), so
format-on-save is off here by design. Do not add one, and do not run `stylua`
over these files. Match surrounding style by hand:

- Lua files here use **2-space** indent (`after/ftplugin/lua.lua`), even though
  `options.lua` sets 4 globally for other languages.
- Single quotes for Lua strings, mostly; follow the neighbouring file.

---

## nvim-treesitter is on `main`

A full rewrite, not a version bump. `ensure_installed`, `auto_install` and
`sync_install` **do not exist**, and highlighting is **not** automatic.

`plugins/treesitter.lua` holds **two separate lists**, and adding a language
means adding it to both:

1. `parsers` — parser names, passed to `require('nvim-treesitter').install()`.
2. `filetypes` — filetypes an autocmd calls `vim.treesitter.start()` for.

They differ wherever parser name and filetype differ: `vimdoc`→`help`,
`bash`→`sh`, and `markdown_inline` has **no filetype at all** (it is reached by
injection from `markdown`).

Markdown parsers are load-bearing: noice renders LSP hover windows as markdown
buffers through treesitter, so `markdown` + `markdown_inline` are what colour
`K` output.

`lazy = false` is required — upstream states the rewrite does not support
lazy-loading. `nvim-treesitter-textobjects` is also on its `main` rewrite: its
`setup()` takes options only and every mapping is set by hand in
`plugins/treesitter.lua` — the old `textobjects = { select = { keymaps = ... } }`
config does not exist there. It sets `vim.g.no_plugin_maps = true` so built-in
ftplugins (python, rust, ...) cannot shadow `]m` / `]]` buffer-locally; don't
remove it.

---

## Java / jdtls

jdtls does **not** start via `vim.lsp.enable()` — why is in the header of
`lua/custom/java.lua`. Two invariants follow:

- It is excluded from mason-lspconfig's `automatic_enable`
  (`plugins/mason.lua`). Without that, Mason enables lspconfig's jdtls too and
  two servers fight over one workspace.
- Both entry points (the ftplugin and the VimEnter start in `plugins/jdtls.lua`)
  build their config from `java.lua`'s one function. `vim.lsp.start` reuses a
  client only on matching name + root; a drifted second config would start a
  second jdtls on the same `-data` directory.

Four things in that config are easy to break:

1. **Compile target.** `java` on PATH is Corretto 25; the project targets 21.
   jdtls runs on 25 and compiles against 21 only because `configuration.runtimes`
   says so. The path is globbed so a patch release doesn't break it, and lives
   under `$HOME/Library`, not `/Library`.
2. **Lombok.** jdtls runs its own compiler and needs the Lombok javaagent, or
   generated accessors and constructors do not exist as far as the editor is
   concerned. The version is read from `build.gradle` and located in the Gradle
   cache — Mason's bundled jar is usually older, and the skew produces errors
   that do not reproduce in a Gradle build. `lombok.config` sets
   `accessors.fluent=true`, so accessors are `session()` not `getSession()`.
3. **Capabilities.** `start_or_attach` bypasses `vim.lsp.config` entirely, so
   the `vim.lsp.config('*', ...)` default set in `plugins/cmp.lua` never reaches
   jdtls. They are passed explicitly. Without them Java completion loses
   `snippetSupport` and inserts bare method names.
4. **Format profile.** Unset, jdtls formats to Eclipse defaults. The profile is
   searched as explicit paths (not `vim.fs.find`, which walks *downward* and
   crawls a monorepo on every Java buffer open), and formatting is switched off
   outright when none is found.

**Symbol search is deliberately split in two** (`<leader>sw` / `<leader>sW`).
nvim-jdtls advertises `classFileContentsSupport`, which lets `gd` decompile
into library source — but it also makes `workspace/symbol` return symbols from
every jar, too slow for a picker that re-queries per keystroke.
`lua/custom/telescope/java_symbols.lua` splits at the query level instead. Do
not "simplify" this to one picker.

---

## Python LSPs

ty is primary; pyright runs only as a fallback. In `LspAttach`
(`plugins/lsp.lua`) pyright keeps just `callHierarchyProvider` — the one thing
ty lacks — whenever `ty` is on PATH. Do not "fix" the stripped capabilities;
running both unfiltered duplicates completion, hover and references.

---

## Machine-local modules

`lua/custom/local/` is **gitignored** and auto-loaded (README describes how).
It holds pickers and helpers wrapping employer-internal or otherwise private
tooling. Therefore:

- **Never reference `custom.local.*` unconditionally.** Always `pcall`.
- Never move code out of `local/` into a tracked file, and never name internal
  tooling, hostnames, or project names in tracked files.
- Files there may exist on disk but not in git. Do not "clean up" references to
  them as dead code.

Secrets in `.http` work: keep them in `http-client.private.env.json` and
gitignore it. `http-client.env.json` is shared with the team and safe to track.

---

## House style

This config is commented far more heavily than most, on purpose. Match it.

- **Comments explain _why_, not what.** A comment restating the code is noise;
  a comment recording the constraint that forced the code is the point.
- **Document removals in place, briefly.** When something is deleted because
  it was wrong, leave a one- or two-line note saying what it was and why it
  went, so nobody re-adds it — e.g. the no-op `<leader>or` "reload config"
  mapping, or the `client:supports_method()` gate that "bought nothing" for
  jdtls. The full story belongs in the commit message, not the comment.
- **Explain a thing once.** Keep the rationale next to the code it constrains
  and point to it from elsewhere, instead of repeating it in README, here and
  several comments.
- Record the *trade-off* when a decision has one, not just the choice.
- Prefer deleting a thing that doesn't earn its place over configuring around it.

---

## Working here

- Read `lua/custom/keymaps.lua`'s header comment before touching any mapping.
  It is the single densest source of constraint in the repo.
- Changing `init.lua`'s require order is almost never right — `options`,
  `keymaps`, `autocmds`, `lazy`, `helpers`, `checks`, `review`, `statusline`,
  in that order. Appending a
  new module at the end is fine; reordering the existing ones is not.
- A non-plugin subsystem gets its own `lua/custom/*.lua` module and registers
  its own mappings there (`helpers.lua`, `checks.lua`). `keymaps.lua` is for
  mappings, not for logic that happens to be bound to a key.
- `checks.lua` must not depend on any AI/agent plugin. It exports
  `qflist_as_text()` and consumers call in, so swapping agent plugins never
  touches it. Adding a language means adding a `marker` / `cmd` / `efm` row —
  and a language only earns a row if its check emits parseable positions.
- `lazy-lock.json` is committed. Do not hand-edit it; let `:Lazy` write it.
- There is no test suite, and a headless Neovim will not exercise most of this.
  Real verification is opening a file of the affected filetype and checking
  `:checkhealth`, `:Lazy`, `:ConformInfo`, `:LspInfo`. A syntax-only check is
  `nvim --headless -c 'luafile <file>' -c 'qa'` — useful, but not proof the
  change works. Say which one you did rather than claiming a change is
  verified when it isn't.
- Plugin setup cannot be re-run by re-requiring a module. The honest answer to
  "reload the config" is to restart Neovim.
