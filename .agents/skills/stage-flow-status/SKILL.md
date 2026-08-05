---
name: stage-flow-status
description: >-
  Read-only map of the whole writing flow: per-section, per-figure, and per-table status from
  notes/outline.md, claim coverage counts by ledger status, evidence freshness against upstream stamps,
  reference counts, cycle state (venue confirmed, reviews in, response drafted, promises open, frozen),
  the latest build and lint signal, and exactly one next action with its exact $stage-* command. Reports
  in chat only and points every action at the sibling skill that owns it. Use when the user invokes
  $stage-flow-status, when a run names it as the next action, or asks where the paper stands, what to
  work on next, whether evidence or the build is fresh, or how far the current cycle has gotten. Never
  writes.
---

# Writing Flow Status — read-only overview

**Reply language (conventions §7.6).** `.env` `STAGE_LANG=en|zh` sets chat replies and the
Markdown this run writes; resolve it once at the start of the run — `grep -sE '^STAGE_LANG=' .env
|| true`, folded into the opening load call. Unset or empty → follow the user's dialogue
language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request
wins. English whatever it says: everything under `manus/`, the response to reviewers, and every
structural literal — frontmatter keys, ledger statuses, IDs, paths, bibkeys, venue and metric
names. Repo resources (the conventions, this skill) are loaded as-is in English; their zh-CN
editions — `SKILL_zh.md` beside this file, and `writing-workflow-conventions.zh-CN.md` for the
conventions — are kept in step for human readers only and are never loaded at runtime, so this
SKILL.md stays authoritative.

Invocation: `$stage-flow-status [SECTION]` — no argument reports the whole flow; a section
argument, resolved per conventions §5 by number, file slug, or title against `notes/outline.md`,
narrows the outline board and claim detail to that section. An `involve=<level>` token is
stripped before SECTION resolves (§7) and changes nothing else here. An ambiguous section
argument is the one question this skill may ask (§5); it asks nothing else.

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` in full at
the start of every run — there is no section-selective loading. It is the baseline every STAGE
skill shares; the sections that bind this skill hardest are §0 vocabulary, §5 section and cycle
resolution, §7 dialogue's reporting rules, and §8 the artifact registry with its staleness rule.
This file states what is specific to this skill and wins wherever it is stricter.

**Reusing an earlier load.** Skip the re-read only when the conventions file's own text is still
verbatim visible in this conversation. A summary that survived a context compaction and a memory
of having read it both fail that test — when in doubt, read it again; a wasted read costs one
message, a wrong assumption costs the run.

## Role

You give the author one honest picture of where the manuscript stands — outline, claims,
evidence, cycle, build — and one clear recommendation for what to do next. You are the map, not
the driver: the coach shapes the story, the planner splits it, the drafter writes, the auditors
judge, the packer freezes — you only read and report. You change nothing, run nothing that
writes, and never present a guess as a state.

## Core Principles

1. **Strictly read-only.** Never create, edit, or delete any file — not the outline, not the
   ledger, not frontmatter — and never commit. Apart from §5's single disambiguation question:
   no `update_plan`, no `spawn_agent`, no `request_user_input`. To act on what you show, point at the owner:
   $stage-proj-adopt, $stage-evid-curator, $stage-stry-coach, $stage-outl-planner,
   $stage-sect-drafter, $stage-tabs-builder, $stage-figs-designer, $stage-refs-curator,
   $stage-copy-editor, $stage-clms-auditor, $stage-cite-auditor, $stage-peer-reviewer,
   $stage-resp-writer, $stage-subm-packer.
2. **Files are the only source of truth.** Everything reported comes from the registry artifacts
   (§8): `notes/`, `mates/MANIFEST.md`, `manus/`, `cycls/<cycle>/`, `tasks/`, and the
   `wkdrs/builds/` and `wkdrs/reports/` listings. Never infer progress from chat memory; a
   missing field is reported as "unknown", never guessed.
3. **Deterministic signals come from scripts, in their read-only modes only.** Evidence
   freshness: `execs/scpts/import.sh --diff` (read-only by contract) when `STAR_HOME` is set,
   else unknown — staleness is stamp comparison, never mtime (§8). Build and lint: name the
   newest artifact under `wkdrs/builds/` and, when one exists, run `execs/scpts/lint.sh
   --no-build` for the current gate signal — it writes nothing; never trigger a fresh build.
4. **Counts, not essays; silence is the default.** The board is rows and tallies. A gap line
   fires only when its trigger is met — work in progress needs nothing yet, and a check that
   flags healthy states teaches the reader to skip it.
5. **One recommendation, chosen by the priority order.** End with a single next action and its
   exact $stage-* command, picked by Workflow step 7 — not a menu. Everything else outstanding
   stays in the gap lines. When nothing qualifies, name the blocker.

## Workflow

1. **Load.** Read the conventions in full, then scan the registry artifacts: frontmatter — `model_id:` and `model_trail:` included (§8) — and
   status tables of `notes/story.md`, `notes/outline.md`, `notes/claims.md`, `notes/notation.md`;
   `mates/MANIFEST.md` entries; `notes/refs/refs_index.md` rows against `manus/bibs/reference.bib`
   keys; the active cycle's `venue.yml`, `reviews/`, `response/`, and `SUBMISSION_*`;
   `tasks/<cycle>_promises.md`; listings of `manus/secs|figs|tabs` and `wkdrs/builds|reports`;
   `git tag -l 'freeze/<cycle>_*'` (read-only). Resolve SECTION when given (§5).
2. **Cycle state.** One line: cycle name; `confirmed:` set or not; reviews present (`SIM_*` and
   `received_*` counts); response present; promises open/total; frozen (tag or SUBMISSION file)
   or not. No story file → the flow has not started; say so and jump to step 7.
3. **Outline board.** Sections, Figures, and Tables tallies by status (planned / skeleton /
   drafted / polished / frozen; planned / sketch / draft / final), per-row detail when
   SECTION-scoped. A row whose file is missing on disk, or a file with no row, is drift — flag
   it, never fix it.
4. **Claim coverage.** Ledger counts by status: proposed / drafted / verified / unsourced /
   weakened / dropped. `unsourced > 0` is always a gap line naming $stage-clms-auditor.
5. **Evidence and refs.** MANIFEST entry count and newest `imported:`; `import.sh --diff` verdict
   (clean / drifted / unknown); bib keys against refs-index rows — a cited work with no reading
   note is $stage-refs-curator's.
6. **Build and lint.** Newest PDF under `wkdrs/builds/` (or `build: none`); the lint gate signal
   per Principle 3.
7. **Next action.** First match wins: (1) no `notes/adopt.md` → $stage-proj-adopt; (2) story
   missing or unfinalized → $stage-stry-coach; (3) outline missing or unfinalized →
   $stage-outl-planner; (4) evidence drifted → $stage-evid-curator; (5) open promises → the
   skill the first open box's change needs ($stage-sect-drafter, $stage-tabs-builder,
   $stage-figs-designer); (6) an outline row still planned / skeleton / sketch → its owner among
   those three, with the row named; (7) claims at `unsourced`, or `drafted` never verified →
   $stage-clms-auditor; (8) all rows drafted but the newest `CITES_*` / `POLISH_*` report date
   trails the outline's `updated:` → $stage-cite-auditor, then $stage-copy-editor; (9) no
   simulated review this cycle → $stage-peer-reviewer; (10) all green → $stage-subm-packer.
   Give the one-line reason with the exact command. When that command names one of the ten the
   agent may start (conventions §11.4) and its target is settled, it is picked up once this
   report is done rather than left for the author to type — this skill starts nothing itself.

   **A red gate outranks the list.** When step 6 found `lint.sh` failing hard — the build broken, a `\todo{` that would ship, a page count over the limit, an identity leak under `ANON=true` — that is the next action whichever numbered rule matched, routed to the owner lint itself names: a marker to `$stage-sect-drafter` or `$stage-tabs-builder`, an over-limit paper to `$stage-copy-editor`, an undefined citation to `$stage-cite-auditor` or `$stage-refs-curator`. Nothing downstream of a red gate is worth recommending — `$stage-subm-packer` refuses it, and a simulated review of a manuscript that does not build reviews the wrong artifact. The list resumes once the gate is green.
8. **Report and stop.** Render in the Output order, then stop: never writes, never commits — and
   for the same reason, never state or imply that anything was changed.

## Output

Registry row (conventions §8): Status — no artifact on disk; read-only, reports in chat; no state
field.

Report order: cycle state → outline board → claim coverage → evidence and refs → build and lint →
provenance → gap lines (omitted when none fire) → the one next action with its exact $stage-* command and
reason. Compact tables and tallies, never prose per row; "unknown" where a field is missing; the
whole reply under ~500 words.

**Provenance** is one line (§8): the models this paper's artifacts name as their last writer,
with a count each — `claude-opus-5[1m] ×7, gpt-5 ×2` — followed by how many registry artifacts
carry no `model_trail` yet, named when there are three or fewer. It reports, never gates: a
missing trail is a file written before the field existed, not a next action.
