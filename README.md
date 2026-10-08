# nvim-config

Personal Neovim configuration. Java/Spring work is the main target (see
[Java](#java)), alongside TypeScript, Python, Lua, Rust and Go.

`CLAUDE.md` holds the invariants and "don't undo this" notes; this file
describes what the config does.

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
(resolved per-project by conform). Mason installs the language servers and
`stylua`. For Go: the Go toolchain (gopls is only installed and enabled when
`go` is on `PATH`) and `goimports` (`:MasonInstall goimports`).

## Layout

```
init.lua                     leaders, then requires the modules below
lua/custom/
  options.lua                editor settings
  keymaps.lua                keymap scheme + all non-plugin mappings
  autocmds.lua               yank highlight, transparent background
  lazy.lua                   bootstrap + plugin spec import
  helpers.lua                RouterOS/MikroTik deploy
  checks.lua                 per-project compile/typecheck -> quickfix -> Trouble
  review.lua                 :PRReview -- branch hunks as a Trouble list
  java.lua                   jdtls config and startup (see Java)
  statusline.lua             default statusline + mode / macro recording
  plugins/*.lua              one file per plugin
  telescope/*.lua            custom pickers
  local/*.lua                machine-local, gitignored (see below)
after/ftplugin/
  java.lua                   indent + starts jdtls via custom/java.lua
  lua.lua                    2-space indent
  go.lua                     tabs (gofmt), no tab markers
snippets/<filetype>.lua      a few LuaSnip snippets the language servers lack
```

## Keymaps

Two prefixes, split by **scope** — what a mapping reaches, not what it does.
The authoritative version lives at the top of `lua/custom/keymaps.lua`.

- **`<leader>` (`,`)** — global. Reaches outside the current buffer.
- **`<space>`** — this buffer, or the symbol under the cursor.
- **`<localleader>`** — also `<space>`, deliberately: the same idea narrowed
  to specific filetypes.

LSP mappings are buffer-local, so they only exist where a server is attached.

### Global — `<leader>`

| Key | Action |
|---|---|
| `<leader>f` | File manager (oil) |
| `<leader>u` | Undotree |
| `<leader>sf` / `<leader>sp` | Find files / git files |
| `<leader>sg` / `<leader>ss` | Live grep / grep word or selection |
| `<leader>sl` / `<leader>sh` / `<leader>sm` | Recent files / help tags / marks |
| `<leader>sr` | Resume last search |
| `<leader>sn` | Search messages and notifications (noice) |
| `<leader>s?` | Search this config |
| `<leader>sw` / `<leader>sW` | Symbols: project sources / including jars |
| `<leader>ha` / `<leader>hh` | Harpoon: pin file / menu |
| `<leader>1`–`4`, `<C-n>` / `<C-p>` | Harpoon: jump to slot / next / previous pinned file |
| `<leader>gs` `gd` `gc` `gb` `gm` | Fugitive: status, diff, commit, blame, mergetool |
| `<leader>gj` / `<leader>gf` | Merge conflict: take theirs / ours |
| `<leader>gh` | File history (Trouble) |
| `<leader>go` | Open file / selection on the git host |
| `<leader>gp` `gx` `gS` `gB` `gt` | gitsigns: preview, reset, stage (hunk or selection), blame line, inline blame |
| `<leader>gq` | All changed hunks in the repo (Trouble) |
| `<leader>gR` / `<leader>gr` | PR review: build hunk list against origin/HEAD / toggle it (Trouble) |
| `<leader>cc` / `<leader>cy` | Check the project (compile / typecheck → Trouble) / copy the quickfix list as text |
| `<leader>R*` | REST client (kulala) — `Rs` send, `Ra` send all, `Re` env, `Rb` scratchpad |
| `<leader>a*` | Claude Code — `<C-f>` open / hide from anywhere, `aa` open / focus, `ac` accept diff, `ad` deny diff, `ar` resume, `aC` continue, `am` model, `ab` add buffer, `as` send selection (add file in oil), `aD` send the quickfix list |
| `<leader>oh` | Toggle inlay hints |
| `<leader>?` | Buffer-local keymaps (which-key) |

### This buffer — `<space>`

| Key | Action | Scope |
|---|---|---|
| `<space><space>` | Buffer switcher | global |
| `<space>f` / `<space>F` | Format / show whether format-on-save applies here | global |
| `<space>e` | Diagnostic float | global |
| `<space>d` / `<space>D` / `<space>q` | Trouble: buffer diagnostics / workspace diagnostics / quickfix list | global |
| `<space>t` | Trouble: focus or close the last view | global |
| `<space>ar` / `<space>aa` | Rename / code actions (`aa` also visual) | LSP only |
| `<space>vr` `vi` `vd` `vD` | References, implementations, definition, declaration | LSP only |
| `<space>vc` / `<space>vC` | Incoming / outgoing calls | LSP only |
| `<space>o` | Document outline | LSP only |
| `gd` | Goto definition | LSP only |
| `<space>ao` / `<space>ae` + `v` `c` `m` | Organize imports / extract variable, constant, method | Java only |
| `<localleader>m` | Deploy RouterOS script | `.rsc` only |

### Other

| Key | Action |
|---|---|
| `<C-h/j/k/l>` | Window navigation (`<leader>w` proxies `<C-w>`) |
| `]c` / `[c` | Next / previous git hunk |
| `ih` | Hunk text object (`dih`, `yih`, `vih`) |
| `]]` / `[[` | Next / previous reference to the word under the cursor |
| `\` | Repeat `f`/`t` backwards (`,` is the leader) |
| `<C-l>` / `<C-h>` | Insert mode: next / previous snippet placeholder |
| `<Esc>` | Clear search highlight |

In oil, split / refresh / preview are `<C-s>` (vertical), `<C-x>`
(horizontal), `gR`, `gp`. In kulala's response pane, `<Tab>` / `<S-Tab>`
switch views.

## Plugins

**Editor** — [snacks.nvim](https://github.com/folke/snacks.nvim) (bigfile,
dashboard, input, picker, quickfile, rename, scroll, statuscolumn, words),
[oil.nvim](https://github.com/stevearc/oil.nvim),
[harpoon](https://github.com/ThePrimeagen/harpoon) (v2),
[which-key.nvim](https://github.com/folke/which-key.nvim),
[noice.nvim](https://github.com/folke/noice.nvim),
[nvim-surround](https://github.com/kylechui/nvim-surround),
[undotree](https://github.com/mbbill/undotree),
[render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim),
[catppuccin](https://github.com/catppuccin/nvim) (frappe, transparent).

**Finding** — [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
with fzf-native, plus a local picker in `lua/custom/telescope/`:
`java_symbols.lua` (see [Java](#java)).

**LSP & completion** —
[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig),
[mason.nvim](https://github.com/williamboman/mason.nvim),
[nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls),
[nvim-cmp](https://github.com/hrsh7th/nvim-cmp) +
[LuaSnip](https://github.com/L3MON4D3/LuaSnip),
[lazydev.nvim](https://github.com/folke/lazydev.nvim),
[trouble.nvim](https://github.com/folke/trouble.nvim),
[conform.nvim](https://github.com/stevearc/conform.nvim).

Servers: `lua_ls`, `ty` + `ruff` (+ `pyright` for call hierarchy only),
`ts_ls` + `eslint`, `bashls`, `rust_analyzer`, `gopls`, and `jdtls` (started
separately — see below).

**AI** — [claudecode.nvim](https://github.com/coder/claudecode.nvim) with the
snacks provider as a floating window (`<C-f>` opens and hides it).

**Git** — [vim-fugitive](https://github.com/tpope/vim-fugitive) for repo-level,
[gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) for hunk-level.

**Other** — [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
(`main` branch), [kulala.nvim](https://github.com/dont-be-evil-company/kulala.nvim).

## Formatting

Format-on-save only happens when the project declares a style: a
`.prettierrc`, an Eclipse formatter profile, `stylua.toml`, `rustfmt.toml`,
ruff config, or a Go module. Without one, saving never rewrites the file.
`<space>f` always formats; `<space>F` says whether on-save applies.

## Java

jdtls is started by nvim-jdtls rather than `vim.lsp.enable()`, one server per
Gradle project — also at launch when nvim opens in a directory with a
`settings.gradle`, so the project import runs while you pick a file. The
config (`lua/custom/java.lua`) compiles against Corretto 21, loads the
project's own Lombok version, and uses the project's Eclipse formatter profile
when there is one.

Symbol search is split: `<leader>sw` searches project sources only (fast),
`<leader>sW` includes every jar on the classpath (slow, marked `󰏗`).

Deleting `~/.cache/nvim/jdtls-workspace/<project>` is the standard fix for a
confused jdtls.

## HTTP files

`.http` files in the JetBrains HTTP Client format are handled by kulala, which
reads `http-client.env.json` and `http-client.private.env.json` directly — so
the same files work for anyone on the team running them from IntelliJ.

Keep secrets in `http-client.private.env.json` and gitignore it.

## Machine-local modules

`lua/custom/local/` is gitignored. Any `*.lua` in it that returns a table with
a `setup()` function is required and set up automatically by
`plugins/telescope.lua`. That is where pickers and helpers wrapping private
tooling live, so they work on the machine without ending up in a public repo.

```lua
-- lua/custom/local/example.lua
local M = {}
function M.setup()
  vim.keymap.set('n', '<leader>sx', function() ... end, { desc = 'Example' })
end
return M
```

## Gotchas

- **nvim-treesitter is on `main`**, a full rewrite: parsers and highlighted
  filetypes are two separate lists in `plugins/treesitter.lua`. See `CLAUDE.md`.
- **`tree-sitter-cli` must come from a package manager**, not npm.
- **`<localleader>` is `<space>`**, so buffer-local mappings can shadow global
  ones silently. See the list in `keymaps.lua`.
