# Session handoff — AI-assisted workflow review

**Date:** 2026-09-15 · **Repo:** `~/.config/nvim` · **Companion:** `docs/ai-harness.html` (17-slide deck)

Attach or paste this into a fresh session to continue. It carries the decisions
and their reasons, so the reasoning doesn't have to be rebuilt. Config
*constraints* are in `CLAUDE.md` and are not repeated here.

---

## What was asked

Three things: explain what an "AI harness" is, brainstorm how to improve this
Neovim config for AI-assisted work, and present it. Audience is Mateusz alone,
so recommendations are config-specific rather than general.

---

## The concept, compressed

A model is a pure function — tokens in, tokens out, stateless, no hands. The
**harness** is the software around it that turns it into an agent: tool
dispatch, context assembly, permission gates, control flow, persistence.

Useful sub-distinction: the **scaffold** is how the agent is assembled *before*
the first prompt (tool definitions, system prompt, what's mounted); the
**harness** is everything *after* (dispatching, compacting, enforcing
invariants, persisting). Different failure modes, different fixes.

The loop: `assemble context → model decides one action → gate & dispatch → run
tool → fold result back in → repeat`. The model owns exactly one of those five
boxes. The other four are ordinary software.

Five layers every harness answers, deliberately or not:

| Layer | Question | In a coding agent |
|---|---|---|
| Tool | How does it touch the world? | read/write/edit, bash, grep, MCP, LSP |
| Context | What does it get to see? | system prompt, `CLAUDE.md`, file reads, diagnostics, git diff |
| Permission | What is it allowed to do? | allow/deny rules, sandboxes, approval prompts |
| Control | What when it runs long or wrong? | compaction, subagents, timeouts, interrupt |
| Persistence | What survives the session? | transcripts, memory files, worktrees, branches |

**The model sets the ceiling; the harness decides how close you get.** The
ceiling isn't movable. The gap is.

Consequence for editors: the harness moved *out* of the editor and into CLI
agents, because the harness is the product and ships on its own cycle. So the
editor is now a peripheral — context provider, review surface, verification
runner. "Which nvim AI plugin?" is the wrong first question.

Three architectures, not competitors but different layers:

- **A — inline completion** (`copilot.lua`, `supermaven`, `minuet-ai`). No loop,
  no tools, no agency. *Decision: skip.* Never had it, hasn't been missed.
- **B — in-editor agent** (`codecompanion.nvim`, `avante.nvim`). Loop lives in
  nvim. Buffer/LSP context free; you own providers and keys.
- **C — attached CLI agent** (`sidekick.nvim`, `coder/claudecode.nvim`,
  `agentic.nvim` via ACP, or plain tmux). Loop lives in the CLI, nvim sends
  context and reviews diffs.

Both B and C need `snacks.nvim`, which this config already loads eagerly.

---

## Starting state (audit)

34 plugins in `lazy-lock.json`, **zero** AI-related. Java/Spring primary;
TS/Python/Lua/Rust secondary. Neovim 0.12+.

Strong already: `snacks.nvim` eager · trouble + quickfix as a structured-error
surface · conform with project-style gating (format-on-save can't rewrite files
an agent touched — this is load-bearing and should not be "fixed") · jdtls call
hierarchy · a documented keymap scheme with an actual rule · gitignored
`lua/custom/local/` · fugitive + gitsigns.

Missing at the start: any AI integration · external-change reload · an agent
keymap namespace · a `CLAUDE.md` · a generalised check verb · worktree workflow
and session persistence.

Layer scorecard then: Tool strong, Context strong primitives but unwired,
Permission/Control nothing, Persistence git only.

---

## Decisions made, and why

1. **`<leader>a` is the agent namespace.** The config's own scope rule decides
   it: `<leader>` (`,`) reaches outside the buffer, `<space>` acts on this
   buffer. An agent reaches the whole repo, a subprocess and the network.
   `<leader>a` was free.
2. **`CLAUDE.md` holds constraints, not history.** This config's reasoning lives
   in unusually dense comments, which an agent can't see in files it hasn't
   opened. The invariants were hoisted; session notes deliberately kept out of
   it (that's what this file is for).
3. **Checks got their own module, not `keymaps.lua`.** A lookup table plus a job
   pipeline is a subsystem. `helpers.lua` is the precedent.
4. **The quickfix serialiser lives in `checks.lua`, not an agent plugin spec.**
   So `checks.lua` has zero dependency on any AI plugin and survives swapping
   B for C.
5. **The marker walk is duplicated from `conform.lua`, not extracted.** Two call
   sites asking different questions ("does this project declare a style?" vs
   "what kind of project is this?"); the shared part is one `vim.fs.root` call.
   Revisit at a third call site.
6. **No `lua` row in the checks table.** `stylua --check` emits a diff with no
   positions — nothing for `errorformat` to parse. Also: this repo declares no
   formatter config, so stylua must not be run over it at all.

---

## What is built

**`lua/custom/autocmds.lua`** — *(Mateusz applied this during the session)*
`autoread` plus `checktime` on FocusGained/BufEnter/CursorHold/TermClose/
TermLeave, and a `FileChangedShellPost` notification. Without it an agent's
write leaves a stale buffer and `:w` silently clobbers it. Note `undofile`
does **not** help: external writes never enter the undo tree, so git is the
only undo — hence commit *before* delegating, not after.

**`CLAUDE.md`** (new, ~270 lines) — version floor, layout, keymap scheme with
taken-suffix lists, formatting policy with its reason, treesitter `main`
two-list rule, the four jdtls breakables, `lua/custom/local/` rules, house
style (comments explain *why*; removals documented in place — do not tidy those
notes away).

**`lua/custom/checks.lua`** (new) — per-filetype `marker` / `cmd` / `efm` table
→ `vim.system` → `setqflist` → Trouble. Owns `<leader>cc` (run) and
`<leader>cy` (copy quickfix as text to `+`). Exports `qflist_as_text()`.
Java and TypeScript rows only.

Two fixes over the old `<leader>cT`, both deliberate:
- **stderr is merged in.** The old version hooked only `on_stdout`, which works
  for tsc but javac writes diagnostics to stderr — a failing Gradle build would
  have reported clean.
- **exit code checked separately from entry count.** A build fails for reasons
  `efm` never matches (wrong JDK, missing task, no network); an empty list
  reading as success is the worst outcome.

**`init.lua`** — `require 'custom.checks'` appended after `helpers`.

**`lua/custom/keymaps.lua`** — `<leader>cT` removed, replaced with an in-place
removal note per house style. No alias; `<leader>cc` covers it.

**`docs/ai-harness.html`** — the deck. Not config; don't lint or refactor it.

---

## Not built, in priority order

1. **Fill in `<leader>a`.** The group label `{ '<leader>a', group = 'Agent' }`
   is already declared in `plugins/whichkey.lua` — but with **no mappings behind
   it**, which violates this repo's own rule ("never declare a which-key group
   with no mappings behind it", `CLAUDE.md`). Two ways out: add the mappings, or
   move the group declaration into the agent plugin's spec so it appears and
   disappears with the plugin — `kulala.lua` does exactly that for `<leader>R`,
   and that is the better shape.
   Planned tree: `aa` toggle · `as` send selection · `af` send file ref ·
   `ad` send diagnostics (calls `checks.qflist_as_text()`) · `ag` send git diff ·
   `ap` prompt picker · `aw` worktree switcher · `ax` interrupt.
2. **Pick one of B or C and live with it two weeks** before judging. This is the
   open decision below.
3. **`<leader>ad`** — the agent-side consumer. Serialiser already exists;
   `<leader>cy` is the clipboard stand-in until a plugin owns the key, and
   should be deleted once it does.
4. **tmux/zellij session persistence** so agent runs outlive nvim restarts.
5. **Git worktrees**, one agent per worktree, with a `<leader>aw` switcher.
6. **Session-transcript telescope picker** — `telescope/java_symbols.lua` is the
   precedent for a custom picker.
7. **Per-repo permission policy** — generalise `conform.lua`'s "does this
   project declare a style?" pattern to "what may an agent do here?", with
   overrides in gitignored `lua/custom/local/`.
8. **LSP-as-MCP** — hover/definition/references/call-hierarchy over the wire.
   Real value, real project; flagged as probably-not-yours-to-build.

Also brainstormed as genuinely worth doing: **jdtls incoming-call hierarchy as
a context tool** (`<space>vc` answers "how does execution reach here" better
and cheaper than any grep an agent will run), and **kulala as the verification
step** (`.http` files are executable specs — agent edits the endpoint,
`<leader>Rs` verifies, real response goes back as context).

---

## Open decisions needing input

- **B or C?** CodeCompanion was the more stable bet as of mid-2026 and fits the
  nvim philosophy; sidekick/claudecode suit the current terminal-first habit.
  No decision was made.
- **`CLAUDE.md` says "nvim-cmp, not blink.cmp — do not migrate without being
  asked."** Remove that line if the migration is actually open; as written it
  will shut down the suggestion.
- **The taken-`<leader>` list in `CLAUDE.md` goes stale** the moment
  `<leader>a` is claimed. That's the line to update.

---

## Verification debt

`checks.lua` has **not been run.** Block and delimiter balance were checked
structurally and the API calls reviewed by hand; no Lua interpreter or Neovim
was available. Open a Java or TypeScript buffer and press `<leader>cc`.
`:checkhealth` and `:ConformInfo` do not exercise this path.

Unrelated: `after/ftplugin/java.lua`, `conform.lua` and `whichkey.lua` had
uncommitted changes from before this session. Untracked `.DS_Store` may want a
gitignore entry.

---

## Anti-patterns worth carrying forward

- Installing several AI plugins to compare them — you compare installers, not
  workflows. Two weeks of one beats two days of three.
- Treating inline completion and agents as one category.
- Weakening the conform gating so format-on-save always runs.
- Auto-approving everything. Reduce friction by narrowing scope, not by
  removing the gate.
- More context is not better context. Ten lines of real diagnostics beat a
  thousand lines of repo dump, and the dump crowds out what matters.

---

## Sources

Concept — [Databricks: What is an AI Agent Harness?](https://www.databricks.com/blog/ai-harness) ·
[DataNorth: Harness Engineering guide](https://datanorth.ai/blog/harness-engineering-the-complete-guide-to-ai-agent-scaffolding) ·
[Hugging Face: agent glossary](https://huggingface.co/blog/agent-glossary) ·
[arXiv 2603.05344: terminal coding agents](https://arxiv.org/html/2603.05344v1) ·
[awesome-harness-engineering](https://github.com/ai-boost/awesome-harness-engineering)

Plugins — [coder/claudecode.nvim](https://github.com/coder/claudecode.nvim) ·
[CodeCompanion vs Avante (maintainer)](https://github.com/olimorris/codecompanion.nvim/discussions/1209) ·
[avante vs CodeCompanion 2026](https://samuellawrentz.com/blog/neovim-ai-plugins-avante-codecompanion/) ·
[agentic.nvim (ACP)](https://github.com/carlos-algms/agentic.nvim) ·
[send-to-agent.nvim](https://github.com/code-inflation/send-to-agent.nvim)

Workflow — [Claude Code in tmux](https://tmux.app/doc/claude-code-tmux/) ·
[Terminal-first AI workflow](https://www.fedeminaya.com/blog/my-terminal-first-ai-workflow)

Plugin landscape verified September 2026; it moves fast. The five-layer frame
will outlast every name above.
