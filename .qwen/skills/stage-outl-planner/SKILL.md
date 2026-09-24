---
name: stage-outl-planner
disable-model-invocation: true
description: >-
  Turn the finalized story into a compilable skeleton: notes/outline.md with section page budgets
  inside the venue limit, figure and table plans, and a claim-to-section map; section stubs under
  manus/secs/ wired into manus/main.tex so the build stays green; and a seeded notes/notation.md. Use
  when the user runs /stage-outl-planner, or asks to outline the paper, budget sections against the
  page limit, set up section files, or turn the story into a skeleton.
argument-hint: "[DESCRIPTION] [involve=high]"
---

# Plan Outliner — story to compilable skeleton

Invocation: `stage-outl-planner [DESCRIPTION] [involve=high]` — one manuscript per repo (conventions §5): there is no target argument; the story is `notes/story.md`, the active cycle is its `cycle:` frontmatter, and the page limit is that cycle's `venue.yml`; the optional `involve=` token sets this run's involve level (conventions §7) and is stripped. With no target to resolve, whatever remains after that token is a description (conventions §7.13): in your own words, what this run is for — "the ablation has to fit, take it out of §2" is a lead this run may follow and may record as the rationale behind a budget, never an answer standing in for the section list and the figure/table plan, which are confirmed with the arithmetic shown at every involve level.

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` whole at the start of every run; it is the baseline every STAGE skill shares, and this file wins wherever it is stricter. Read `.env` once for the `STAGE_LANG`, `INVOLVE`, `STAGE_*_MODEL`, and runtime values this run needs, and reuse `.env` values and conventions text still verbatim visible in this conversation. Resolve the language once under conventions §7.6 — an explicit request first, then a valid `STAGE_LANG`, then the user's dialogue language — for replies and the Markdown this run newly writes; everything under `manus/`, the response to reviewers, and every structural literal stay English, and an existing document keeps the language it was written in. Resolve the involve level once under conventions §7.7, and the tier value once under §11.6. Repository resources load in English: a `references/*_zh.md` edition is for human readers and is never loaded at runtime.

## Role

You give the finalized story its load-bearing frame: which sections exist, what each must argue, which claims land where, how many pages each may spend, and which figures and tables will carry the evidence — the storyboard between `stage-stry-coach`'s pitch and `stage-sect-drafter`'s prose. You outline, you do not re-pitch: the story owns why and what; you own where and how much. You never draft section prose, never state a number as content, and never edit the claim ledger beyond the `Stated in` slugs a rename changes — the claim→section map lives in the outline's Claims column.

## Core Principles

1. **Outline, don't re-pitch.** Pull structure out of the story; do not re-derive it. A doubt about the pitch or a contribution goes back to `stage-stry-coach`; it is never silently fixed here.
2. **Budgets are arithmetic against a confirmed limit.** The Sections budgets must sum within `page_limit_main` from the active cycle's `venue.yml` — references count inside the sum only when `references_in_limit: true`, and then as one `+ refs <pages>` term on the arithmetic line (`sum 7.0 + refs 1.0 = 8.0 / limit 8`), never as a Sections row, which would have no file (drift, conventions §5.6). Always show the arithmetic: per-row budgets, the sum, the limit, the slack. A missing `venue.yml`, one whose `confirmed:` is empty, or a blank `page_limit_main` means there is no limit to check against, and conventions §9(c) forbids inventing one: route to `stage-stry-coach` to confirm it; a user who insists on outlining anyway gets budgets, but the outline cannot finalize (Step 6).
3. **Confirm the shape, then auto-draft the briefs.** Two decisions are asked via `ask_user_question` (one question per call, recommendation marked): the section list with budgets, then the figure and table plan. After those, draft every brief autonomously from story, claims, and evidence; ask a targeted follow-up only when a brief is undecidable without the user. At every involve level the two plan confirmations stay asked — they settle the decision this slash-only skill exists for (conventions §7.7, §11.1) — as do Step 0's overwrite confirmations; the commit follows the level (conventions §1.6). If `ask_user_question` is unavailable (headless runs), fall back to plain text — still one decision at a time.
4. **Every claim has a home.** Every ID in `notes/claims.md` not at `dropped` appears in at least one Sections row's Claims cell; a claim no section will state is raised with the user, never dropped silently; a Claims cell uses only IDs that exist in the ledger and are not `dropped`. The ledger itself is not edited here, except the `Stated in` slugs the Step 4 rename changes.
5. **Skeletons carry briefs, not prose.** The leading comment block is the section brief — the drafter's standing orders; the body is one `\section` line and one `\todo{...}` — the skeleton placeholder conventions §9a sanctions, replaced by the first draft. No facts, no numbers: under conventions §9(a) a number enters `manus/` only when a drafter traces it to a fingerprinted `mates/` entry, so a skeleton carries none.
6. **The skeleton must compile.** After wiring, run `execs/run.sh` (one `run_shell_command` call) — deterministic checks live in scripts, judgment lives here. The run ends with a green build or an honest statement of what is broken and why.
7. **Incremental writes.** Outline before skeletons, each skeleton written before the next, notation last — chats end, files do not.

8. **Fan out the pre-read (§6).** Step 0 must read every `manus/secs/` file that is more than a skeleton before anything is created — an adopted repository arrives full of them — so more than 6 such files → one delegate per file, on the READ tier's model (conventions §11.6), where the harness can name one, each returning that file's earned status and its outline row and nothing else. Step 4 stays here (§6.7): every brief is already drafted in this context, so a skeleton is a transcription that finishes before a delegate would return, and Principle 7 writes them one after another. The build at the end is the gate, run here (§6.3).

## Workflow

**Where this run executes.** This run's tier is PLAN (conventions §11.6); it stays in the session that started it, on the session's model. When the `STAGE_PLAN_MODEL` value names a model that is not an alias of the session's, say so in one line at the start — the tier, that model, and the one way to get it: switch the session's model — then continue here.

### Step 0: Load and gate

1. Read the conventions as Shared conventions says, then `notes/story.md`; `notes/claims.md`; `mates/MANIFEST.md`; `notes/outline.md` and `notes/notation.md` where present; `manus/main.tex`; one `run_shell_command` call for `date +%F` (conventions §4) plus a listing of `manus/secs/` and `cycls/`. Then read the active cycle's `cycls/<cycle>/venue.yml`.
2. Gate on the story: missing, or `finalized:` empty → the outline would be guesswork; recommend `stage-stry-coach` and stop unless the user explicitly proceeds — then the report names what the outline was built on.
3. Gate on the limit per Principle 2.
4. **Drafted prose is never overwritten, outline or no outline.** Before anything is created, list what `manus/secs/` already holds and read every file that is more than a skeleton — an adopted repository arrives with real sections and no `notes/outline.md`, so a guard attached only to the re-run branch below would not fire exactly where it is needed most. Any such file keeps its content: it enters the Sections table at the status its text has earned, under the `<n>_` prefix Step 1 proposes for it — the rename is Step 4's, made only after Step 1 confirms that prefix, so nothing moves here — and a skeleton is created only where no file exists. Overwriting one is a per-file question, never a default.
5. An existing `notes/outline.md` → ask which re-run this is, via `ask_user_question`: **reconcile** (repair rows against the files that actually exist — recommended once drafting has started), **extend** (add sections, figures, or tables; keep the rest), or **re-outline** (from scratch — confirm file by file before touching any `manus/secs/` file whose outline Status has moved past `skeleton` or whose content has outgrown its brief; drafted prose is never overwritten).
6. **What a re-run keeps.** `reconcile` and `extend`: every existing row keeps its Status and Claims, only new or repaired rows enter as Steps 1–2 write them, `notes/notation.md` is appended to and never rewritten, and Steps 1–2 show and re-confirm only the rows that changed — that answer is the plan confirmation Step 6 needs. `re-outline`: a row whose Status has moved past `planned` or `skeleton` keeps it unless the user confirms its reset in item 5's file-by-file question. With nothing drafted yet, `extend` is the recommended answer.

### Step 1: Propose the section plan

Draft the Sections table from the story and the venue's shape: `#` from `0` (`0_abstract`, `1_intro`, …), `File` `<n>_<slug>.tex` (a file Step 0 found shows `<old>.tex → <n>_<slug>.tex` where its prefix changes, so adopting the prefixes adopts the rename), `Title`, `Budget (pages)` in quarter-page steps, `Claims` (the IDs this section states or supports), `Status` `planned`. Give every claim a home: contribution claims land in abstract and intro plus the method or experiment section that delivers them; performance claims land where their table or figure will sit. For example:

```markdown
| # | File | Title | Budget (pages) | Claims | Status |
|---|------|-------|----------------|--------|--------|
| 1 | 1_intro.tex | Introduction | 1.25 | C1, C2, C3 | planned |
| 3 | 3_method.tex | Method | 2.25 | C1, C2 | planned |
```

Show the full table with the budget arithmetic (Principle 2) — e.g. `sum 7.75 / limit 8 (references outside) / slack 0.25` — and the claim-coverage line; rebalance until the sum fits; confirm via `ask_user_question` — each option a consequence (conventions §7.3), e.g. "adopt: these rows and their <n>_ prefixes go on to the figure/table plan; renumbering once drafting starts takes a re-outline run" / "edit rows: redrafted and re-shown with the arithmetic" / "merge or split sections: budgets recomputed and re-shown".

### Step 2: Propose the figure and table plan

Figures, teaser first: `F1` is the figure that tells the story alone — its row exists before any results figure. Rows per conventions §8 — `ID`, `File` (`manus/figs/<slug>.pdf`), `Purpose` (what it must show, not how), `Section`, `Source` (the planned source under `manus/figs/srcs/`, or the `mates/` path for imported artwork), `Status` `planned`. Tables — `ID`, `File` (`manus/tabs/<slug>.tex`), `Purpose`, `Section`, `Evidence` (the `mates/` path the data will come from, named only from a `mates/MANIFEST.md` entry whose `covers:` fits; `—` when no entry covers it yet, each `—` named for `stage-evid-curator`), `Status` `planned`. Show both tables in the reply, then confirm via `ask_user_question` (conventions §7.12: rows the user cannot see are rows nobody reviewed).

### Step 3: Write `notes/outline.md`

Per the conventions §8 schema: frontmatter `finalized:` (empty until Step 6) and `updated:` (real date); the three confirmed tables `## Sections`, `## Figures`, `## Tables`.

### Step 4: Create skeletons and wire the build

Per Sections row, in order:

1. A row whose file Step 0 found keeps that file, its content, and its earned Status: where Step 1 confirmed a new prefix, `git mv` it to `<n>_<slug>.tex` and rewrite the old `<n>_<slug>` in every ledger `Stated in` cell and every open `- [ ]` box under `tasks/` that names it — that token only, the rest of the box untouched — listing each old → new in the report and the commit message. Otherwise create `manus/secs/<n>_<slug>.tex` and set its Sections row from `planned` to `skeleton`. The leading comment block is the section brief — purpose, claims (state vs support), evidence paths (`mates/MANIFEST.md` entries only), budget, figures and tables landing here; the body is one `\section{<Title>}` line (`0_abstract` wraps its text and `\todo` in `\abstract{...}` instead of a `\section`) and one `\todo{...}` — nothing else (Principle 5):

```tex
% ---- Section brief: 3_method (stage-outl-planner, 2026-08-02) ----
% Purpose: present the decoupled two-stage decoder; argue why decoupling wins.
% Claims: states C2; supports C1.
% Evidence: mates/<slug>/metds/framework.md#decoder; mates/<slug>/wkdrs/digests/abl_decoder.md
% Budget: 2.25 pages (outline row 3).
% Figures/Tables here: F2 (architecture), T2 (ablation).
% -------------------------------------------------------------------
\section{Method}
\todo{draft per the brief — stage-sect-drafter 3}
```

2. Uncomment, or repoint after item 1's rename, the matching `\input{secs/<n>_<slug>}` line in `manus/main.tex`, or add one in outline order where the shipped example lines use another slug — only for files that now exist. The stock abstract moves into `0_abstract` inside `\abstract{...}`, because `main.tex` inputs that file in the preamble. Once the first body `\input` is live, delete the shipped placeholder body under `%% Placeholder body` (`\section{Introduction}` and its scaffold `\todo`): it is scaffolding, not user text. While the shipped `\title{Untitled STAGE Manuscript}` stands, replace it with the working title the user gives, asked once as an open question (conventions §7.3).
3. After the last row: run `execs/run.sh` and fix what it reports — a missing brace, a wrong slug, a bad input path — until the build is green (Principle 6).

### Step 5: Seed `notes/notation.md`

Per the conventions §8 schema, seeded small — `stage-sect-drafter` appends, `stage-copy-editor` enforces. `## Symbols`: the core symbols the key idea already fixes; `First defined` `—` until a section defines them. `## Terminology canon`: `Use | Never | Notes` rows for every name the story settled — the method name and the variant spellings visible in `mates/` docs. `## Abbreviations`: expansions, `First use` `—`. Frontmatter `updated:` (real date). Every row traces to the story or an imported doc; nothing is invented here.

### Step 6: Finalize, report, commit

Set outline `finalized:` (real date) only when all of: both plans user-confirmed, the budget sum within the confirmed limit, every skeleton created with its `\input` uncommented, and the build green — otherwise leave it empty and say exactly what blocks it. Report in ≤300 words: the budget arithmetic, claim coverage (any homeless claim by ID), files created, the build result, notation rows seeded, and the one next command — `stage-sect-drafter <section>` for the first section (resolved per conventions §5), `stage-tabs-builder` and `stage-figs-designer` once their evidence lands, `stage-flow-status` for the whole map. Offer once to commit what this run wrote — `stage-outl-planner: <N> sections for <cycle>` (conventions §1). Declining is fine.

## Output

- `notes/outline.md` — created here; `stage-sect-drafter`, `stage-figs-designer`, `stage-tabs-builder`, and `stage-copy-editor` update their own rows afterward. Output-table state: `finalized:` plus per-row `Status` — sections `planned | skeleton | drafted | polished`; figures and tables `planned | sketch | draft | final`.
- `manus/secs/<n>_<slug>.tex` — one skeleton per Sections row with no file yet: brief comment block, `\section` line, one `\todo`; a file Step 0 found keeps its content, renamed by `git mv` where its confirmed prefix changed; each `\input` line uncommented or added in `manus/main.tex`, the shipped placeholder body removed, and the shipped `\title` replaced by the user's working title; the result compiles via `execs/run.sh`.
- `notes/notation.md` — created here; `stage-sect-drafter` appends, `stage-copy-editor` enforces. Output-table state: `updated:`.
- In chat: the ≤300-word report. Never written here: section prose, `notes/claims.md` beyond a renamed `Stated in` slug, `tasks/` beyond a renamed slug in an open box, `mates/`, `venue.yml`.
- Provenance (conventions §8): every artifact this run writes under `notes/`, `tasks/`, `cycls/`, or `wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended `model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.
