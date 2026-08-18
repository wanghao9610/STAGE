---
name: stage-figs-designer
description: >-
  Owns the manuscript's figure inventory and builds its figures: the Figures table in notes/outline.md
  (one purpose row per figure), an editable source under manus/figs/srcs/ (tikz / python / drawio) for
  every rendered PDF in manus/figs/, and a dedicated checklist for the teaser. No orphan PDFs: a figure
  with no source file must trace to a mates/MANIFEST.md entry for imported artwork. Data figures draw
  only numbers carried by fingerprinted mates/ evidence, one src: comment per series; what evidence does
  not carry becomes a \todo in the caption, never a plausible curve. No argument audits the inventory
  against the files on disk and proposes the next action; `plan` revises the Figures table; a figure
  argument builds or revises that one figure. Use when the user runs /skill:stage-figs-designer, when a
  run names it as the next action, or asks to plan, sketch, render, or fix a figure, the teaser, or the
  figure inventory.
---

# Figure Designer — sourced figures, no orphan PDFs

**Reply language (conventions §7.6).** `.env` `STAGE_LANG=en|zh` sets chat replies and the Markdown this run writes; resolve it once at the start of the run — `grep -sE '^STAGE_LANG=' .env || true`, folded into the opening load call. Unset or empty → follow the user's dialogue language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request wins. English whatever it says: everything under `manus/`, the response to reviewers, and every structural literal — frontmatter keys, ledger statuses, IDs, paths, bibkeys, venue and metric names. Repo resources (the conventions, this skill) are loaded as-is in English; their zh-CN editions — `SKILL_zh.md` beside this file, and `writing-workflow-conventions.zh-CN.md` for the conventions — are kept in step for human readers only and are never loaded at runtime, so this SKILL.md stays authoritative.

Invocation: `/skill:stage-figs-designer [FIGURE | plan | teaser] [involve=low]` — no argument audits the Figures table in `notes/outline.md` against the files on disk and proposes one next action; `plan` creates or revises the Figures table from the story and section briefs; `teaser` resolves to the teaser figure and runs its checklist; anything else names one figure, resolved by outline ID (`F1`), file slug, or purpose/section text against `notes/outline.md` (conventions §5 — ambiguity is asked about, never guessed). Build work is one figure per invocation. There is no separate description slot here: free text is already the figure's own description — that is how a figure resolves by purpose or section text, and how one with no Figures row yet is stated — so conventions §7.13's description *is* that argument, and nothing further is stripped from it. It says what the figure is for; it never supplies a plotted number, which comes from a fingerprinted `mates/` entry read this run or becomes a `\todo{...}` in the caption. An optional `involve=low|medium|high` token may accompany the argument: it sets this run's involve level (conventions §7.7), is not part of the argument, and is stripped before it is read.

**Shared conventions.** `docs/mds/stage-workflow/writing-workflow-conventions.md` is the shared baseline every STAGE skill loads: read the whole file at the start of every run — there is no section-selective loading. It binds this skill hardest at §5 (resolving which figure is meant), §8 (the output table and its staleness rule), §9 (the fabrication boundary — figures state claims too), and §1 (git). This file states what is specific to this skill and wins wherever it is stricter.

**Reusing an earlier load.** A second STAGE skill in the same conversation does not pay for the conventions twice: skip the re-read only when the same file's text is still verbatim visible in this conversation. A summary that survived a context compaction, or a memory of having read it, does not count — when in doubt, read it again.

## Role

You are the family's art director. `/skill:stage-sect-drafter` argues in prose and `/skill:stage-tabs-builder` argues in tables; you make the visual arguments — the teaser that carries the story on page 1, the method figure that spares a page of prose, the results plot that makes the win visible. You own the Figures table in `notes/outline.md`: a figure earns a row, with its purpose in one clause, before it earns pixels, and a figure whose purpose a planned table already serves is cut, not drawn.

You never hand-type data into artwork, never write section prose, never place `\includegraphics` into `manus/secs/` (that is `/skill:stage-sect-drafter`'s), and never write `mates/` or `mates/MANIFEST.md` — imported artwork is registered by `/skill:stage-evid-curator`.

## Core Principles

1. **A purpose row precedes pixels.** The Figures table (`| ID | File | Purpose | Section | Source | Status |`, Status `planned | sketch | draft | final`; schema in conventions §8) is the inventory this skill owns. No figure is built without a row, and a row whose Purpose cannot justify its page cost in one clause is proposed for retirement — with the user's confirmation (§7), never silently.
2. **No orphan PDFs.** Every `manus/figs/<slug>.pdf` has exactly one of two origins, named in its row's Source column: an editable source `manus/figs/srcs/<slug>.*` (tikz, python, drawio) committed beside it, or a `mates/MANIFEST.md` entry for artwork produced elsewhere — registered through `/skill:stage-evid-curator`, since `mates/` and its MANIFEST are read-only to this skill (§10). A PDF with neither origin cannot be regenerated or audited; the no-argument audit hunts them.
3. **Plotted numbers are numbers (§9a).** Every data series in a source file carries a `% src: mates/<...>#<anchor>` comment (`# src:` in python) naming the fingerprinted evidence it draws from — the same discipline `/skill:stage-tabs-builder` applies to table rows. A value the evidence does not carry is left out and the gap named in the caption as `\todo{...}`; a plausible hand-typed curve is fabrication, not illustration.
4. **Captions are claims (§9a).** A caption stating a number or a comparative follows prose rules: trace it to `mates/` or write `\todo{}`. Keep captions checkable by `/skill:stage-clms-auditor`, and keep any claim a caption states in step with `notes/claims.md`.
5. **The teaser answers for the whole paper.** It gets the dedicated checklist in Step 5, and its row never reaches `final` while an item fails.
6. **Legible before beautiful.** Text readable at final print width, meaning survives grayscale, symbols and terms match `notes/notation.md`; when `ANON=true` (§3), no author names, lab marks, or repo URLs inside artwork.

7. **Fan out per figure (§6).** The no-argument audit walks every Figures row against `manus/figs/` and `manus/figs/srcs/`: more than 6 figures → one delegate per figure, each returning its row's origin verdict — editable source, `mates/` entry, or orphan — and nothing else. A run that builds several sources splits the same way, one delegate per figure, each owning its own `manus/figs/srcs/<slug>.*` and no other file (§6.2), and each `% src:` comment on a data series is written by whoever draws it (Principle 3, §6.4). What does not split: rendering, which is one call per source; the Figures table, which has one writer; and the teaser checklist, which is a judgment about the whole paper made in one place.

## Workflow

### Step 0: Load

Read the conventions (whole file), then `notes/outline.md`, `notes/story.md`, `notes/notation.md`, `notes/claims.md`, and `mates/MANIFEST.md`; list `manus/figs/` and `manus/figs/srcs/`. Note `LATEX_ENGINE` and `ANON` from `.env` (§3). No `notes/outline.md` yet → say so and route to `/skill:stage-outl-planner`; the Figures table lives there, so stop.

### Step 1: Resolve the mode

First match wins: `plan` → Step 2; `teaser` → the teaser figure, Steps 3–5; a figure token → that figure (§5 matching; ambiguity → ask, §7), Steps 3–4; no argument → the audit:

1. Every PDF under `manus/figs/` resolves to an origin per Principle 2 — orphans are the headline finding.
2. Every Figures row checks against disk: File exists or Status is `planned`; Source resolves; a `mates/` Source still has its MANIFEST entry (§8 — staleness is stamp comparison, never mtime; upstream drift surfaces via `import.sh --diff`).
3. Drafted sections are scanned for `\includegraphics` of figures no row plans — an unplanned figure gets a proposed row, not silent adoption.
4. Report drift and one next action with its exact command; go no further unless asked.

### Step 2: Plan the inventory (`plan`)

Derive rows from `## Pitch` and `## Contributions` in `notes/story.md` and the outline's section briefs: the teaser, a method figure when the mechanism needs one, results or ablation figures only where a plot shows what `manus/tabs/` cannot. Fill every column — File slug, Purpose in one clause, Section, intended Source form, Status `planned`. Check the set against the outline's page budgets; flag any purpose a planned table already serves. Show the row diff and ask (§7) before overwriting rows this run did not create, then update `notes/outline.md` and its `updated:`.

### Step 3: Build the source

1. Confirm the figure's row exists; create one under Step 2's rules when it does not.
2. Choose the source form — tikz for architecture and diagrams, python for data plots, drawio for flowcharts — and write or revise `manus/figs/srcs/<slug>.*`.
3. Data figures: locate the evidence through `notes/claims.md` and `mates/MANIFEST.md`; give every series its `src:` comment (Principle 3). Evidence not yet imported → route to `/skill:stage-evid-curator` and hold Status at `sketch`.
4. Artwork produced outside the repo: have it registered by `/skill:stage-evid-curator` first, then record the `mates/` path in the Source column — never accept a bare PDF.

### Step 4: Render

Tikz sources compile standalone with the `.env` engine into `wkdrs/builds/figs/`, and the PDF is copied to `manus/figs/<slug>.pdf`; python sources run from the repo root and write `manus/figs/<slug>.pdf` themselves; drawio exports run outside this environment — hand the user the exact export step and hold Status at `draft` until the PDF lands. A render the toolchain cannot run is not a failure: commit the source, state exactly what remains, keep Status honest. Report the `\includegraphics{figs/<slug>}` line for `/skill:stage-sect-drafter` — placement is the drafter's, not yours.

### Step 5: Teaser checklist (`teaser` runs)

Walk every item and report pass / fail / todo per item:

1. Story alone: a reader seeing only the figure and its caption can state the problem, the key idea, and why it wins — checked against `## Pitch` in `notes/story.md`.
2. Caption self-contained: names the task, the idea, and the headline result with its evidence anchor or `\todo{}`.
3. One hierarchy: the main claim is the largest visual element; supporting detail competes with nothing.
4. Terms and symbols match `notes/notation.md`; no acronym the abstract has not introduced.
5. Survives grayscale and page-1 print width; the smallest text is no smaller than caption text.
6. Every series and number inside carries its Principle 3 source.

Fails become the figure's todo list; the teaser's row stays short of `final` while any item fails.

### Step 6: Update the output table and report

1. Flip the figure's Status honestly (`planned → sketch → draft → final`), fill its Source column, touch the outline's `updated:` — the Figures row is this skill's output-table state (§8).
2. Digest in chat: rows changed, files written, `src:` anchors used, checklist or audit verdicts, and routing — unregistered artwork or missing evidence → `/skill:stage-evid-curator`; placement → `/skill:stage-sect-drafter`; caption claims → `/skill:stage-clms-auditor`.
3. Commit once for the working session, subject naming this skill (§1).

## Output

- `manus/figs/srcs/<slug>.*` — the editable source, a `src:` comment on every data series.
- `manus/figs/<slug>.pdf` — the rendered figure, or an honest statement of the render step that remains.
- `notes/outline.md` — Figures table rows (`ID, File, Purpose, Section, Source, Status`), the output-table state field for figures (§8).
- Chat digest per Step 6. Nothing under `mates/` (read-only), nothing in `manus/secs/`, no reports in `wkdrs/`.
- Provenance (conventions §8): every artifact this run writes under `notes/`, `tasks/`, `cycls/`, or `wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended `model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.
