# nvim-config

Personal Neovim configuration. Java/Spring work is the main target (see
[Java](#java), which carries most of the non-obvious setup), alongside
TypeScript, Python, Lua and Rust.

## Requirements

| | |
|---|---|
| Neovim | **0.12+** — required by nvim-treesitter `main` and kulala.nvim |
| `tree-sitter-cli` | **0.26.1+**, from a system package manager (`brew install tree-sitter`) — *not* the npm build |
| C compiler | parser compilation |
| `curl`, `git`, `tar` | parser and kulala-core downloads |
| Java | Corretto 21 in `~/Library/Java/JavaVirtualMachines/` for the jdtls compile target |
| Nerd Font | icons throughout |

External tools expected on `PATH`: `rg` (Telescope grep) and `prettier`
(resolved per-project by conform).

## Layout

```
init.lua                     leaders, then requires the modules below
lua/custom/
  options.lua                editor settings
  keymaps.lua                keymap scheme + all non-plugin mappings
  autocmds.lua               yank highlight, transparent background
  helpers.lua                RouterOS/MikroTik deploy
  lazy.lua                   bootstrap + plugin spec import
  plugins/*.lua              one file per plugin
  telescope/*.lua            custom pickers
  local/*.lua                machine-local, gitignored (see below)
after/ftplugin/
  java.lua                   jdtls startup (see Java)
  lua.lua                    2-space indent
```

## Keymaps

Two prefixes, split by **scope** — what a mapping reaches, not what it does.
The authoritative version of this lives at the top of `lua/custom/keymaps.lua`.

- **`<leader>` (`,`)** — global. Reaches outside the current buffer.
- **`<space>`** — this buffer, or the symbol under the cursor.
- **`<localleader>`** — also `<space>`, deliberately: it is the same idea
  narrowed to specific filetypes.

A `<space>` mapping may exist in one filetype and not another. That is correct:
the LSP mappings are registered buffer-locally on `LspAttach`, so they are
absent where no server is attached. The trade-off is that a buffer-local
mapping silently shadows a global one on the same keys — new `<localleader>`
mappings must avoid the suffixes already taken globally (`<space>`, `a`, `d`,
`D`, `e`, `f`, `o`, `q`, `v`).

### Global — `<leader>`

| Key | Action |
|---|---|
| `<leader>f` | File manager (oil) |
| `<leader>u` | Undotree |
| `<leader>sf` / `<leader>sp` | Find files / git files |
| `<leader>sg` / `<leader>ss` | Live grep / grep word under cursor |
| `<leader>sl` / `<leader>sh` | Recent files / help tags |
| `<leader>s?` | Search this config |
| `<leader>sw` / `<leader>sW` | Symbols: project sources / including jars |
| `<leader>gs` `gd` `gc` `gb` `gm` | Fugitive: status, diff, commit, blame, mergetool |
| `<leader>gj` / `<leader>gf` | Merge conflict: take theirs / ours |
| `<leader>gp` `gr` `gB` `gt` | gitsigns: preview, reset, blame line, inline blame |
| `]c` / `[c` | Next / previous hunk |
| `<leader>R*` | REST client (kulala) — `Rs` send, `Ra` send all, `Re` env |
| `<leader>cT` | TypeScript project check (`tsc` → Trouble) |
| `<leader>?` | Buffer-local keymaps (which-key) |

### This buffer — `<space>`

| Key | Action | Scope |
|---|---|---|
| `<space><space>` | Buffer switcher | global |
| `<space>f` | Format (conform) | global |
| `<space>e` / `<space>q` | Diagnostic float / loclist | global |
| `<space>d` / `<space>D` | Diagnostics: buffer / workspace | global |
| `<space>ar` / `<space>aa` | Rename / code actions (`aa` also visual) | LSP only |
| `<space>vr` `vi` `vd` `vD` | References, implementations, definition, declaration | LSP only |
| `<space>vc` / `<space>vC` | Incoming / outgoing calls | LSP only |
| `<space>o` | Document outline | LSP only |
| `gd` | Goto definition | LSP only |
| `<localleader>m` | Deploy RouterOS script | `.rsc` only |

Other: `<C-h/j/k/l>` window navigation, `<leader>w` proxies `<C-w>`, `<Esc>`
clears search highlight, `<Esc><Esc>` leaves terminal mode.

## Plugins

**Editor** — [snacks.nvim](https://github.com/folke/snacks.nvim) (bigfile,
dashboard, input, picker, quickfile, scroll, statuscolumn, words),
[oil.nvim](https://github.com/stevearc/oil.nvim),
[which-key.nvim](https://github.com/folke/which-key.nvim),
[noice.nvim](https://github.com/folke/noice.nvim),
[nvim-surround](https://github.com/kylechui/nvim-surround),
[undotree](https://github.com/mbbill/undotree),
[catppuccin](https://github.com/catppuccin/nvim) (frappe, transparent).

**Finding** — [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
with fzf-native, plus two local pickers in `lua/custom/telescope/`:
`java_symbols.lua` (see [Java](#java)) and `kep_pipelines.lua`.

**LSP & completion** —
[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig),
[mason.nvim](https://github.com/williamboman/mason.nvim),
[nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls),
[nvim-cmp](https://github.com/hrsh7th/nvim-cmp) + LuaSnip,
[lazydev.nvim](https://github.com/folke/lazydev.nvim),
[trouble.nvim](https://github.com/folke/trouble.nvim),
[conform.nvim](https://github.com/stevearc/conform.nvim).

Servers: `lua_ls`, `pyright` + `ruff` + `ty`, `ts_ls` + `eslint`, `bashls`,
`rust_analyzer`, and `jdtls` (started separately — see below).

**Git** — [vim-fugitive](https://github.com/tpope/vim-fugitive) for repo-level,
[gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) for hunk-level.

**Other** — [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
(`main` branch), [kulala.nvim](https://github.com/mistweaverco/kulala.nvim).

## Java

`jdtls` does not start via `vim.lsp.enable()` like the other servers. It keeps a
stateful compiled project model in a workspace directory, one per project root,
which a single global client cannot express — so it is started per-buffer from
`after/ftplugin/java.lua` via `nvim-jdtls`'s `start_or_attach`.

That file also handles three things that are easy to get wrong:

- **Compile target.** `java` on `PATH` is Corretto 25, but the project targets
  21. jdtls runs on 25 and compiles against 21 only because it is told to.
- **Lombok.** jdtls runs its own compiler and needs the Lombok javaagent, or
  generated accessors and constructors do not exist as far as the editor is
  concerned. The version is read from `build.gradle` and located in the Gradle
  cache, because Mason's bundled jar is usually older and the skew produces
  errors that do not reproduce in a Gradle build.
- **Completion capabilities.** `start_or_attach` bypasses `vim.lsp.config`, so
  the cmp capabilities set globally in `plugins/cmp.lua` have to be passed
  explicitly here.

**Symbol search is split in two.** nvim-jdtls advertises
`classFileContentsSupport`, which is what lets `gd` decompile into library
source — but it also makes `workspace/symbol` return symbols from every jar on
the classpath. On a large project that is slow enough to be unusable in a
picker that re-queries per keystroke. Rather than disable the flag and lose
decompiling, `lua/custom/telescope/java_symbols.lua` splits at the query level:

- `<leader>sw` — `java/searchSymbols` with `sourceOnly`, project sources, fast.
- `<leader>sW` — plain `workspace/symbol`, jars included, marked with `󰏗`.

Deleting `~/.cache/nvim/jdtls-workspace/<project>` is the standard fix for a
confused jdtls.

## HTTP files

`.http` files in the JetBrains HTTP Client format are handled by kulala, which
reads `http-client.env.json` and `http-client.private.env.json` directly — so
the same files work for anyone on the team running them from IntelliJ.

Keep secrets in `http-client.private.env.json` and gitignore it.

## Machine-local modules

`lua/custom/local/` is gitignored. Any `*.lua` in it that returns a table with a
`setup()` function is required and set up automatically by
`plugins/telescope.lua`, after Telescope itself is configured. Failures are
reported with `vim.notify` rather than aborting startup.

That is where pickers and helpers wrapping employer-internal or otherwise
private tooling live, so they work on the machine without ending up in a public
repo.

```lua
-- lua/custom/local/example.lua
local M = {}
function M.setup()
  vim.keymap.set('n', '<leader>sx', function() ... end, { desc = 'Example' })
end
return M
```

## Gotchas

- **nvim-treesitter is on `main`**, a full rewrite. `ensure_installed`,
  `auto_install` and `sync_install` do not exist, and highlighting is not
  automatic: parsers are listed in `plugins/treesitter.lua` and highlighting is
  started per filetype by an autocmd there. Adding a language means adding it
  to *both* lists — they differ where parser name and filetype differ
  (`vimdoc`/`help`, `bash`/`sh`), and `markdown_inline` has no filetype at all.
- **`tree-sitter-cli` must come from a package manager**, not npm.
- **`<localleader>` is `<space>`**, so buffer-local mappings can shadow global
  ones silently. See the list in `keymaps.lua`.
- **Markdown treesitter** is enabled; LSP hover windows are markdown buffers
  rendered through treesitter by noice, so the `markdown` and `markdown_inline`
  parsers are what colour `K` output.
