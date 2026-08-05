---
name: stage-outl-planner
disable-model-invocation: true
description: >-
  Turns the finalized story into a compilable manuscript skeleton: writes notes/outline.md — a
  section table whose page budgets sum within the venue page limit, a figure plan, a table plan,
  and a claim-to-section assignment — creates manus/secs/<n>_<slug>.tex skeletons whose leading
  comment block is the section brief, uncomments their \input lines in manus/main.tex so the
  build stays green, and seeds notes/notation.md. Use when the user runs /stage-outl-planner,
  or asks to outline the paper, budget sections against the page limit, set up section files, or
  turn the story into a skeleton.
---

# Plan Outliner — story to compilable skeleton

**Reply language (conventions §7.6).** `.env` `STAGE_LANG=en|zh` sets chat replies and the Markdown this run writes; resolve it once at the start of the run — `grep -sE '^STAGE_LANG=' .env || true`, folded into the opening load call. Unset or empty → follow the user's dialogue language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request wins. English whatever it says: everything under `manus/`, the response to reviewers, and every structural literal — frontmatter keys, ledger statuses, IDs, paths, bibkeys, venue and metric names. Repo resources (the conventions, this skill) are loaded as-is in English; their zh-CN editions — `SKILL_zh.md` beside this file, and `writing-workflow-conventions.zh-CN.md` for the conventions — are kept in step for human readers only and are never loaded at runtime, so this SKILL.md stays authoritative.

Invocation: `/stage-outl-planner [involve=low|medium|high]` — one manuscript per repo (conventions §5): there is no target argument; the story is `notes/story.md`, the active cycle is its `cycle:` frontmatter, and the page limit is that cycle's `venue.yml`; the optional `involve=` token sets this run's involve level (conventions §7) and is stripped.

**Shared conventions.** `docs/mds/stage-workflow/writing-workflow-conventions.md` is the baseline every STAGE skill shares. Read the whole file at the start of every run — there is no section-selective loading — as its own `Read`, never `cat`-ed through Shell. The sections that bind this skill hardest: conventions §5 (manuscript and cycle resolution), §7 (dialogue), §8 (the registry and the outline / notation schemas), and §9 (the fabrication boundary: §9(a) — skeletons state no facts and no numbers; §9(c) — an unconfirmed page limit is not a limit). This file states what is specific to this skill and wins wherever it is stricter.

**Reusing an earlier load.** Skip the re-read only when the same file's text is still verbatim visible in this conversation. A summary that survived a context compaction does not count, and neither does a memory of having read it — when in doubt, read it again: a wasted read costs one message, a wrong assumption costs the run.

## Role

You give the finalized story its load-bearing frame: which sections exist, what each must argue, which claims land where, how many pages each may spend, and which figures and tables will carry the evidence — the storyboard between `/stage-stry-coach`'s pitch and `/stage-sect-drafter`'s prose. You outline, you do not re-pitch: the story owns why and what; you own where and how much. You never draft section prose, never state a number as content, and never edit the claim ledger — the claim→section map lives in the outline's Claims column.

## Core Principles

1. **Outline, don't re-pitch.** Pull structure out of the story; do not re-derive it. A doubt about the pitch or a contribution goes back to `/stage-stry-coach`; it is never silently fixed here.
2. **Budgets are arithmetic against a confirmed limit.** The Sections budgets must sum within `page_limit_main` from the active cycle's `venue.yml` — references count inside the sum only when `references_in_limit: true`. Always show the arithmetic: per-row budgets, the sum, the limit, the slack. A missing `venue.yml`, or one whose `confirmed:` is empty, means there is no limit to check against, and conventions §9(c) forbids inventing one: route to `/stage-stry-coach` to confirm it; a user who insists on outlining anyway gets budgets, but the outline cannot finalize (Step 6).
3. **Confirm the shape, then auto-draft the briefs.** Two decisions are asked via AskQuestion (one question per call, recommendation marked): the section list with budgets, then the figure and table plan. After those, draft every brief autonomously from story, claims, and evidence; ask a targeted follow-up only when a brief is undecidable without the user. At involve `low`, adopt the drafted plans after showing them with the arithmetic — Step 0's overwrite confirmations and the commit offer are always asked. If AskQuestion is unavailable (headless runs), fall back to plain text — still one decision at a time.
4. **Every claim has a home.** Every ID in `notes/claims.md` appears in at least one Sections row's Claims cell; a claim no section will state is raised with the user, never dropped silently; a Claims cell uses only IDs that exist in the ledger. The ledger itself is not edited here.
5. **Skeletons carry briefs, not prose.** The leading comment block is the section brief — the drafter's standing orders; the body is one `\section` line and one `\todo{...}`. No facts, no numbers: under conventions §9(a) a number enters `manus/` only when a drafter traces it to a fingerprinted `mates/` entry, so a skeleton carries none.
6. **The skeleton must compile.** After wiring, run `execs/run.sh` (one Shell call) — deterministic checks live in scripts, judgment lives here. The run ends with a green build or an honest statement of what is broken and why.
7. **Incremental writes.** Outline before skeletons, each skeleton written before the next, notation last — chats end, files do not.

## Workflow

### Step 0: Load and gate

1. Opening load, one message where possible: the conventions file (its own `Read`); `notes/story.md`; `notes/claims.md`; `notes/outline.md` and `notes/notation.md` where present; `manus/main.tex`; one Shell call for `date +%F` (conventions §4) plus a listing of `manus/secs/` and `cycls/`. Then read the active cycle's `cycls/<cycle>/venue.yml`.
2. Gate on the story: missing, or `finalized:` empty → the outline would be guesswork; recommend `/stage-stry-coach` and stop unless the user explicitly proceeds — then the report names what the outline was built on.
3. Gate on the limit per Principle 2.
4. **Drafted prose is never overwritten, outline or no outline.** Before anything is created, list what `manus/secs/` already holds and read every file that is more than a skeleton — an adopted repository arrives with real sections and no `notes/outline.md`, so a guard attached only to the re-run branch below would not fire exactly where it is needed most. Any such file keeps its content: it enters the Sections table at the status its text has earned, its `<n>_` prefix is assigned or corrected by a rename this run records, and a skeleton is created only where no file exists. Overwriting one is a per-file question, never a default.
5. An existing `notes/outline.md` → ask which re-run this is, via AskQuestion: **reconcile** (repair rows against the files that actually exist — recommended once drafting has started), **extend** (add sections, figures, or tables; keep the rest), or **re-outline** (from scratch — confirm file by file before touching any `manus/secs/` file whose outline Status has moved past `skeleton` or whose content has outgrown its brief; drafted prose is never overwritten).

### Step 1: Propose the section plan

Draft the Sections table from the story and the venue's shape: `#` from `0` (`0_abstract`, `1_intro`, …), `File` `<n>_<slug>.tex`, `Title`, `Budget (pages)` in quarter-page steps, `Claims` (the IDs this section states or supports), `Status` `planned`. Give every claim a home: contribution claims land in abstract and intro plus the method or experiment section that delivers them; performance claims land where their table or figure will sit. For example:

```markdown
| # | File | Title | Budget (pages) | Claims | Status |
|---|------|-------|----------------|--------|--------|
| 1 | 1_intro.tex | Introduction | 1.25 | C1, C2, C3 | planned |
| 3 | 3_method.tex | Method | 2.25 | C1, C2 | planned |
```

Show the full table with the budget arithmetic (Principle 2) — e.g. `sum 7.75 / limit 8 (references outside) / slack 0.25` — and the claim-coverage line; rebalance until the sum fits; confirm via AskQuestion ("looks good" / "edit the list" / "change granularity").

### Step 2: Propose the figure and table plan

Figures, teaser first: `F1` is the figure that tells the story alone — its row exists before any results figure. Rows per conventions §8 — `ID`, `File` (`manus/figs/<slug>.pdf`), `Purpose` (what it must show, not how), `Section`, `Source` (the planned source under `manus/figs/srcs/`, or the `mates/` path for imported artwork), `Status` `planned`. Tables — `ID`, `File` (`manus/tabs/<slug>.tex`), `Purpose`, `Section`, `Evidence` (the `mates/` path the data will come from; `—` when nothing imported covers it yet, each `—` named for `/stage-evid-curator`), `Status` `planned`. Show both tables in the reply, then confirm via AskQuestion (conventions §7.12: rows the user cannot see are rows nobody reviewed).

### Step 3: Write `notes/outline.md`

Per the conventions §8 schema: frontmatter `finalized:` (empty until Step 6) and `updated:` (real date); the three confirmed tables `## Sections`, `## Figures`, `## Tables`.

### Step 4: Create skeletons and wire the build

Per Sections row, in order:

1. Create `manus/secs/<n>_<slug>.tex`. The leading comment block is the section brief — purpose, claims (state vs support), evidence paths, budget, figures and tables landing here; the body is one `\section{<Title>}` line (`0_abstract` carries abstract text instead of a `\section`) and one `\todo{...}` — nothing else (Principle 5):

```tex
% ---- Section brief: 3_method (stage-outl-planner, 2026-08-02) ----
% Purpose: present the decoupled two-stage decoder; argue why decoupling wins.
% Claims: states C2; supports C1.
% Evidence: mates/<slug>/metds/framework.md#decoder; mates/<slug>/wkdrs/digests/abl_decoder.md
% Budget: 2.25 pages (outline row 3).
% Figures/Tables here: F2 (architecture), T2 (ablation).
% -------------------------------------------------------------------
\section{Method}
\todo{draft per the brief — /stage-sect-drafter 3}
```

2. Uncomment the matching `\input{secs/<n>_<slug>}` line in `manus/main.tex` — only lines whose skeleton now exists. When an uncommented input supersedes a placeholder block `main.tex` shipped with (the stock abstract), move that placeholder text into the skeleton instead of deleting it.
3. After the last row: run `execs/run.sh` and fix what it reports — a missing brace, a wrong slug, a bad input path — until the build is green (Principle 6).

### Step 5: Seed `notes/notation.md`

Per the conventions §8 schema, seeded small — `/stage-sect-drafter` appends, `/stage-copy-editor` enforces. `## Symbols`: the core symbols the key idea already fixes; `First defined` `—` until a section defines them. `## Terminology canon`: `Use | Never | Notes` rows for every name the story settled — the method name and the variant spellings visible in `mates/` docs. `## Abbreviations`: expansions, `First use` `—`. Frontmatter `updated:` (real date). Every row traces to the story or an imported doc; nothing is invented here.

### Step 6: Finalize, report, commit

Set outline `finalized:` (real date) only when all of: both plans user-confirmed, the budget sum within the confirmed limit, every skeleton created with its `\input` uncommented, and the build green — otherwise leave it empty and say exactly what blocks it. Report in ≤300 words: the budget arithmetic, claim coverage (any homeless claim by ID), files created, the build result, notation rows seeded, and the one next command — `/stage-sect-drafter <section>` for the first section (resolved per conventions §5), `/stage-tabs-builder` and `/stage-figs-designer` once their evidence lands, `/stage-flow-status` for the whole map. Offer once to commit what this run wrote — `stage-outl-planner: <N> sections for <cycle>` (conventions §1). Declining is fine.

## Output

- `notes/outline.md` — created here; `/stage-sect-drafter`, `/stage-figs-designer`, and `/stage-tabs-builder` update their own rows afterward. Registry state: `finalized:` plus per-row `Status` — sections `planned | skeleton | drafted | polished | frozen`; figures and tables `planned | sketch | draft | final`.
- `manus/secs/<n>_<slug>.tex` — one skeleton per Sections row: brief comment block, `\section` line, one `\todo`; each matching `\input` line uncommented in `manus/main.tex`; the result compiles via `execs/run.sh`.
- `notes/notation.md` — created here; `/stage-sect-drafter` appends, `/stage-copy-editor` enforces. Registry state: `updated:`.
- In chat: the ≤300-word report. Never written here: section prose, `notes/claims.md`, `mates/`, `venue.yml`.
- Provenance (conventions §8): every artifact this run writes under `notes/`, `tasks/`, `cycls/`, or `wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended `model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.
