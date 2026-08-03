# Project Memory

**Language:** English | [简体中文](memory_spec.zh-CN.md)

Where a session records what it learned, and how that reaches the next one. The rule that decides *whether* to record — offer, never assume; the repository's own files come first — is `AGENTS.md` §10 and is not repeated here. This file is the format both halves of that rule stand on: what the store holds, what one memory looks like, and what the session hooks parse.

## What belongs here

One test, and it is exclusive: **a fact belongs in memory only when no file in the repository already owns it.** A number belongs to a fingerprinted `mates/` entry, a claim to `notes/claims.md`, a page limit or a deadline to the cycle's `venue.yml`, what a cited paper says to `notes/refs/`, a promise made to reviewers to `tasks/<cycle>_promises.md`, a venue follow-up to `tasks/<cycle>_venue.md`. Memory is the residue — what stays true across runs and is owned by nothing. Without that test the store becomes a second answer to questions the ledger and the notes already answer, and the two drift apart.

The exclusivity cuts hardest against the fabrication boundary (conventions §9): **a memory is never a source for a number, a venue rule, or an assertion about a cited work.** Those have their own homes precisely because they must be checkable, and a recalled value is unsourced no matter which file recalls it.

| Type | What it holds | Example |
|---|---|---|
| `env` | a fact about a machine or a TeX toolchain, usually learned by failing | this machine's TeX Live has no `newtxtext`; `arxiv.cls` builds here only under `LATEX_ENGINE=xelatex` |
| `pref` | a standing preference of the user's about how the writing is done | drafts arrive one section at a time and stop for review; never a batch |
| `insight` | a judgment that outlived the run that produced it | the upstream `results.md` renumbers its rows on every rerun, so a `% src:` anchor must name the table id, never a row index |
| `deadend` | something tried, rejected, and not worth retrying, with what it cost | framing the contribution as a new benchmark; the simulated panel read it as incremental, and a full intro rewrite came back to the method framing |

`deadend` is the type a paper repository needs most and the one a general-purpose memory has no room for: between cycles, the expensive knowledge is which framing, cut, or layout was already tried and did not survive.

## Where it lives

```text
.stage/memory/
├── MEMORY.md          # the index: one line per memory
├── <slug>.md          # one memory per file
└── local/             # machine-specific memories, git-ignored
    ├── MEMORY.md
    └── <slug>.md
```

`.stage/memory/` is versioned, so a memory outlives the machine that recorded it and travels with a clone. `local/` is ignored the way `.env` is: a path, a font, a missing LaTeX package, or an engine quirk that is true here and false on the next machine belongs there. Where such a fact is worth carrying anyway, the alternative is a shared memory whose `scope` names the machine it holds on.

## The memory file

One fact per file, named for its slug:

```markdown
---
type: env
scope: machine:mbp-a
language: en
verified: 2026-08-03
source: wkdrs/builds/main.log
---

`arxiv.cls` builds on this machine only under `LATEX_ENGINE=xelatex`.

**Why:** the TeX Live install here ships no `newtxtext`, and pdflatex halts in the preamble.
**How to apply:** set the engine in `.env`, not on the command line — every skill builds through `execs/run.sh`.
```

| Field | What it is |
|---|---|
| `type` | one of the four above; `env` is the only one the hooks age |
| `scope` | `global`, `machine:<name>`, `cycle:<cycle>`, or `manus:<path>` — where the fact is true, not where it was learned |
| `language` | the body's language (conventions §7.6, the reply-language rule); frontmatter keys stay English |
| `verified` | the date the fact was last confirmed true, from the system clock (conventions §4, real dates) |
| `source` | the artifact the fact came out of, or `conversation` |
| `supersedes` | optional: the slug this memory replaces |

The body opens with one sentence stating the fact, then carries only what a reader needs in order to act on it. A memory carries no history of its own: a re-verification rewrites `verified` rather than appending, and what the file used to say is in git.

**The language rule applies to the body only.** `STAGE_LANG` governs what a run writes (conventions §7.6), so a Chinese session records a Chinese body — and every frontmatter key, every value in the table above, and the `<type>` token in the index line stay English, because the hooks and this spec match them byte-exactly.

## The index line

`MEMORY.md` lists every memory beside it, one line each, newest first:

    - <type> · <scope> · <verified> · [<slug>](<slug>.md) — <one line>
    - env · machine:mbp-a · 2026-08-03 · [xelatex-only](xelatex-only.md) — arxiv.cls builds here only under xelatex

The first four fields are separated by a space, a middle dot, and a space; everything after the em dash is free text and may contain anything, that separator included. **The session hooks split on it byte-exactly** — reword the separator and they silently stop marking anything, with no error anywhere. The aging check is as literal about the type token: `env` stays English, whatever language the one-liner speaks. Only lines starting with `- ` are read, so the index file's own header is invisible to them.

That one line is what a session judges relevance on, so it says what the fact *is*, not what it is about: "arxiv.cls builds here only under xelatex", not "notes on the build engine". Keep the index under roughly 60 lines; past that, group the entries under one heading per type — in this same file, never a second one: the hooks read no other file as an index, so a split-off index silently stops reaching sessions, while a heading is just another line they skip.

## Retiring a memory

Three ways out, and the first is the common one:

- **Re-verified** — the fact still holds: set `verified` to today, and carry the new date into the memory's index line — the stale flag reads that line, not the frontmatter.
- **Superseded** — the fact changed: write the new memory with `supersedes: <old-slug>`, then delete the old file and its index line. Git holds the history, and nothing is archived inside the store — that is what keeps the index short enough to inject into every session.
- **Wrong** — delete it. A memory that was never true is not history worth keeping.

Deleting a memory is a deletion like any other: it is confirmed with the user at every involve level (conventions §7.7, how much the skills ask).

A cycle is not a retirement event. A `cycle:<cycle>` memory from a submission that has been frozen stays true of that cycle and keeps its scope; what makes it go is being wrong, not being old.

## How it reaches a session

| Runtime | Hook | Event | What it injects |
|---|---|---|---|
| Claude Code | `.claude/hooks/stage_memory.sh` | `SessionStart` | the index, as `additionalContext` |
| Codex | `.codex/hooks/stage_memory.sh` | `SessionStart` | the index, as `additionalContext` |
| Cursor | `.cursor/hooks/stage_memory.sh` | `sessionStart` | the index, as `additional_context` |
| Kimi | `.kimi-code/hooks/stage_memory.sh` | `UserPromptSubmit` | the index, once per session |

Each hook prints the two indexes and nothing else — the shared one, and `local/`'s where it exists. An `env` line whose `verified` is more than 180 days old is marked stale in what the session sees, because a machine changes under a fact recorded about it; the other three types are not aged, since a dead end stays dead and a flag that fires on healthy entries teaches the reader to skip it. A store with no entries prints nothing at all, so a paper that has recorded nothing pays nothing.

A hook that exists is not necessarily registered. Claude, Codex and Cursor ship theirs registered in `.claude/settings.json`, `.codex/hooks.json` and `.cursor/hooks.json`; Kimi has no project-level config, so `bash .kimi-code/hooks/install.sh` registers it once per machine. On Codex, registered is still not running until the project is trusted and the hook approved with `/hooks` in the CLI. A paper repository adopted before this hook existed keeps its own registration file, which `execs/update.sh` never overwrites — it reports the gap instead, and the entry is added by hand.
