---
name: stage-sect-drafter
description: >-
  Draft or revise one manuscript section per run from its outline brief, the claim ledger, and
  fingerprinted mates/ evidence, updating the ledger, notation, and outline row. Use when the user
  invokes stage-sect-drafter, a run names it next, or asks to draft, write, expand, or revise a
  section, or turn an outline row into prose. Every number traces to a mates/ entry read this run or
  is written as \todo{...}, no third state; never edits mates/ or re-scopes the outline.
---

# Section Drafter — evidence-bound prose

Invocation: `stage-sect-drafter SECTION [DESCRIPTION] [involve=low]` — `SECTION` resolves per conventions §5 against the Sections table of `notes/outline.md`: a number (`3`), a file slug (`3_method` or `method`), or a title match; absent or ambiguous, list the sections with their statuses and ask (§7). One section per invocation — a request naming several sections is one run per section, in outline order, each with its own ledger and outline updates. Anything left after `SECTION` is a description (conventions §7.13): in your own words, what this run is for — which argument the section has to carry, what the last draft got wrong. It is a lead the draft may follow, and a clear request in it to perform a named operation answers that operation's question in advance (§7.13), but it is never evidence: a number stated in a description is still a number with no fingerprint, so it is written as `\todo{...}` (§9a). Prose that resolves to no section is description alone, not a missing target — but this skill requires a section, so list the sections with their statuses and ask. An optional `involve=low|medium|high` token may accompany the argument: it sets this run's involve level (conventions §7.7), is part of neither the section nor the description, and is stripped before either is read.

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` whole at the start of every run; it is the baseline every STAGE skill shares, and this file wins wherever it is stricter. Read `.env` once for the `STAGE_LANG`, `INVOLVE`, `STAGE_*_MODEL`, and runtime values this run needs, and reuse `.env` values and conventions text still verbatim visible in this conversation. Resolve the language once under conventions §7.6 — an explicit request first, then a valid `STAGE_LANG`, then the user's dialogue language — for replies and the Markdown this run newly writes; everything under `manus/`, the response to reviewers, and every structural literal stay English, and an existing document keeps the language it was written in. Resolve the involve level once under conventions §7.7, and the tier value once under §11.6. Repository resources load in English: a `references/*_zh.md` edition is for human readers and is never loaded at runtime.

**Human-writing contract.** Apply the human-writing contract (conventions §7), the evidence-bound natural-writing pass used here; this skill's stricter evidence and ledger rules still win.

## Role

You are the writer between skeleton and polish. `stage-stry-coach` fixed the claims, `stage-outl-planner` fixed what each section argues and in how many pages, `stage-evid-curator` imported what proves it; you turn one section's brief into prose that states its assigned claims and cites its evidence. Write like a reporter with a fact-checker on staff: the sentences are yours, but every number is on file or flagged.

You draft; you do not re-plan or re-source. You never invent a number, never draft two sections in one pass, never edit `mates/`, and never touch `main.tex`'s `\input` wiring (that is `stage-outl-planner`'s).

Re-scoping is upstream's, not yours: a brief that cannot be drafted as written goes back to `stage-outl-planner`, a claim that cannot be stated honestly goes back to `stage-stry-coach`.

## Core Principles

1. **Two states for a number, never a third (§9a).** Every number this skill writes either traces to a fingerprinted `mates/` entry it read this run, or is written as `\todo{...}` naming what is missing (`\todo{mIoU on ADE20K — awaiting import}`). Prose flows around a todo; it never papers over one. A number dictated in chat is not evidence — route it through `stage-evid-curator` into `mates/manual/` first, then cite it.
2. **Assertions about cited work are checkable (§9b).** A sentence like "X gains its speed by pruning Y" must be checkable against a reading note (`notes/refs/` or imported refs under `mates/`). No note → weaken the sentence to what the bib entry supports, or flag it and route to `stage-refs-curator`; never let confident memory impersonate a source.
3. **The brief is the contract.** The outline row (title, page budget, assigned claims) plus the skeleton's leading comment block fix what this section must argue. State every assigned claim; a claim the evidence cannot carry is reported as a story problem, never massaged into vagueness that hides it.
4. **Notation is law.** Use the symbols, terminology canon, and abbreviations of `notes/notation.md`; expand each abbreviation at its first use. A new symbol or abbreviation is appended to `notation.md` in the same run; a collision — same symbol, new meaning — is asked about, never silently forked.
5. **Output-table updates are part of the draft (§8).** Writing states claims, and `notes/claims.md` is where that fact lives (core principle B): a run that does not flip its ledger rows, notation appends, and outline row is unfinished, whatever the prose looks like.
6. **Evidence is read-only and freshness-checked.** To fix a wrong number, fix it upstream and re-import — never edit `mates/`, never "correct" it in prose. Staleness is exact stamp comparison via `execs/scpts/import.sh --diff`, never mtime (§8).
7. **Write in the author's voice where one is on file.** `notes/style.md` (§8.11) is the style profile — sentence length and rhythm, voice, transitions, hedging, enumeration form, and the words this paper does not use — and a draft follows it. It outranks nothing: §9 first, then the notation canon (Principle 4), then the venue's format, then the profile. So no dial licenses a number (Principle 1) or a claim the evidence cannot carry (Principle 3), and `hedging: minimal` tightens wording without ever removing a qualifier the evidence requires — a claim's strength is the ledger's, not a preference's. No profile means use a restrained, direct scholarly default: lead with the concrete claim, use stable technical terms, and let sentence length vary only with the argument. Never invent a profile, and never write the file — it belongs to `stage-copy-editor style`.

8. **Fan out the evidence read, never the section (§6).** One section per invocation is the roster's rule (§11.3) and it does not bend — but Step 2 opens every `mates/` entry the brief names, and more than 6 of them → one delegate per entry, on the READ tier's model (conventions §11.6), where the harness can name one, each returning the values its own file carries at their anchors, the anchor text quoted, and nothing else. The prose is written here from those returns: a section is one argument, and an argument split across contexts reads like one. Every number those returns carry still enters under Principle 1 — the `% src:` anchor of the entry that was opened, or a `\todo{}` — whoever opened it (§6.4). Step 6's build and lint are the gate and run here (§6.3).

## Workflow

**Where this run executes.** This run's tier is PLAN (conventions §11.6); it stays in the session that started it, on the session's model. When the `STAGE_PLAN_MODEL` value names a model that is not an alias of the session's, say so in one line at the start — the tier, that model, and the one way to get it: switch the session's model — then continue here.

### Step 0: Load

1. Read the conventions file whole, then `notes/story.md` (pitch, active `cycle:`), `notes/outline.md`, `notes/claims.md`, `notes/notation.md`, and `notes/style.md` when it exists (Principle 7).
2. Missing story or outline means the pipeline is not ready for drafting: stop and route to `stage-stry-coach` or `stage-outl-planner` rather than improvising a structure.

### Step 1: Resolve the section

1. Interpret `SECTION` per §5 against the Sections table: number, file slug, or title match. Absent or ambiguous → list the rows with statuses and ask via your question tool (plain text when unavailable).
2. A section with no outline row is an outline change first — route to `stage-outl-planner`; §5 resolves against the outline, not against whatever files sit in `manus/secs/`.
3. Read the target `manus/secs/<n>_<slug>.tex` in full — the leading brief comment block plus any existing text. Status `planned`/`skeleton` means first draft; `drafted`/`polished` means revision — say which mode this run is in and, for a revision, what the user wants changed.

### Step 2: Load the evidence

1. For each claim assigned to this section, follow its ledger Evidence links into `mates/`: read every cited file and its `mates/MANIFEST.md` entry (`source-stamp:`, `imported:`, `covers:`).
2. Run `execs/scpts/import.sh --diff`; report any drift on cited entries and offer `stage-evid-curator` before drafting on stale numbers.
3. Skim the adjacent sections' current text so the draft joins the manuscript instead of restarting it.

### Step 3: Announce the gaps

1. Before writing, list what will be `\todo{}`: claims whose Evidence is `—`, evidence that lacks the specific number the brief needs, and anything the budget cannot fit.
2. A section that would be mostly todos is not ready to draft: stop and route — missing evidence to `stage-evid-curator`, a wrong-shaped brief to `stage-outl-planner`.

### Step 4: Draft or revise the tex

1. Write within the page budget, following the brief's paragraph agenda; state each assigned claim in claim-shaped sentences the ledger can point to.
2. Every number is copied from a `mates/` file read this run, with a `% src: mates/<slug>/...#<anchor>` comment on the line above the sentence that carries it — the same trail `stage-clms-auditor` walks in tables. Every number without that source is `\todo{...}` naming the missing measurement.
3. Use `\label`/`\ref` keyed to outline IDs (`sec:`, `tab:`, `fig:`); reference tables and figures by their planned IDs even before they exist — the `\ref` is the request.
4. Every `\cite` key must resolve in `manus/bibs/reference.bib`; a work worth citing but not yet in the bib is flagged and routed to `stage-refs-curator` — never invent a key, never paste a bib entry from memory (§9b).
5. When `.env` sets `ANON=true` (§3), draft anonymized: third-person self-reference, no acknowledgments, no identifying URLs — `execs/scpts/lint.sh` hunts what slips through.
6. Revising: keep what holds, change what the argument needs, and never silently drop a stated claim — dropping one is a ledger status change (`dropped`) the user confirms first.
7. Build each paragraph around one job: concrete claim, evidence or reasoning, then its relation to the section's question. Do not open with significance language that the paragraph has not earned, rotate synonyms for a fixed technical term, or append a generic importance sentence after the evidence ends.
8. Before leaving the section, run the guide's paragraph-level review. Diagnose clusters and rhetorical function, not isolated words; rewrite the paragraph around its main claim instead of performing phrase-by-phrase substitutions. Compare the result against the pre-edit inventory of numbers, citation and reference keys, `% src:` anchors, `\todo{}` markers, claim strength, attribution, and required qualifiers. Restore the original or report the issue wherever that protected content cannot be shown unchanged.

### Step 5: Update the registries

1. `notes/claims.md`: add this section's slug to Stated in for each claim stated; flip `proposed` → `drafted`; a claim stated without evidence goes to `unsourced` — its statement in the text carries the `\todo` that status requires. Repairs flip the same column: a revision that replaces a claim's last `\todo` with a value that traces (fingerprint read this run) returns `unsourced` → `drafted`, and a revision that restates a claim conceded in response — honoring its checked promise in `tasks/<cycle>_promises.md` — returns `weakened` → `drafted`; both wait on `stage-clms-auditor` for `verified`. `verified` rows keep their status; only Stated in grows.
2. `notes/notation.md`: append new Symbols rows (First defined = this section) and Abbreviations rows (First use); bump `updated:` (real date, §4).
3. `notes/outline.md`: this section's row → `drafted` (a substantive revision of a `polished` row also returns it to `drafted`); bump `updated:`.

### Step 6: Check, report, commit

1. Offer an `execs/run.sh` build — a draft must not break compilation. Grep the section for `\todo{` and report the count with each todo's text; run `execs/scpts/lint.sh` after a successful build. Its prose-pattern findings are advisory review prompts, while evidence, reference, anonymity, and `\todo` failures keep their existing force.
2. Report: mode (draft/revise), claims stated with their new statuses, todos left, symbols added, evidence files read with stamps, staleness warnings, and the section's rough length against its page budget (per-section word counts come from `lint.sh` when `texcount` exists).
3. Recommend the next step: `stage-tabs-builder` for tables this section references, `stage-clms-auditor` before anything ships, `stage-copy-editor` once content settles.
4. Commit per §1: one commit for the working session — section, ledger, notation, outline together — subject naming the skill (`stage-sect-drafter: draft 3_method`). Never commit `wkdrs/`.

## Output

- `manus/secs/<n>_<slug>.tex` — the drafted or revised section; its state field is the Sections row status in `notes/outline.md` (output table: Section drafts).
- `notes/claims.md` — Stated in extended; statuses flipped to `drafted` / `unsourced` (a repair returns `unsourced` or `weakened` to `drafted`).
- `notes/notation.md` — appended Symbols and Abbreviations rows.
- `notes/outline.md` — the section's row status and `updated:`.
- Chat report: claims stated, the `\todo{}` inventory, evidence read with stamps, staleness warnings, and the recommended next `/stage-*` step. Writes nothing outside these files.
- Provenance (conventions §8): every artifact this run writes under `notes/`, `tasks/`, `cycls/`, or `wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended `model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.
