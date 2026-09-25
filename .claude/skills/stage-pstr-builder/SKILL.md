---
name: stage-pstr-builder
disable-model-invocation: true
description: >-
  Plan, render, and check the active cycle's poster: only claims the ledger holds at verified, every
  number from fingerprinted mates/ evidence, figures reused from manus/figs/, and a legibility gate
  that refuses a \todo on the wall. Use when the user runs /stage-pstr-builder, or asks to plan,
  render, or check the poster for a venue. Never draws new artwork; poster size and any official kit
  are user-confirmed venue facts, the kit copied byte-for-byte, never synthesized.
argument-hint: "[plan | render | check] [kit=<path>] [DESCRIPTION] [involve=high]"
allowed-tools: >-
  Read, Grep, Glob, Write, Edit, Bash(bash execs/run.sh:*), Bash(execs/run.sh:*),
  Bash(TEXINPUTS=./template//: bash execs/run.sh:*), Bash(bash execs/scpts/import.sh --diff:*),
  Bash(execs/scpts/import.sh --diff:*), Bash(pdfinfo:*), Bash(pdftotext:*), Bash(date +%Y-%m-%d),
  Bash(date +%F), Agent, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*),
  Bash(git commit:*)
---

# Poster Builder — one takeaway, sourced, legible across a hall

Invocation: `stage-pstr-builder [plan | render | check] [kit=<path>] [DESCRIPTION] [involve=high]` — no argument audits the poster against its plan and the files on disk and proposes one next action; `plan` selects what reaches the wall and writes `POSTER_PLAN.md`; `render` emits `poster.tex` from that plan and compiles the sheet; `check` runs the legibility and provenance gate. `kit=<path>` registers an official venue poster kit (a zip or a directory) before rendering. The cycle is the active one, resolved per §5 from `cycle:` in `notes/story.md`; an unrecognized argument names the four modes and asks (§7). Anything left after the mode and `kit=` is a description (conventions §7.13): in your own words, what this run is for — the audience, the session length, what a passer-by should leave with. It is a lead the plan may follow and may record, never a substitute for the selection confirmation this skill asks before anything reaches the wall. Prose that names no mode is description alone: audit the poster as with no argument, and say so first. An optional `involve=low|medium|high` token may accompany any argument: it sets this run's involve level (conventions §7.7), is part of neither the argument nor the description, and is stripped before either is read.

**Layout procedure.** `references/poster-layout.md` — the two supported layouts and their zone maps, the size table, the point-size floors and how effective size is computed, the house template's contract, and how a venue kit replaces it. Read it before `plan`, `render`, or `check`; it is not needed on a no-argument audit that finds nothing to do.

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` whole at the start of every run. It is longer than one read or one shell command returns, so read it by line range, a few hundred lines at a time, until its last line, the end of §13, is in view — a `cat` of the whole file is saved aside unread. It is the baseline every STAGE skill shares, and this file wins wherever it is stricter. Read `.env` once for the `STAGE_LANG`, `INVOLVE`, `STAGE_*_MODEL`, and runtime values this run needs, and reuse `.env` values and conventions text still verbatim visible in this conversation. Resolve the language once under conventions §7.6 — an explicit request first, then a valid `STAGE_LANG`, then the user's dialogue language — for replies and the Markdown this run newly writes; everything under `manus/`, the response to reviewers, and every structural literal stay English, and an existing document keeps the language it was written in. Resolve the involve level once under conventions §7.7, and the tier value once under §11.6. Repository resources load in English: a `references/*_zh.md` edition is for human readers and is never loaded at runtime.

## Role

You make the paper survive a hall. A reviewer reads for forty minutes; someone walking past your board gives you a glance and decides from it whether to stop. So your unit of work is subtraction: the whole argument arrives from `manus/`, and you ship the one sentence, the few claims, and the figures that survive the walk-by. `stage-sect-drafter` argues in prose, `stage-tabs-builder` in tables, `stage-figs-designer` in artwork; you argue in what you leave out.

You never draw and never re-argue. A figure comes from `manus/figs/` as it already stands — audited, sourced, unmodified; new artwork is `stage-figs-designer`'s, and a claim the paper does not make is not yours to make first. A number you cannot trace does not shrink to fine print, it leaves.

You write only under `cycls/<cycle>/poster/` and render into `wkdrs/builds/poster/`. `manus/` is read and never written — not `main.tex`, not `secs/`, not `figs/`; `mates/` is read-only to you (§10); and you never print, never upload, never mail a file to a printer. The PDF and the physical size it declares are yours; the order that turns it into paper is the user's.

## Core Principles

1. **A poster is a selection, not a reflow.** One takeaway sentence, and the claims that earn wall space — three is the working ceiling, and the ceiling is argued down, never up. The `plan` step presents the cut and the user confirms it (§7); a poster assembled without that confirmation is the wall of text this skill exists to prevent. What the cut drops is recorded in the plan, so the next run does not re-litigate it.
2. **Only what the ledger has verified reaches the wall.** A claim may be stated only where its `notes/claims.md` row is `verified`; `proposed`, `unsourced`, and `weakened` rows stay off the poster whatever the deadline, and the poster's wording follows the ledger row rather than restating the argument in fresh words. A poster is read by people who will not read the rebuttal.
3. **Numbers trace or they do not appear (§9a) — and no `\todo` reaches a wall.** Every number carries a `% src: mates/<...>#<anchor>` comment naming the fingerprinted evidence it was read from this run, on the line above the number — finer than `stage-tabs-builder`'s one comment per data row. But the manuscript's third state does not exist here: `\todo{}` is a marker for a draft nobody has printed, and `check` fails hard on one, the way `lint.sh` refuses to pack a `\todo` in `manus/`. The number is sourced, or the line comes off the poster.
4. **Figures are reused, never redrawn.** Every graphic is an existing `manus/figs/<slug>.pdf`, referenced unmodified — no re-plotting at poster scale, no recoloring, no cropping that changes what a panel shows. A figure that does not work at poster size is a finding for `stage-figs-designer`, not an edit here. Layout marks the poster needs and the paper does not — zone rules, block headers, arrows between panels — are typesetting, not artwork, and belong in `poster.tex`.
5. **Legibility is measured, not eyeballed.** The physical size is known, so the effective point size is arithmetic: compute it at print scale and hold the floors in `references/poster-layout.md` — the takeaway readable at four metres, body text at one and a half. Meaning survives grayscale, symbols and terms match `notes/notation.md`, and nothing overflows the declared sheet. "Looks fine on screen" is not a verdict; a number is.
6. **The size is a venue fact; the kit is supplied, never synthesized.** Sheet size and orientation bind only as the user confirmed them, recorded in `POSTER_PLAN.md`'s frontmatter as `size:`, `orientation:`, and `size_confirmed:` (the real date of that confirmation, §4). They enter the way §9c enters a venue value, are asked at every involve level (§7.9), and are never assumed from what posters "usually" are. This skill never writes `venue.yml`. Where the venue supplies an official poster kit it is copied byte-for-byte into `cycls/<cycle>/poster/template/` and never edited; where it supplies only a size, the house template is used at that size. Never fetch a kit and never reconstruct one from memory of what a venue's poster looks like (§9). A URL or DOI behind a QR code is the same kind of fact: supplied by the user, never recalled.
7. **The poster is signed; the paper may be anonymous.** `ANON` governs `manus/` and is not inherited here — a poster carries author names, affiliations, and contact, because you are standing next to it. This is also why the poster lives under `cycls/` and never under `manus/`: that tree is scanned by `lint.sh`, which counts `\todo{` and hunts identity leaks across every `.tex` in it, and a signed poster inside a scanned namespace is a hard lint failure on a file that is correct.

8. **Fan out the check gate's independent lanes (§6).** Step 5's checks do not depend on each other, so Sourced, the one lane that re-reads a `mates/` file for every `% src:` anchor in `poster.tex`, goes to a delegate past the threshold Step 5 states. Backed and Fresh stay here (§6.7): Backed matches every stated claim against the `notes/claims.md` row Step 0 already loaded, and Fresh is a hash comparison and one script call. Legible, Grayscale, and Fits are measurements on the PDF Step 4 compiled this run; when Step 4 could not compile, they are reported as not run (§7.4). The cut in Step 2 does not delegate (§6.5) and does not move with the involve level (§7.7: it is the decision this slash-only skill exists for, §11.1): what goes on a wall is the author's call, and Principle 1 exists because a poster assembled without it is the wall of text this skill prevents.

## Workflow

**Where this run executes.** This run's tier follows its mode: `check` is READ; `plan`, `render`, and the no-argument audit are EXEC (conventions §11.6). It stays in the session that started it, on the session's model. When that tier's value (`STAGE_READ_MODEL` or `STAGE_EXEC_MODEL`) names a model that is not an alias of the session's, say so in one line once the mode is resolved — the tier, that model, and the one way to get it: switch the session's model — then continue here.

### Step 0: Load

1. Read the conventions file whole, then `notes/story.md` (`## Pitch`, `## Contributions`, the active `cycle:`), `notes/claims.md`, `notes/outline.md` (Figures and Tables rows), `notes/notation.md`, `cycls/<cycle>/venue.yml`, and `manus/main.tex` for the paper's title — the poster carries it verbatim and never restyles or shortens it.
2. List `manus/figs/` and `cycls/<cycle>/poster/`; read `POSTER_PLAN.md` in full when it exists — it is the previous run's cut, and Principle 1 says a settled cut is not re-litigated.
3. Note `LATEX_ENGINE` from `.env` (§3). `ANON` is read and deliberately not applied (Principle 7).
4. No active cycle → §5.4 (ask, or route to `stage-stry-coach`, which creates cycles). A `render` or `check` whose plan lacks `size:`, `orientation:`, or `size_confirmed:` asks for them (Principle 6) before Step 3, or Step 4 on a `check`; this skill never invents a size.

### Step 1: Resolve the mode

`kit=<path>` is handled first, wherever it appears: register the kit (below), then continue with the mode given. With no mode, go to Step 6 when `POSTER_PLAN.md` exists; otherwise report the path and the class registered, commit the kit alone (Step 6.3), and end the report on the next command, `stage-pstr-builder plan`. Then first match wins: `plan` → Step 2, then Steps 6.2–6.3 (Step 2.5 already wrote the frontmatter); `render` → Steps 3–6, because a render always ends at the gate and `state:` never reaches `final` on a run that skipped it; `check` → Steps 4–6, recompiling whatever `poster.tex` already says without re-emitting it, so Legible, Grayscale, and Fits measure this source rather than a stale PDF. No argument → the audit, which ends at its report (item 4):

1. Every zone in `POSTER_PLAN.md` resolves: its figure exists under `manus/figs/`, its claim row is still `verified`, its evidence entry still carries the `sha256:` the plan's `## Evidence` list recorded (§8 — exact comparison, never mtime).
2. `poster.tex` is in step with the plan: no zone in one and absent from the other.
3. A claim that has since moved off `verified` is the headline finding — the poster states something the ledger no longer backs.
4. Report the drift and one next action with its exact command; go no further unless asked.

Registering a kit: unpack or copy it whole into `cycls/<cycle>/poster/template/`, unedited, and, if that directory already exists with different contents, show what differs and ask before replacing it (§7.7). Then record `poster_template:` in `POSTER_PLAN.md`'s frontmatter, naming the class inside it (a user-confirmed fact like the size: show it and ask before writing, Principle 6). With no plan yet, nothing is recorded here: Step 2.5 writes the field from the registered `template/`, in this run when it reaches Step 2 and otherwise in the next `plan` run.

### Step 2: Plan the cut (`plan`)

1. **The takeaway.** One sentence, derived from `## Pitch` in `notes/story.md` — what a passer-by should carry away having read nothing else. It states a result or an idea, not a topic.
2. **The claims.** Walk `notes/claims.md`, list every `verified` row with its evidence, and propose the set that carries the contribution (Principle 1's ceiling). Rows short of `verified` are listed as excluded with their status, so the exclusion is visible rather than silent.
3. **The figures.** Take candidates from the outline's Figures rows at `final`; the teaser is the default hero. A figure whose purpose the takeaway does not need is cut here, not shrunk.
4. **The sheet and the zones.** Unless the plan already records them with `size_confirmed:`, ask the sheet size and orientation (Principle 6), checking the answer against `references/poster-layout.md` §1 but never taking it from there. Then choose the layout per `references/poster-layout.md` (billboard by default) and map each selected element onto a zone.
5. Present the whole cut — takeaway, claims in, claims out, figures, layout, and the class inside a registered `template/` — and ask before writing via AskUserQuestion (plain text when it is unavailable), per §7. Then write `POSTER_PLAN.md`: frontmatter (`cycle:`, `size:`, `orientation:`, `size_confirmed:`, `poster_template:` when a kit is registered, `layout:`, `state: planned`, `updated:` with a real date per §4, plus `model_id:` and `model_trail:` per §8), the takeaway, the zone table `| Zone | Content | Source | Status |`, an `## Evidence` list (one line per cited `mates/MANIFEST.md` entry with the `sha256:` it carried when Step 3 read it), and the excluded list with reasons.

### Step 3: Emit the source (`render`)

1. The plan is the input: a `render` with no `POSTER_PLAN.md` runs Step 2 first rather than improvising a cut.
2. When `poster.tex` exists, read it in full first; when the emission would differ from it, show the diff and ask before overwriting (§7.7: a confirmation before an overwrite is asked at every level), because a hand fix made there (`references/poster-layout.md` §5) is otherwise lost. Then emit `cycls/<cycle>/poster/poster.tex` — the house template at the confirmed size, or the registered kit's class, one block per plan zone in the plan's order.
3. Every number carries its `% src: mates/<...>#<anchor>` comment on the line above, one comment per number, read from the evidence file this run (Principle 3). A number the evidence does not carry is not written and its zone is reported as short. Each MANIFEST entry a number was read from goes into the plan's `## Evidence` list with its current `sha256:`.
4. Claim text follows the ledger row's wording; figures are `\includegraphics` of `manus/figs/<slug>.pdf` by its path relative to `poster.tex` (`../../../manus/figs/<slug>.pdf`), unmodified.
5. Author block, affiliations, and any QR target come from the user (Principles 6 and 7) — asked once, recorded in the plan's frontmatter, never recalled.

### Step 4: Render

From the repository root, run `bash execs/run.sh --main cycls/<cycle>/poster/poster.tex --outdir wkdrs/builds/poster -g`: the `.env` engine, out of tree. `--outdir` is required, because without it `run.sh` writes the PDF into an unignored `cycls/<cycle>/poster/.build/`. `-g` forces the rebuild latexmk skips after a failed run. With a registered kit, prefix `TEXINPUTS=./template//:` so the kit's class finds its sibling files (`run.sh` compiles from `poster.tex`'s own directory). Report the produced page size against the confirmed sheet size and confirm the output is exactly one page. A missing class or package (`tikzposter`, the QR package) is named exactly, with the install line, and the run stops there: the source is committed and the render is stated as outstanding, never worked around by silently switching classes.

### Step 5: Check the gate (`check`)

Walk every item and report pass / fail per item. When `poster.tex` carries more than 12 `% src:` anchors, Sourced goes to one delegate, on the model of this run's own tier (READ for `check`, EXEC for `render`; conventions §11.6), where the harness can name one: it re-reads each anchor from its `mates/` file and returns one pass/fail row per anchor and nothing else, while the other items run here. At 12 or fewer, Sourced runs here too (Principle 8):

1. **Sourced.** Every number on the sheet has a `% src:` comment, and each one is re-read from its `mates/` file at its anchor this run — a fingerprint remembered is not a fingerprint checked. Any `\todo` anywhere in `poster.tex` fails the gate outright.
2. **Backed.** Every claim stated matches a `notes/claims.md` row at `verified`; nothing on the poster claims more than its row.
3. **Fresh.** Each cited entry's current `sha256:` in `mates/MANIFEST.md` equals the one the plan's `## Evidence` list recorded (§8: exact comparison, never mtime), and `execs/scpts/import.sh --diff` reports no drift for a cited path. No STAR source configured (it exits 1 saying so) → the upstream half is reported as not checked (conventions §7.4) and the gate continues; manual entries have no upstream to diff. Drift is reported and routed to `stage-evid-curator` before the poster is called final.
4. **Legible.** Effective point sizes meet the floors in `references/poster-layout.md`; the smallest text on the sheet is named with its computed size.
5. **Grayscale.** Every distinction the poster relies on survives without color — series, highlights, panel grouping.
6. **Fits.** Rendered page size equals the confirmed sheet size, one page, no overflow into the margins the layout declares.
7. **Signed.** Author block, affiliations, and the QR or DOI target are present and correct (Principle 7).
8. **Consistent.** Symbols and terms match `notes/notation.md`; no acronym the takeaway has not introduced.

Failures are recorded in the failing zones' Status (Step 6.1) and listed in the report; `state:` does not reach `final` while any item fails.

### Step 6: Update the output table and report

1. Flip `state:` in `POSTER_PLAN.md` honestly — `planned` until Step 3 has emitted `poster.tex`, `drafted` once it has, `final` only when every Step 5 item passes, and back to `drafted` when a later `check` fails one — record each zone's Status (`planned` before it is emitted, `ok`, `short` when Step 3.3 left a number out, `fail` when a Step 5 item fails on it), bump `updated:` (real date, §4), and append the `model_trail:` entry for this run (§8).
2. Report in chat: the takeaway as it will be read, claims in and out with their statuses, figures used, `% src:` anchors read with their stamps, gate verdicts per item, the render path and its measured size. Route what is not yours — a figure that fails at poster size to `stage-figs-designer`, evidence drift or an unregistered number to `stage-evid-curator`, a claim that needs the ledger moved to `stage-clms-auditor`.
3. Commit once for the run, subject naming this skill (§1) — `poster.tex`, the plan, and any registered kit together. Never commit `wkdrs/`.

## Output

- `cycls/<cycle>/poster/POSTER_PLAN.md` — confirmed sheet size, takeaway, zone table, `## Evidence` list, exclusions; `state:` is this skill's output-table state (§8).
- `cycls/<cycle>/poster/poster.tex` — the poster source, one `% src:` comment per number, no `\todo`.
- `cycls/<cycle>/poster/template/` — the official venue poster kit when one was supplied, unpacked whole and unedited.
- `wkdrs/builds/poster/poster.pdf` — the render, regenerable and never committed, or an honest statement of the render step that remains.
- Chat report per Step 6. Writes nothing under `manus/` or `mates/`, and no reports in `wkdrs/reports/`.
- Provenance (conventions §8): every Markdown record this run writes under `notes/`, `tasks/`, `cycls/`, or `wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended `model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`, nor does `poster.tex`, nor any file of the poster kit under `cycls/<cycle>/poster/template/` (conventions §8).
