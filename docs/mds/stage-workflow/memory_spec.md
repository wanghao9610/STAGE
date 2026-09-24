# Project Memory

Where a session records what it learned, and how that reaches the next one. The rule that decides *whether* to record: offer, never assume — at most two offers per session, written only after the user agrees, `INVOLVE=low` recording unasked and saying so; a fact a repository file already owns goes there (`AGENTS.md` §10 where present). This file is the format both halves of that rule stand on: what the store holds, what one memory looks like, and what the session hooks parse.

## What belongs here

One test, and it is exclusive: **a fact belongs in memory only when no file in the repository already owns it.** A number belongs to a fingerprinted `mates/` entry, a claim to `notes/claims.md`, a page limit or a deadline to the cycle's `venue.yml`, what a cited paper says to `notes/refs/`, a promise made to reviewers to `tasks/<cycle>_promises.md`, a venue follow-up to `tasks/<cycle>_venue.md`. Memory is the residue — what stays true across runs and is owned by nothing. Without that test the store becomes a second answer to questions the ledger and the notes already answer, and the two drift apart.

The exclusivity cuts hardest against the fabrication boundary (conventions §9): **a memory is never a source for a number, a venue rule, or an assertion about a cited work.** Those have their own homes precisely because they must be checkable, and a recalled value is unsourced no matter which file recalls it.

| Type | What it holds | Example |
|---|---|---|
| `env` | a fact about a machine or a TeX toolchain, usually learned by failing | this machine's TeX Live has no `newtxtext`; `stage.cls` builds here only under `LATEX_ENGINE=xelatex` |
| `pref` | a standing preference of the user's about how the writing is done | drafts arrive one section at a time and stop for review; never a batch |
| `insight` | a judgment that outlived the run that produced it | the upstream `results.md` renumbers its rows on every rerun, so a `% src:` anchor must name the table id, never a row index |
| `deadend` | something tried, rejected, and not worth retrying, with what it cost | framing the contribution as a new benchmark; the simulated panel read it as incremental, and a full intro rewrite came back to the method framing |

`deadend` is the type a paper repository needs most and the one a general-purpose memory has no room for: between cycles, the expensive knowledge is which framing, cut, or layout was already tried and did not survive.

## Where it lives

```text
.stage/memory/
├── .gitkeep           # what the template tracks here; the memories are yours
├── <slug>.md          # one memory per file
└── local/             # git-ignored: what stays on this machine
    └── <slug>.md
```

`.stage/memory/` is versioned, so a memory outlives the machine that recorded it and travels with a clone. `local/` is ignored the way `.env` is and holds what stays behind: a `machine:` scoped fact — a path, a font, a missing LaTeX package, or an engine quirk true here and false on the next machine — and any memory the user keeps off the repository, whatever its scope. Every other scope — `global`, `cycle:`, `manus:` — holds on any clone and goes to the versioned store; the split is by where a fact travels, not by where it holds.

## The memory file

One fact per file, named for its slug:

```markdown
---
type: env
scope: machine:mbp-a
summary: stage.cls builds here only under xelatex
language: en
verified: 2026-08-03
model_id: claude-opus-5[1m]
source: wkdrs/builds/main.log
---

`stage.cls` builds on this machine only under `LATEX_ENGINE=xelatex`.

**Why:** the TeX Live install here ships no `newtxtext`, and pdflatex halts in the preamble.
**How to apply:** set the engine in `.env`, not on the command line — every skill builds through `execs/run.sh`.
```

| Field | What it is |
|---|---|
| `type` | one of the four above; `env` is the only one the hooks age |
| `scope` | `global`, `machine:<name>`, `cycle:<cycle>`, or `manus:<path>` — where the fact is true, not where it was learned |
| `summary` | the one line the index shows for it: what the fact *is*, not what it is about — "stage.cls builds here only under xelatex", not "notes on the build engine" |
| `language` | the body's language (conventions §7.6, the reply-language rule); frontmatter keys stay English |
| `verified` | the date the fact was last confirmed true, from the system clock (conventions §4, real dates) |
| `model_id` | the model that wrote or last re-verified it, verbatim (conventions §8, the output table; fallbacks in `model_id_spec.md`) |
| `source` | the artifact the fact came out of, or `conversation` |
| `supersedes` | optional: the slug this memory replaces |

The body opens with one sentence stating the fact, then carries only what a reader needs to act on it. A memory carries no history of its own, and no `model_trail`: a re-verification rewrites `verified` and `model_id` rather than appending, and what the file used to say is in git. Conventions §8 asks for a trail where several sessions each write a different part of one artifact, which is not what happens to a file this small.

**The language rule applies to the body only.** `STAGE_LANG` governs what a run writes (conventions §7.6), so a Chinese session records a Chinese body — and every frontmatter key, every value in the table above (`summary` included), and the `<type>` token in the index line stay English: that same section keeps frontmatter keys and their values English as structural literals, and the hooks read the keys and the `env` token literally.

## The index line

Nothing is hand-written: the session hook reads every `<slug>.md` in the two directories and builds one line per memory from its frontmatter, newest `verified` first:

    - <type> · <scope> · <verified> · [<slug>](<slug>.md) — <summary>
    - env · machine:mbp-a · 2026-08-03 · [xelatex-only](xelatex-only.md) — stage.cls builds here only under xelatex

Writing a memory is therefore writing one file, and re-verifying one is editing one field. The hook reads the frontmatter literally: a file whose frontmatter is not closed by a second `---` is not listed; the aging check matches the type token `env` as written — English, like the summary, whatever language the body speaks; and a file without `summary` is listed by its first body line, the sentence the body opens with anyway, so a memory written before the field existed still reaches the session.

That one line is what a session judges relevance on, so it says what the fact *is*, not what it is about. Keep the store under roughly 60 memories; past that, retire rather than group — there is no index file to add headings to, and every line reaches every session.

## Retiring a memory

Three ways out, and the first is the common one:

- **Re-verified** — the fact still holds: set `verified` to today and `model_id` to the model that checked it; the index line follows on its own.
- **Superseded** — the fact changed: write the new memory with `supersedes: <old-slug>`, then delete the old file. Git holds the history, and nothing is archived inside the store — that is what keeps the index short enough to inject into every session.
- **Wrong** — delete it. A memory that was never true is not history worth keeping.

Deleting a memory is a deletion like any other: it is confirmed with the user at every involve level (conventions §7.7, how much the skills ask).

A cycle is not a retirement event. A `cycle:<cycle>` memory from a submission that has been frozen stays true of that cycle and keeps its scope; what makes it go is being wrong, not being old.

## How it reaches a session

| Runtime | Hook | Event | What it injects |
|---|---|---|---|
| Claude Code | `.claude/hooks/stage_memory.sh` | `SessionStart`, and `SubagentStart` for a delegate | the index, as `additionalContext` |
| Codex | `.codex/hooks/stage_memory.sh` | `SessionStart` | the index, as `additionalContext` |
| Cursor | `.cursor/hooks/stage_memory.sh` | `sessionStart` | the index, as `additional_context` |
| DSH | `.dsh/hooks/stage_memory.sh` | `SessionStart`, through the Claude Code hook bridge | the index, as `additionalContext` |
| Kimi | `.kimi-code/hooks/stage_memory.sh` | `UserPromptSubmit` | the index, once per session |
| Pi | `.pi/extensions/stage-hooks/stage_memory.sh` | `before_agent_start`, wired by `.pi/extensions/stage-hooks/index.ts` | the index, as a hidden message before the first agent run, and again after a model change |
| Qwen Code | `.qwen/hooks/stage_memory.sh` | `SessionStart` | the index, as `additionalContext` |

Each hook prints the index and nothing else — the versioned directory's memories, then `local/`'s where it exists; run any copy with `--list` to see the same lines as plain text. An `env` line whose `verified` is more than 180 days old is marked stale in what the session sees, because a machine changes under a fact recorded about it; the other three types are not aged, since a dead end stays dead and a flag that fires on healthy entries teaches the reader to skip it. A store with no entries prints nothing at all, so a paper that has recorded nothing pays nothing.

A hook that exists is not necessarily registered. Claude, Codex, Cursor and Qwen Code ship theirs registered in `.claude/settings.json`, `.codex/hooks.json`, `.cursor/hooks.json` and `.qwen/settings.json`; Kimi has no project-level config, so `bash .kimi-code/hooks/install.sh` registers it once per machine. DSH is the same shape: `.dsh/hooks.json` is the table, but the row pointing DSH at it belongs in the machine's `$DSH_HOME/cordis.patch.yml`, written once by `bash .dsh/hooks/install.sh` — and the bridge it loads is not a dsh dependency, so each profile needs `dsh plugin --profile <name> add @deepseek-ai/dsh-hooks-claude-code`. Pi's registration is code, not config — the extension is discovered automatically, but only in a trusted project (`/trust`, or `defaultProjectTrust`); untrusted, it loads no project extension and injects nothing. On Codex, registered is still not running until the project is trusted and the hook approved with `/hooks` in the CLI; on Qwen Code, a project-level hook runs only in a trusted folder, which applies only where folder trust is on (`security.folderTrust.enabled`, off by default). A paper repository adopted before this hook existed keeps its own registration file, which `execs/update.sh` never overwrites — it reports the gap instead, and the entry is added by hand.
