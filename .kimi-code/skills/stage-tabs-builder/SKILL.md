---
name: stage-tabs-builder
description: >-
  Generate or update one booktabs table under manus/tabs/ from fingerprinted mates/ evidence only —
  never from memory, chat, or recalled papers. Every data row carries a % src: mates/<...>#<anchor>
  comment so each number is traceable to its fingerprint; a missing number becomes a \todo{...} cell
  that opens an unsourced claim in notes/claims.md — hand-typed numbers are the failure mode this
  skill exists to kill. Re-reads every cited number before it ships, surfaces evidence staleness, and
  updates the outline Tables row and the claim ledger. Use when the user runs /skill:stage-tabs-builder, or
  asks to build, fill, extend, or fix a results, ablation, or comparison table, or to turn imported
  results into LaTeX.
---

# Table Builder — evidence-to-booktabs compiler

**Reply language (conventions §7.6).** `.env` `STAGE_LANG=en|zh` sets chat replies and the Markdown this run writes; resolve it once at the start of the run — `grep -sE '^STAGE_LANG=' .env || true`, folded into the opening load call. Unset or empty → follow the user's dialogue language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request wins. English whatever it says: everything under `manus/`, the response to reviewers, and every structural literal — frontmatter keys, ledger statuses, IDs, paths, bibkeys, venue and metric names. Repo resources (the conventions, this skill) are loaded as-is in English; their zh-CN editions — `SKILL_zh.md` beside this file, and `writing-workflow-conventions.zh-CN.md` for the conventions — are kept in step for human readers only and are never loaded at runtime, so this SKILL.md stays authoritative.

Invocation: `/skill:stage-tabs-builder [TABLE]` — `TABLE` matches the Tables table of `notes/outline.md` by ID (`T2`), file slug (`main_results`), or purpose phrase, with §5's matching manners applied to Tables rows; absent or ambiguous, list the rows with their statuses and ask (§7). A table not yet in the outline is described in the argument and gets its outline row first. One table per invocation.

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` before acting — the whole file, at the start of every run; v1 has no section-selective loading. It arrives through its own `ReadFile` call, never `cat`-ed into a Shell command. It is the baseline every STAGE skill shares; the sections that bind this skill hardest are §9 (the fabrication boundary — this skill is its enforcement at the table level), §8 (the artifact registry and its staleness rule), and §5 (resolution). This file states what is specific to this skill and wins wherever it is stricter.

**Reusing an earlier load.** A second STAGE skill in the same conversation does not pay for this twice: skip the re-read only when the same file's text is still verbatim visible in this conversation. A summary that survived a context compaction and a memory of having read it do not count. When in doubt, read it again — a wasted read costs one message, a wrong assumption costs the run.

## Role

You are a compiler, not a typist: `mates/` evidence in, a booktabs table out, and every data row carries the `% src:` comment that lets `/skill:stage-clms-auditor` walk from cell to fingerprint without you in the room. Upstream, `/skill:stage-evid-curator` imports and registers what STAR produced or what was hand-dropped; you only read it. Hand-typing a number into a table — from chat, from memory, from a paper you recall — is the failure mode this skill exists to kill.

You build tables; you do not source evidence, argue prose, or design comparisons from scratch: a number with no `mates/` entry is a `\todo{}` cell and a routing, not a keystroke.

The choice of which methods and metrics the table compares belongs to the outline row and its host section's argument — reshaping it beyond that goes back to `/skill:stage-outl-planner`. You never edit `mates/`, and you write only under `manus/tabs/` plus the two registries below.

## Core Principles

1. **Every cell traces or todos — no third state (§9a).** A data cell either carries a number read this run from the `mates/` file its row's `% src:` comment names, or is `\todo{...}` naming the missing measurement. A not-applicable cell is `—` with the reason in the row comment. Nothing else may appear in a data cell.
2. **`mates/` is the only number source.** Chat is not evidence, memory is not evidence, and a published paper's number is not evidence until it is registered: a baseline row from the literature enters through `mates/manual/` with a MANIFEST entry (route to `/skill:stage-evid-curator`), so even "well-known" numbers have a fingerprint to audit. A user who dictates a number is offered that registration, never a direct cell.
3. **A todo cell opens a claim.** Each `\todo{}` cell adds (or flips) a `notes/claims.md` row to `unsourced`, Evidence `—` — the gap becomes ledger-visible work for `/skill:stage-flow-status` and `/skill:stage-clms-auditor`, and `execs/scpts/lint.sh` holds the manuscript at the gate while any `\todo` remains. The todo cell is the carried `\todo` that `unsourced` status requires.
4. **Bold is a claim.** Highlighting the best number states a performance claim: bold or underline only where the cited evidence supports the comparison, and make sure a ledger row covers it with `tabs/<slug>` in Stated in. A best-marker over a `\todo{}` column is fabrication by typography.
5. **Staleness before typesetting (§8).** Compare the cited entries' `source-stamp:` values upstream via `execs/scpts/import.sh --diff` — exact comparison, never mtime. Stale evidence is reported and re-imported (user-approved) before its numbers ship; to fix a wrong number, fix it upstream and re-import — never in `mates/`, never only in the table.
6. **Booktabs, greppable.** `\toprule`/`\midrule`/`\bottomrule`, no vertical rules; one data row per source line so each `% src:` comment sits beside exactly one row; captions and column heads state setup facts — dataset, split, metric — only as the evidence states them, in `notes/notation.md`'s terms.

## Workflow

### Step 0: Load

1. Read the conventions file (whole file, own `ReadFile` call), then `notes/outline.md` (Tables and Sections), `notes/claims.md`, `notes/notation.md`, `notes/story.md` (active `cycle:`), and `mates/MANIFEST.md`.
2. An empty `mates/` means there is nothing to build from: stop and route to `/skill:stage-evid-curator` (or `execs/scpts/import.sh` with a paired STAR repo) — this skill does not start tables on promises.

### Step 1: Resolve the table

1. Match `TABLE` against the Tables rows by ID, file slug, then purpose phrase; absent or ambiguous → list the rows with statuses and ask via AskUserQuestion (plain text when unavailable).
2. For a table not yet planned, settle {ID, file slug, purpose, host section, evidence} in one question and append the outline Tables row (`planned`) before building.
3. When revising, read the existing `manus/tabs/<slug>.tex` in full, including its current `% src:` comments — they are the previous run's evidence map.

### Step 2: Gather the evidence

1. Follow the outline row's Evidence column and the ledger's Evidence links into `mates/`; read each cited file and its MANIFEST entry (`source-type:`, `source-stamp:`, `imported:`, `covers:`).
2. Run `execs/scpts/import.sh --diff`; report drift on cited entries and offer re-import before their numbers are typeset.
3. Map every intended row and column to a concrete number with an anchor — the nearest heading or row key in the evidence file, precise enough for `/skill:stage-clms-auditor` to find the number without guessing. This map, not the outline's wish, is what the table can honestly show.

### Step 3: Design and announce the gaps

1. Fix the layout: columns from the comparison the host section argues, metric names and abbreviations per `notes/notation.md`, grouping rules (`\midrule` between method families), and where the best-marker applies per principle 4.
2. Say which cells will be `\todo{}` before emitting, each with what is missing and where it should come from. A table that would be mostly todos routes instead: evidence that exists upstream to `/skill:stage-evid-curator`, measurements that were never run to the paired STAR repo's own workflow — this skill ships tables, not todo lattices.

### Step 4: Emit `manus/tabs/<slug>.tex`

1. A `table` float: booktabs skeleton, `\centering`, caption stating what the table shows and its setup facts from evidence, `\label{tab:<slug>}`.
2. One data row per line; directly above each, its `% src: mates/<slug>/...#<anchor>` comment — one comment per data row, no shared or blanket comments. `\todo{...}` cells named per Step 3; `—` cells reasoned in the row comment.
3. Precision: a cell may round the evidence value to the table's uniform precision — the `% src:` anchor still recovers the raw value — but never shows more precision than the evidence carries; averaging or otherwise deriving new numbers is `/skill:stage-evid-curator`'s normalization (done beside the evidence, fingerprinted), never a cell-side edit.
4. Header rows may use `\multicolumn`; data rows never merge — one `% src:` comment covers exactly one row, and a merged data row would blur that trail.
5. The table is referenced from its host section (`\input{tabs/<slug>}` or `\ref{tab:<slug>}`); when the hook is missing, report it for `/skill:stage-sect-drafter` — this skill does not write in `manus/secs/`.

### Step 5: Verify before it ships

1. Re-open every cited `mates/` file at its anchor and compare against the emitted cell, number by number — a wrong number in a table gets quoted into reviews and rebuttals. Mismatch → fix from the file or downgrade the cell to `\todo{}`. Never trust the Step 2 map without this re-read.
2. Check the emitted tex compiles in context: offer an `execs/run.sh` build.

### Step 6: Update the registries

1. `notes/claims.md`: performance claims the table states get `tabs/<slug>` added to Stated in and `proposed` → `drafted`; one `unsourced` row (Evidence `—`) per `\todo{}` cell; bump `updated:` (real date, §4).
2. `notes/outline.md`: the Tables row → `draft` (`sketch` while todos dominate); bump `updated:`.

### Step 7: Report and commit

1. Report: cells sourced vs `\todo{}` (counts and texts), evidence files read with stamps, staleness findings, ledger rows touched, best-markers applied and their covering claims. Recommend next: `/skill:stage-clms-auditor` to verify the numbers, `/skill:stage-sect-drafter` for the prose around the table, `/skill:stage-evid-curator` for what is still missing.
2. Commit per §1: one commit for the working session — table, ledger, outline together — subject naming the skill (`stage-tabs-builder: main_results`). Never commit `wkdrs/`.

## Output

- `manus/tabs/<slug>.tex` — the booktabs table; its state fields are the per-data-row `% src:` comment and the Tables row in `notes/outline.md` (registry: Tables).
- `notes/claims.md` — performance claims stated (`drafted`); one `unsourced` row per `\todo{}` cell.
- `notes/outline.md` — the Tables row status and `updated:`.
- Chat report: sourced/todo cell counts, stamps read, staleness findings, ledger deltas, and the recommended next `/skill:stage-*` step. Writes nothing outside these files.
