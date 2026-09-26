---
name: stage-sect-drafter
description: >-
  Draft or revise one manuscript section per run from its outline brief, the claim ledger, and
  fingerprinted mates/ evidence, updating the ledger, notation, and outline row. Use when the user
  invokes stage-sect-drafter, stage-auto starts it, or asks to draft, write, expand, or revise a
  section, or turn an outline row into prose. Every number traces to a mates/ entry read this run or
  is written as \todo{...}, no third state; never edits mates/ or re-scopes the outline.
---

# Section Drafter — evidence-bound prose

Invocation: `stage-sect-drafter SECTION [DESCRIPTION] [involve=low]` — `SECTION` resolves per conventions §5 against the Sections table of `notes/outline.md`: a number (`3`), a file slug (`3_method` or `method`), or a title match; absent or ambiguous, list the sections with their statuses and ask (§7). One section per invocation — a request naming several sections is one run per section, in outline order, each with its own ledger and outline updates. Anything left after `SECTION` is a description (conventions §7.13): in your own words, what this run is for — which argument the section has to carry, what the last draft got wrong. It is a lead the draft may follow, and a clear request in it to perform a named operation answers that operation's question in advance (§7.13), but it is never evidence: a number stated in a description is still a number with no fingerprint, so it is written as `\todo{...}` (§9a). Prose that resolves to no section is description alone, not a missing target — but this skill requires a section, so list the sections with their statuses and ask. An optional `involve=low|medium|high` token may accompany the argument: it sets this run's involve level (conventions §7.7), is part of neither the section nor the description, and is stripped before either is read.

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` whole at the start of every run. It is longer than one read or one shell command returns, so read it by line range, a few hundred lines at a time, until its last line, the end of §13, is in view — a `cat` of the whole file is saved aside unread. It is the baseline every STAGE skill shares, and this file wins wherever it is stricter. Read `.env` once for the `STAGE_LANG`, `INVOLVE`, `STAGE_*_MODEL`, and runtime values this run needs, and reuse `.env` values and conventions text still verbatim visible in this conversation. Resolve the language once under conventions §7.6 — an explicit request first, then a valid `STAGE_LANG`, then the user's dialogue language, read from their latest message in their own words and never from a bare command line or the English this run loads — for replies and the Markdown this run newly writes; everything under `manus/`, the response to reviewers, and every structural literal stay English, and an existing document keeps the language it was written in. Resolve the involve level once under conventions §7.7, and the tier value once under §11.6. Repository resources load in English: a `references/*_zh.md` edition is for human readers and is never loaded at runtime.

**Human-writing contract.** Apply the human-writing contract (conventions §7), the evidence-bound natural-writing pass used here; this skill's stricter evidence and ledger rules still win.

## Role

You are the writer between skeleton and polish. `stage-stry-coach` fixed the claims, `stage-outl-planner` fixed what each section argues and in how many pages, `stage-evid-curator` imported what proves it; you turn one section's brief into prose that states its assigned claims and cites its evidence. Write like a reporter with a fact-checker on staff: the sentences are yours, but every number is on file or flagged.

You draft; you do not re-plan or re-source. You never invent a number, never draft two sections in one pass, never edit `mates/`, and never touch `main.tex`'s `\input` wiring (that is `stage-outl-planner`'s).

Re-scoping is upstream's, not yours: a brief that cannot be drafted as written goes back to `stage-outl-planner`, a claim that cannot be stated honestly goes back to `stage-stry-coach`.

## Core Principles

1. **Two states for a number, never a third (§9a).** Every number this skill writes either traces to a fingerprinted `mates/` entry it read this run, or is written as `\todo{...}` naming what is missing (`\todo{mIoU on ADE20K — awaiting import}`). A number the sentence attributes to a cited work — the value its `\cite` attaches to — is that work's fact, backed by its reading note under Principle 2 (conventions §9a, §9b); this paper's own numbers beside it stay under this principle, and so does a delta against it, which is a derived number (§9a). Prose flows around a todo; it never papers over one. A number dictated in chat is not evidence — route it through `stage-evid-curator register <path>` into `mates/manual/` first, then cite it.
2. **Assertions about cited work are checkable (§9b).** A sentence like "X gains its speed by pruning Y" must be checkable against a reading note (`notes/refs/` or imported refs under `mates/`). No note → mark it `\todo{verify: <the fact>}` or drop the assertion (a bare `\citep` pointer with no predicate about the work may stay), and route the missing note to `stage-refs-curator`; never soften it into vagueness (§9b), and never let confident memory impersonate a source.
3. **The brief is the contract.** The outline row (title, page budget, assigned claims) plus the skeleton's leading comment block fix what this section must argue. State every assigned claim not at `dropped`, and take out a `dropped` claim the section still states; a claim the evidence cannot carry is reported as a story problem, never massaged into vagueness that hides it.
4. **Notation is law.** Use the symbols, terminology canon, and abbreviations of `notes/notation.md`; expand each abbreviation at its first use. A new symbol or abbreviation is appended to `notation.md` in the same run; a collision — same symbol, new meaning — is asked about, never silently forked.
5. **Output-table updates are part of the draft (§8).** Writing states claims, and `notes/claims.md` is where that fact lives: a run that does not flip its ledger rows, notation appends, and outline row is unfinished, whatever the prose looks like.
6. **Evidence is read-only and freshness-checked.** To fix a wrong number, fix it upstream and re-import — never edit `mates/`, never "correct" it in prose. Staleness is exact stamp comparison via `execs/scpts/import.sh --diff`, never mtime (§8).
7. **Write in the author's voice where one is on file.** `notes/style.md` (§8.11) is the style profile — sentence length and rhythm, voice, transitions, hedging, enumeration form, and the words this paper does not use — and a draft follows it. It outranks nothing: §9 first, then the notation canon (Principle 4), then the venue's format, then the profile. So no dial licenses a number (Principle 1) or a claim the evidence cannot carry (Principle 3), and `hedging: minimal` tightens wording without ever removing a qualifier the evidence requires — a claim's strength is the ledger's, not a preference's. No profile means use a restrained, direct scholarly default: lead with the concrete claim, use stable technical terms, and let sentence length vary only with the argument. Never invent a profile, and never write the file — it belongs to `stage-copy-editor style`.

8. **Fan out the evidence read, never the section (§6).** One section per invocation is the roster's rule (§11.3) and it does not bend — but Step 2 opens every `mates/` entry the brief names, and more than 6 of them → one delegate per entry, on the READ tier's model (conventions §11.6), where the harness can name one, each returning the values its own file carries at their anchors, the anchor text quoted, and nothing else. The prose is written here from those returns: a section is one argument, and an argument split across contexts reads like one. Every number those returns carry still enters under Principle 1 — the `% src:` anchor of the entry that was opened, or a `\todo{}` — whoever opened it (§6.4). Step 6's build and lint are the gate and run here (§6.3).

## Workflow

**Where this run executes.** This run's tier is PLAN (conventions §11.6); it stays in the session that started it, on the session's model. When the `STAGE_PLAN_MODEL` value names a model that is not an alias of the session's, say so in one line at the start — the tier, that model, and the one way to get it: switch the session's model — then continue here.

### Step 0: Load

1. Read the conventions file whole, then `notes/story.md` (pitch, active `cycle:`), `notes/outline.md`, `notes/claims.md`, `notes/notation.md`, `notes/style.md` when it exists (Principle 7), and, when they exist, `tasks/claims_followups.md`, `tasks/cites_followups.md` (Step 1.3), and the active cycle's `tasks/<cycle>_promises.md` (Steps 1.3, 5.4).
2. Missing story or outline means the pipeline is not ready for drafting: stop and route to `stage-stry-coach` or `stage-outl-planner` rather than improvising a structure.

### Step 1: Resolve the section

1. Interpret `SECTION` per §5 against the Sections table: number, file slug, or title match. Absent or ambiguous → list the rows with statuses and ask via your question tool (plain text when unavailable).
2. A section with no outline row is an outline change first — route to `stage-outl-planner`; §5 resolves against the outline, not against whatever files sit in `manus/secs/`.
3. Read the target `manus/secs/<n>_<slug>.tex` in full — the leading brief comment block plus any existing text. Status `planned`/`skeleton` means first draft; `drafted`/`polished` means revision — say which mode this run is in and, for a revision, what the user wants changed. In a revision with no description, the revision brief is the open boxes that name this section in `tasks/claims_followups.md`, `tasks/cites_followups.md`, and `tasks/<cycle>_promises.md`, plus any Tables or Figures row whose Section is this one and whose file exists but is not yet placed here (Step 4.3).

### Step 2: Load the evidence

1. For each claim assigned to this section, follow its ledger Evidence links into `mates/`: read every cited file and its `mates/MANIFEST.md` entry (`source-stamp:`, `imported:`, `covers:`).
2. Run `execs/scpts/import.sh --diff`; report any drift on cited entries and offer `stage-evid-curator import` before drafting on stale numbers. No STAR source configured (it exits 1 saying so) → report staleness as not checked (conventions §7.4) and continue; manual entries have no upstream to diff.
3. Skim the adjacent sections' current text so the draft joins the manuscript instead of restarting it.

### Step 3: Announce the gaps

1. Before writing, list what will be `\todo{}`: claims whose Evidence is `—`, and evidence that lacks the specific number the brief needs. What the budget cannot fit is not a marker (§9a): report it and route it to `stage-outl-planner`.
2. A section that would be mostly todos is not ready to draft: stop and route — missing evidence to `stage-evid-curator`, a wrong-shaped brief to `stage-outl-planner`.

### Step 4: Draft or revise the tex

1. Write within the page budget, following the brief's paragraph agenda; state each assigned claim in claim-shaped sentences the ledger can point to. The skeleton's placeholder `\todo` is replaced by the body.
2. Every number is copied from a `mates/` file read this run, with a `% src: mates/<slug>/...#<anchor>` comment on the line above the sentence that carries it — the same trail `stage-clms-auditor` walks in tables. A number the sentence attributes to a cited work is excepted (Principle 1): it carries its `\cite`, is backed by the reading note (Principle 2), and needs no `mates/` source of its own, while this paper's numbers in the same sentence, and a delta against it, keep the `% src:` line. Every other number without that source is `\todo{...}` naming the missing measurement.
3. Key `\label`/`\ref` by the outline row's file slug without its `<n>_` prefix (`sec:<slug>`, `fig:<slug>`, and `tab:<slug>`, the label `stage-tabs-builder` writes); reference tables and figures by those keys even before they exist — the `\ref` is the request. A Tables or Figures row whose Section is this one and whose file exists is placed here: `\input{tabs/<slug>}` for a table; for a figure, a `figure` float with `\includegraphics{figs/<slug>}`, `\label{fig:<slug>}`, and a caption whose numbers take their `% src:` lines from the figure's `src:` entries in `manus/figs/srcs/<slug>.*` — the `mates/<...>#<anchor>` part of each entry, its `sha256:` field left behind — with any `\todo{...}` caption text handed over kept verbatim.
4. Every `\cite` key must resolve in `manus/bibs/reference.bib`; a work worth citing but not yet in the bib is flagged and routed to `stage-refs-curator` — never invent a key, never paste a bib entry from memory (§9b).
5. When `.env` sets `ANON=true` (§3), draft anonymized: third-person self-reference, no acknowledgments, no identifying URLs — `execs/scpts/lint.sh` hunts what slips through.
6. Revising: keep what holds, change what the argument needs, and never silently drop a stated claim: one the outline's Claims cell still assigns here goes back to `stage-outl-planner` first (Principle 3); once unassigned, the revision removes this section's slug from its Stated in, user confirmed, and a claim left with no Stated in flips to `dropped` only after the user confirms it leaves the paper.
7. Build each paragraph around one job: concrete claim, evidence or reasoning, then its relation to the section's question. Do not open with significance language that the paragraph has not earned, rotate synonyms for a fixed technical term, or append a generic importance sentence after the evidence ends.
8. Before leaving the section, run the human-writing contract's paragraph-level review (conventions §7). Diagnose clusters and rhetorical function, not isolated words; rewrite the paragraph around its main claim instead of performing phrase-by-phrase substitutions. Compare the result against the inventory of numbers, citation and reference keys, `% src:` anchors, `\todo{}` markers, claim strength, attribution, and required qualifiers taken from the draft Steps 4.1–4.7 produced, before this review. Restore the original or report the issue wherever that protected content cannot be shown unchanged.

### Step 5: Update the registries

1. `notes/claims.md`: add this section's slug to Stated in for each claim stated; flip `proposed` → `drafted`; a claim stated without evidence goes to `unsourced` — its statement in the text carries the `\todo` that status requires. Repairs flip the same column: a revision that replaces a claim's last `\todo` with a value that traces (fingerprint read this run) returns `unsourced` → `drafted`, and a revision that restates a claim conceded in response returns `weakened` → `drafted` in Step 5.4, only on the author's yes to the promise that restates it; both wait on `stage-clms-auditor` for `verified`. `verified` rows keep their status; Stated in grows, and loses this section's slug only by Step 4.6's confirmed removal, this skill's one path to `dropped`. Bump `updated:` (real date, §4).
2. `notes/notation.md`: append new Symbols rows (First defined = this section) and Abbreviations rows (First use); bump `updated:` (real date, §4).
3. `notes/outline.md`: this section's row → `drafted` (a substantive revision of a `polished` row also returns it to `drafted`); bump `updated:`.
4. `tasks/<cycle>_promises.md`: for each open box naming this section, ask once "does this revision keep <point id>?" with no recommended answer — a mandatory confirmation point, asked at every involve level (conventions §7.7, §7.9); on a yes, tick that box `- [ ]` → `- [x]` and append this run's `model_trail:` entry, and for a `restate C<n>` box return C<n> `weakened` → `drafted` in `notes/claims.md` (Step 5.1), bumping its `updated:` — all in this run's commit. A no leaves the box open and the claim `weakened`, and the report says so (Step 6.2).

### Step 6: Check, report, commit

1. Run `execs/scpts/lint.sh`, which builds through `execs/run.sh` — a draft must not break compilation: a build this run broke is fixed and rerun, or reported as broken before the commit offer. Grep the section for `\todo{` and report the count with each todo's text. Lint's prose-pattern findings are advisory review prompts, while evidence, reference, anonymity, and `\todo` failures keep their existing force; the ones this draft expects — its own `\todo`s, a `\ref` to a row not built yet — are reported with their owner's command, never worked around.
2. Report: mode (draft/revise), the build and lint verdicts (PDF path, page count, hard failures by kind), claims stated with their new statuses, todos left, symbols added, evidence files read with stamps, staleness warnings, and the section's rough length against its page budget (per-section word counts come from `lint.sh` when `texcount` exists).
3. Close on one next command, first match wins: (1) a table or figure this section references has no file yet → `stage-tabs-builder <ID>` or `stage-figs-designer <ID>`; (2) a claim this run left `drafted` → `stage-clms-auditor <n>_<slug>`; (3) only `\todo`s for values `mates/` does not hold remain → `stage-evid-curator import`, or `stage-evid-curator register <path>` for a manual drop; (4) otherwise `stage-copy-editor <n>_<slug>`. Routes that also hold stay as report lines above it (conventions §7.5).
4. Commit per §1: one commit for the run — section, ledger, notation, outline, and any promise boxes ticked together — subject naming the skill (`stage-sect-drafter: draft 3_method`). Never commit `wkdrs/`.

## Output

- `manus/secs/<n>_<slug>.tex` — the drafted or revised section; its state field is the Sections row status in `notes/outline.md` (output table: Section drafts).
- `notes/claims.md` — Stated in extended, or trimmed by Step 4.6's confirmed removal; statuses flipped to `drafted` / `unsourced` / `dropped` (a repair returns `unsourced` to `drafted`, and Step 5.4's yes returns `weakened` there).
- `notes/notation.md` — appended Symbols and Abbreviations rows.
- `notes/outline.md` — the section's row status and `updated:`.
- `tasks/<cycle>_promises.md` — the boxes this revision keeps, ticked on the author's yes (Step 5.4).
- Chat report: claims stated, the `\todo{}` inventory, evidence read with stamps, staleness warnings, and the recommended next step as its exact command (conventions §7.5). Writes nothing outside these files.
- Provenance (conventions §8): every artifact this run writes under `notes/`, `tasks/`, `cycls/`, or `wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended `model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.
