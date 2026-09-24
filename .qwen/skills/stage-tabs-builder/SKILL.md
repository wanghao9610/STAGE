---
name: stage-tabs-builder
description: >-
  Build or update one booktabs table under manus/tabs/ from fingerprinted mates/ evidence, a % src:
  comment on every data row and every number re-read before it ships; a missing number becomes a
  \todo{...} cell that opens an unsourced claim. Use when the user runs /stage-tabs-builder, a run
  names it next, or asks to build, fill, extend, or fix a results, ablation, or comparison table, or
  turn imported results into LaTeX. No number comes from memory, chat, or recalled papers.
argument-hint: "[TABLE] [involve=low]"
---

# Table Builder — evidence-to-booktabs compiler

Invocation: `stage-tabs-builder [TABLE] [involve=low]` — `TABLE` matches the Tables table of `notes/outline.md` by ID (`T2`), file slug (`main_results`), or purpose phrase, with §5's matching manners applied to Tables rows; absent or ambiguous, list the rows with their statuses and ask (§7). A table not yet in the outline is described in the argument and gets its outline row first. One table per invocation. There is no separate description slot here: free text is already the table's own description — that is how a purpose phrase resolves a Tables row, and how a table with no row yet is stated — so conventions §7.13's description *is* that argument, and nothing further is stripped from it. It says what the table is for; it never supplies what goes in a cell, which comes from a fingerprinted `mates/` entry read this run or becomes a `\todo{...}`. An optional `involve=low|medium|high` token may accompany the argument: it sets this run's involve level (conventions §7.7), is not part of the argument, and is stripped before it is read.

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` whole at the start of every run; it is the baseline every STAGE skill shares, and this file wins wherever it is stricter. Read `.env` once for the `STAGE_LANG`, `INVOLVE`, `STAGE_*_MODEL`, and runtime values this run needs, and reuse `.env` values and conventions text still verbatim visible in this conversation. Resolve the language once under conventions §7.6 — an explicit request first, then a valid `STAGE_LANG`, then the user's dialogue language — for replies and the Markdown this run newly writes; everything under `manus/`, the response to reviewers, and every structural literal stay English, and an existing document keeps the language it was written in. Resolve the involve level once under conventions §7.7, and the tier value once under §11.6. Repository resources load in English: a `references/*_zh.md` edition is for human readers and is never loaded at runtime.

## Role

You are a compiler, not a typist: `mates/` evidence in, a booktabs table out, and every data row carries the `% src:` comment that lets `stage-clms-auditor` walk from cell to fingerprint without you in the room. Upstream, `stage-evid-curator` imports and registers what STAR produced or what was hand-dropped; you only read it. Hand-typing a number into a table — from chat, from memory, from a paper you recall — is the failure mode this skill exists to kill.

You build tables; you do not source evidence, argue prose, or design comparisons from scratch: a number with no `mates/` entry is a `\todo{}` cell and a routing, not a keystroke.

The choice of which methods and metrics the table compares belongs to the outline row and its host section's argument — reshaping it beyond that goes back to `stage-outl-planner`. You never edit `mates/`, and you write only under `manus/tabs/` plus the two registries below.

## Core Principles

1. **Every cell traces or todos — no third state (§9a).** A data cell either carries a number read this run from the `mates/` file its row's `% src:` comment names, or is `\todo{...}` naming the missing measurement. A not-applicable cell is `—` with the reason in the row comment. Nothing else may appear in a data cell.
2. **`mates/` is the only number source.** Chat is not evidence, memory is not evidence, and a published paper's number is not evidence until it is registered: a baseline row from the literature enters through `mates/manual/` with a MANIFEST entry (route to `stage-evid-curator`), so even "well-known" numbers have a fingerprint to audit. A user who dictates a number is offered that registration, never a direct cell.
3. **A todo cell opens a claim.** Each `\todo{}` cell adds (or flips) a `notes/claims.md` row to `unsourced`, Evidence `—` — the gap becomes ledger-visible work for `stage-flow-status` and `stage-clms-auditor`, and `execs/scpts/lint.sh` holds the manuscript at the gate while any `\todo` remains. The todo cell is the carried `\todo` that `unsourced` status requires.
4. **Bold is a claim.** Highlighting the best number states a performance claim: bold or underline only where the cited evidence supports the comparison, and make sure a ledger row covers it with `tabs/<slug>` in Stated in. A best-marker over a `\todo{}` column is fabrication by typography.
5. **Staleness before typesetting (§8).** Compare the cited entries' `source-stamp:` values upstream via `execs/scpts/import.sh --diff` — exact comparison, never mtime. Stale evidence is reported and re-imported (user-approved) before its numbers ship; to fix a wrong number, fix it upstream and re-import — never in `mates/`, never only in the table.
6. **Booktabs, greppable.** `\toprule`/`\midrule`/`\bottomrule`, no vertical rules; one data row per source line so each `% src:` comment sits beside exactly one row; captions and column heads state setup facts — dataset, split, metric — only as the evidence states them, in `notes/notation.md`'s terms.

7. **Fan out the evidence gather (§6).** Step 2 collects one number per cell from fingerprinted `mates/` files: more than 6 distinct files behind one table → one delegate per file, on the READ tier's model (conventions §11.6), where the harness can name one, each returning the values at their anchors with the anchor text quoted and nothing else. The table is emitted here, because one `.tex` file has one writer (§6.2) and a row's `% src:` comment and its number are written together by whoever writes the row (§6.4). The staleness diff is one `import.sh --diff` call and Step 5's re-read before it ships is the gate — both run here (§6.3).

## Workflow

**Where this run executes.** This run's tier is EXEC (conventions §11.6); it stays in the session that started it, on the session's model. When the `STAGE_EXEC_MODEL` value names a model that is not an alias of the session's, say so in one line at the start — the tier, that model, and the one way to get it: switch the session's model — then continue here.

### Step 0: Load

1. Read the conventions file whole, then `notes/outline.md` (Tables and Sections), `notes/claims.md`, `notes/notation.md`, `notes/story.md` (active `cycle:`), and `mates/MANIFEST.md`.
2. An empty `mates/` means there is nothing to build from: stop and route to `stage-evid-curator` (or `execs/scpts/import.sh` with a paired STAR repo) — this skill does not start tables on promises.

### Step 1: Resolve the table

1. Match `TABLE` against the Tables rows by ID, file slug, then purpose phrase; absent or ambiguous → list the rows with statuses and ask via `ask_user_question` (plain text when unavailable).
2. For a table not yet planned, settle {ID, file slug, purpose, host section, evidence} in one question and append the outline Tables row (`planned`) before building.
3. When revising, read the existing `manus/tabs/<slug>.tex` in full, including its current `% src:` comments — they are the previous run's evidence map.

### Step 2: Gather the evidence

1. Follow the outline row's Evidence column and the ledger's Evidence links into `mates/`; read each cited file and its MANIFEST entry (`source-type:`, `source-stamp:`, `imported:`, `covers:`).
2. Run `execs/scpts/import.sh --diff`; report drift on cited entries and offer re-import before their numbers are typeset.
3. Map every intended row and column to a concrete number with an anchor — the nearest heading or row key in the evidence file, precise enough for `stage-clms-auditor` to find the number without guessing. This map, not the outline's wish, is what the table can honestly show.

### Step 3: Design and announce the gaps

1. Fix the layout: columns from the comparison the host section argues, metric names and abbreviations per `notes/notation.md`, grouping rules (`\midrule` between method families), and where the best-marker applies per principle 4.
2. Say which cells will be `\todo{}` before emitting, each with what is missing and where it should come from. A table that would be mostly todos routes instead: evidence that exists upstream to `stage-evid-curator`, measurements that were never run to the paired STAR repo's own workflow — this skill ships tables, not todo lattices.

### Step 4: Emit `manus/tabs/<slug>.tex`

1. A `table` float: booktabs skeleton, `\centering`, caption stating what the table shows and its setup facts from evidence, `\label{tab:<slug>}`.
2. One data row per line; directly above each, its `% src: mates/<slug>/...#<anchor>` comment — one comment per data row, no shared or blanket comments. `\todo{...}` cells named per Step 3; `—` cells reasoned in the row comment.
3. Precision: a cell may round the evidence value to the table's uniform precision — the `% src:` anchor still recovers the raw value — but never shows more precision than the evidence carries; averaging or otherwise deriving new numbers is `stage-evid-curator`'s normalization (done beside the evidence, fingerprinted), never a cell-side edit.
4. Header rows may use `\multicolumn`; data rows never merge — one `% src:` comment covers exactly one row, and a merged data row would blur that trail.
5. The table is referenced from its host section (`\input{tabs/<slug>}` or `\ref{tab:<slug>}`); when the hook is missing, report it for `stage-sect-drafter` — this skill does not write in `manus/secs/`.

### Step 5: Verify before it ships

1. Re-open every cited `mates/` file at its anchor and compare against the emitted cell, number by number — a wrong number in a table gets quoted into reviews and rebuttals. Mismatch → fix from the file or downgrade the cell to `\todo{}`. Never trust the Step 2 map without this re-read.
2. Check the emitted tex compiles in context: offer an `execs/run.sh` build.

### Step 6: Update the registries

1. `notes/claims.md`: performance claims the table states get `tabs/<slug>` added to Stated in and `proposed` → `drafted`; one `unsourced` row (Evidence `—`) per `\todo{}` cell; a rebuild that fills a previous `\todo{}` cell with a value that traces returns that claim `unsourced` → `drafted`, and one honoring a checked promise in `tasks/<cycle>_promises.md` returns its conceded claim `weakened` → `drafted` — `verified` stays `stage-clms-auditor`'s to award; bump `updated:` (real date, §4).
2. `notes/outline.md`: the Tables row → `draft` (`sketch` while todos dominate); bump `updated:`.

### Step 7: Report and commit

1. Report: cells sourced vs `\todo{}` (counts and texts), evidence files read with stamps, staleness findings, ledger rows touched, best-markers applied and their covering claims. Recommend next: `stage-clms-auditor` to verify the numbers, `stage-sect-drafter` for the prose around the table, `stage-evid-curator` for what is still missing.
2. Commit per §1: one commit for the working session — table, ledger, outline together — subject naming the skill (`stage-tabs-builder: main_results`). Never commit `wkdrs/`.

## Output

- `manus/tabs/<slug>.tex` — the booktabs table; its state fields are the per-data-row `% src:` comment and the Tables row in `notes/outline.md` (output table: Tables).
- `notes/claims.md` — performance claims stated (`drafted`); one `unsourced` row per `\todo{}` cell.
- `notes/outline.md` — the Tables row status and `updated:`.
- Chat report: sourced/todo cell counts, stamps read, staleness findings, ledger deltas, and the recommended next `/stage-*` step. Writes nothing outside these files.
- Provenance (conventions §8): every artifact this run writes under `notes/`, `tasks/`, `cycls/`, or `wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended `model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.
