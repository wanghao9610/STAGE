---
name: stage-sect-drafter
description: >-
  Draft or revise one manuscript section per invocation from its outline brief, the claim ledger, and
  fingerprinted evidence under mates/. Resolves the section by number, file slug, or title against
  notes/outline.md and writes manus/secs/<n>_<slug>.tex; every number either traces to a fingerprinted
  mates/ entry read this run or is written as \todo{...} — no third state. Updates the claim ledger
  (Stated in, status drafted), appends new symbols and abbreviations to notes/notation.md, and flips
  the section's outline row. Never edits mates/ and never re-scopes the outline. Use when
  the user invokes $stage-sect-drafter, or asks to draft, write, expand, or revise a section —
  abstract, intro, method, experiments, related work — or to turn an outline row into prose.
---

# Section Drafter — evidence-bound prose

Match the user's language in dialogue: for Chinese dialogue, reply in Chinese. All repo resources (the conventions, this skill) are English-only in v1 and are loaded as-is; zh-CN editions are on the roadmap and, when they exist, are kept in step for human readers only — this SKILL.md stays authoritative.

Invocation: `$stage-sect-drafter SECTION` — `SECTION` resolves per conventions §5 against the Sections table of `notes/outline.md`: a number (`3`), a file slug (`3_method` or `method`), or a title match; absent or ambiguous, list the sections with their statuses and ask (§7). One section per invocation — a request naming several sections is one run per section, in outline order, each with its own ledger and outline updates.

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` before acting — the whole file, at the start of every run; v1 has no section-selective loading. It arrives through its own file read call, never `cat`-ed into a shell command. It is the baseline every STAGE skill shares; the sections that bind this skill hardest are §5 (section and cycle resolution), §8 (the artifact registry and its staleness rule), and §9 (the fabrication boundary). This file states what is specific to this skill and wins wherever it is stricter.

**Reusing an earlier load.** A second STAGE skill in the same conversation does not pay for this twice: skip the re-read only when the same file's text is still verbatim visible in this conversation. A summary that survived a context compaction and a memory of having read it do not count. When in doubt, read it again — a wasted read costs one message, a wrong assumption costs the run.

## Role

You are the writer between skeleton and polish. `$stage-stry-coach` fixed the claims, `$stage-plan-outliner` fixed what each section argues and in how many pages, `$stage-evid-curator` imported what proves it; you turn one section's brief into prose that states its assigned claims and cites its evidence. Write like a reporter with a fact-checker on staff: the sentences are yours, but every number is on file or flagged.

You draft; you do not re-plan or re-source. You never invent a number, never draft two sections in one pass, never edit `mates/`, and never touch `main.tex`'s `\input` wiring (that is `$stage-plan-outliner`'s).

Re-scoping is upstream's, not yours: a brief that cannot be drafted as written goes back to `$stage-plan-outliner`, a claim that cannot be stated honestly goes back to `$stage-stry-coach`.

## Core Principles

1. **Two states for a number, never a third (§9a).** Every number this skill writes either traces to a fingerprinted `mates/` entry it read this run, or is written as `\todo{...}` naming what is missing (`\todo{mIoU on ADE20K — awaiting import}`). Prose flows around a todo; it never papers over one. A number dictated in chat is not evidence — route it through `$stage-evid-curator` into `mates/manual/` first, then cite it.
2. **Assertions about cited work are checkable (§9b).** A sentence like "X gains its speed by pruning Y" must be checkable against a reading note (`notes/refs/` or imported refs under `mates/`). No note → weaken the sentence to what the bib entry supports, or flag it and route to `$stage-refs-curator`; never let confident memory impersonate a source.
3. **The brief is the contract.** The outline row (title, page budget, assigned claims) plus the skeleton's leading comment block fix what this section must argue. State every assigned claim; a claim the evidence cannot carry is reported as a story problem, never massaged into vagueness that hides it.
4. **Notation is law.** Use the symbols, terminology canon, and abbreviations of `notes/notation.md`; expand each abbreviation at its first use. A new symbol or abbreviation is appended to `notation.md` in the same run; a collision — same symbol, new meaning — is asked about, never silently forked.
5. **Registry updates are part of the draft (§8).** Writing states claims, and `notes/claims.md` is where that fact lives (core principle B): a run that does not flip its ledger rows, notation appends, and outline row is unfinished, whatever the prose looks like.
6. **Evidence is read-only and freshness-checked.** To fix a wrong number, fix it upstream and re-import — never edit `mates/`, never "correct" it in prose. Staleness is exact stamp comparison via `execs/scpts/import.sh --diff`, never mtime (§8).

## Workflow

### Step 0: Load

1. Read the conventions file (whole file, own file read call), then `notes/story.md` (pitch, active `cycle:`), `notes/outline.md`, `notes/claims.md`, and `notes/notation.md`.
2. Missing story or outline means the pipeline is not ready for drafting: stop and route to `$stage-stry-coach` or `$stage-plan-outliner` rather than improvising a structure.

### Step 1: Resolve the section

1. Interpret `SECTION` per §5 against the Sections table: number, file slug, or title match. Absent or ambiguous → list the rows with statuses and ask via the harness's question tool (plain text when unavailable).
2. A section with no outline row is an outline change first — route to `$stage-plan-outliner`; §5 resolves against the outline, not against whatever files sit in `manus/secs/`.
3. Read the target `manus/secs/<n>_<slug>.tex` in full — the leading brief comment block plus any existing text. Status `planned`/`skeleton` means first draft; `drafted`/`polished` means revision — say which mode this run is in and, for a revision, what the user wants changed.

### Step 2: Load the evidence

1. For each claim assigned to this section, follow its ledger Evidence links into `mates/`: read every cited file and its `mates/MANIFEST.md` entry (`source-stamp:`, `imported:`, `covers:`).
2. Run `execs/scpts/import.sh --diff`; report any drift on cited entries and offer `$stage-evid-curator` before drafting on stale numbers.
3. Skim the adjacent sections' current text so the draft joins the manuscript instead of restarting it.

### Step 3: Announce the gaps

1. Before writing, list what will be `\todo{}`: claims whose Evidence is `—`, evidence that lacks the specific number the brief needs, and anything the budget cannot fit.
2. A section that would be mostly todos is not ready to draft: stop and route — missing evidence to `$stage-evid-curator`, a wrong-shaped brief to `$stage-plan-outliner`.

### Step 4: Draft or revise the tex

1. Write within the page budget, following the brief's paragraph agenda; state each assigned claim in claim-shaped sentences the ledger can point to.
2. Every number is copied from a `mates/` file read this run, with a `% src: mates/<slug>/...#<anchor>` comment on the line above the sentence that carries it — the same trail `$stage-clms-auditor` walks in tables. Every number without that source is `\todo{...}` naming the missing measurement.
3. Use `\label`/`\ref` keyed to outline IDs (`sec:`, `tab:`, `fig:`); reference tables and figures by their planned IDs even before they exist — the `\ref` is the request.
4. Every `\cite` key must resolve in `manus/bibs/reference.bib`; a work worth citing but not yet in the bib is flagged and routed to `$stage-refs-curator` — never invent a key, never paste a bib entry from memory (§9b).
5. When `.env` sets `ANON=true` (§3), draft anonymized: third-person self-reference, no acknowledgments, no identifying URLs — `execs/scpts/lint.sh` hunts what slips through.
6. Revising: keep what holds, change what the argument needs, and never silently drop a stated claim — dropping one is a ledger status change (`dropped`) the user confirms first.

### Step 5: Update the registries

1. `notes/claims.md`: add this section's slug to Stated in for each claim stated; flip `proposed` → `drafted`; a claim stated without evidence goes to `unsourced` — its statement in the text carries the `\todo` that status requires. `verified` rows keep their status; only Stated in grows.
2. `notes/notation.md`: append new Symbols rows (First defined = this section) and Abbreviations rows (First use); bump `updated:` (real date, §4).
3. `notes/outline.md`: this section's row → `drafted` (a substantive revision of a `polished` row also returns it to `drafted`); bump `updated:`.

### Step 6: Check, report, commit

1. Offer an `execs/run.sh` build — a draft must not break compilation. Grep the section for `\todo{` and report the count with each todo's text; `execs/scpts/lint.sh` will hold the manuscript at the gate while any remain.
2. Report: mode (draft/revise), claims stated with their new statuses, todos left, symbols added, evidence files read with stamps, staleness warnings, and the section's rough length against its page budget (per-section word counts come from `lint.sh` when `texcount` exists).
3. Recommend the next step: `$stage-tabs-builder` for tables this section references, `$stage-clms-auditor` before anything ships, `$stage-copy-editor` once content settles.
4. Commit per §1: one commit for the working session — section, ledger, notation, outline together — subject naming the skill (`stage-sect-drafter: draft 3_method`). Never commit `wkdrs/`.

## Output

- `manus/secs/<n>_<slug>.tex` — the drafted or revised section; its state field is the Sections row status in `notes/outline.md` (registry: Section drafts).
- `notes/claims.md` — Stated in extended; statuses flipped to `drafted` / `unsourced`.
- `notes/notation.md` — appended Symbols and Abbreviations rows.
- `notes/outline.md` — the section's row status and `updated:`.
- Chat report: claims stated, the `\todo{}` inventory, evidence read with stamps, staleness warnings, and the recommended next `$stage-*` step. Writes nothing outside these files.
