---
name: stage-flow-status
model: sonnet
effort: medium
context: fork
background: false
description: >-
  Read-only map of the whole writing flow: per-section, per-figure, and per-table status from
  notes/outline.md, claim coverage counts by ledger status, evidence freshness against upstream stamps,
  reference counts, cycle state (venue confirmed, reviews in, response drafted, promises open, frozen),
  the latest build and lint signal, and exactly one next action with its exact /stage-* command. Reports
  in chat only and points every action at the sibling skill that owns it. Use when the user runs
  /stage-flow-status, when a run names it as the next action, or asks where the paper stands, what to
  work on next, whether evidence or the build is fresh, or how far the current cycle has gotten. Never
  writes.
argument-hint: "[SECTION]"
allowed-tools: >-
  Read, Grep, Glob, Bash(bash execs/scpts/import.sh --diff:*),
  Bash(execs/scpts/import.sh --diff:*), Bash(bash execs/scpts/lint.sh --no-build:*),
  Bash(execs/scpts/lint.sh --no-build:*),
  Bash(bash .claude/skills/stage-flow-status/scripts/scan.sh),
  Bash(bash .claude/skills/stage-flow-status/scripts/scan.sh:*),
  Bash(bash ${CLAUDE_SKILL_DIR}/scripts/scan.sh),
  Bash(bash ${CLAUDE_SKILL_DIR}/scripts/scan.sh:*),
  Bash(grep:*), Bash(sed -n:*), Bash(awk:*), Agent, Bash(git status:*), Bash(git log:*),
  Bash(git tag -l:*)
---

# Writing Flow Status — read-only overview

**Reply language (conventions §7.6).** `.env` `STAGE_LANG=en|zh` sets chat replies and the
Markdown this run writes; resolve it once at the start of the run — the probe is the first of the
five calls step 1 sends together. Unset or empty → follow the user's dialogue
language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request
wins. English whatever it says: everything under `manus/`, the response to reviewers, and every
structural literal — frontmatter keys, ledger statuses, IDs, paths, bibkeys, venue and metric
names. Repo resources (the conventions, this skill) are loaded as-is in English; their zh-CN
editions — `SKILL_zh.md` beside this file, and `writing-workflow-conventions.zh-CN.md` for the
conventions — are kept in step for human readers only and are never loaded at runtime, so this
SKILL.md stays authoritative.

Invocation: `/stage-flow-status [SECTION]` — no argument reports the whole flow; a section
argument, resolved per conventions §5 by number, file slug, or title against `notes/outline.md`,
narrows the outline board and claim detail to that section. An `involve=<level>` token is
stripped before SECTION resolves (§7) and changes nothing else here. An ambiguous section
argument is the one question this skill may ask (§5); it asks nothing else.

**Shared conventions.** `docs/mds/stage-workflow/writing-workflow-conventions.md` is the baseline
every STAGE skill shares; this file states what is specific to this one and wins wherever it is
stricter. Step 1 loads eight of its twelve sections — §0 vocabulary, §3 the `.env` runtime, §5
section and cycle resolution, §6 delegation, §7 dialogue's reporting rules, §8 the artifact
registry with its staleness rule, §9 the fabrication boundary, §11 the skill roster — and that is
the whole read: this is the most-run skill in the flow, and the four it leaves out are a fifth of
the file that no read-only report can use.

**The four left out, and why each is safe to leave.** §1 git: its only sentence about this skill is
that this skill never commits, which Principle 1 states here in stronger terms, and the read-only
`status` / `log` / `tag -l` the scan runs need no rule to permit them. §2 the STOP line: it draws
the line between light and heavy work, and the only two commands this skill may run — `import.sh
--diff` and `lint.sh --no-build` — are named on the light side of it and bounded again by
Principle 3. §4 real dates: every date reported is read from a file or printed by the scan, which
stamps its own `# today:` line from the clock; this skill writes no date anywhere. §10 project
layout: it says where a skill puts what it writes, and this one writes nothing — every path it
reads is named in step 1 or printed by the scan. Read a left-out section in full the moment a run
needs it; the saving is in not reading it by default, not in refusing to.

**Reusing an earlier load.** Skip the re-read only when those excerpts' own text is still verbatim
visible in this conversation. A summary that survived a context compaction and a memory of having
read it both fail that test — when in doubt, read them again; a wasted read costs one message, a
wrong assumption costs the run.

## Role

You give the author one honest picture of where the manuscript stands — outline, claims,
evidence, cycle, build — and one clear recommendation for what to do next. You are the map, not
the driver: the coach shapes the story, the planner splits it, the drafter writes, the auditors
judge, the packer freezes — you only read and report. You change nothing, run nothing that
writes, and never present a guess as a state.

## Core Principles

1. **Strictly read-only.** Never create, edit, or delete any file — not the outline, not the
   ledger, not frontmatter — and never commit. Apart from §5's single disambiguation question:
   no AskUserQuestion and no plan mode. Delegation is available and Principle 6 says where it pays; a
   delegate sent from here is read-only like the session that sent it. To act on what you show,
   point at the owner:
   /stage-proj-adopt, /stage-evid-curator, /stage-stry-coach, /stage-outl-planner,
   /stage-sect-drafter, /stage-tabs-builder, /stage-figs-designer, /stage-refs-curator,
   /stage-copy-editor, /stage-clms-auditor, /stage-cite-auditor, /stage-peer-reviewer,
   /stage-resp-writer, /stage-subm-packer.
2. **Files are the only source of truth.** Everything reported comes from the registry artifacts
   (§8): `notes/`, `mates/MANIFEST.md`, `manus/`, `cycls/<cycle>/`, `tasks/`, and the
   `wkdrs/builds/` and `wkdrs/reports/` listings. Never infer progress from chat memory; a
   missing field is reported as "unknown", never guessed.
3. **Deterministic signals come from scripts, in their read-only modes only.** Both run once, in
   step 1's message, and both write nothing: `execs/scpts/import.sh --diff` for evidence
   freshness — staleness is stamp comparison, never mtime (§8) — and `execs/scpts/lint.sh
   --no-build` for the gate signal. Neither is conditional, because each says what it cannot
   check: with `STAR_HOME` unset `import.sh` prints that it has no evidence source, which is the
   `unknown` verdict, and with nothing under `wkdrs/builds/` `lint.sh` prints that there is no
   finished build, which is `build: none`. Never trigger a fresh build.
4. **Counts, not essays; silence is the default.** The board is rows and tallies. A gap line
   fires only when its trigger is met — work in progress needs nothing yet, and a check that
   flags healthy states teaches the reader to skip it.
5. **One recommendation, chosen by the priority order.** End with a single next action and its
   exact /stage-* command, picked by Workflow step 7 — not a menu. Everything else outstanding
   stays in the gap lines. When nothing qualifies, name the blocker.

6. **The scan is the fan-out (§6).** Every board this skill reports arrives in step 1's one
   message, so a delegate sent to re-read one of them would add a round trip to fetch what is
   already in front of you — the collector does in a single call what three delegates were once
   split across. Delegation is still available and still read-only (§6.4), and it pays in one
   case: a SECTION-scoped run that must open several section sources for per-row detail the
   digest does not carry. Two things never fan out either way — the script signals, run once each
   in step 1 (§6.3), and Principle 5's single next action, a judgment across every board at once.

## Workflow

1. **One load, then reason.** Everything this skill reads arrives in a single message — five Bash
   calls sent together, which cost one round trip between them rather than one each. Steps 2–8
   work from what came back, and a file the digest already printed is never re-opened. This is
   the most-run skill in the flow, and the round trips are the whole of what makes it slow.

   ```bash
   grep -sE '^STAGE_LANG=' .env || true    # reply language (§7.6)
   sed -n '/^## 0\./,/^## 1\./p; /^## 3\./,/^## 4\./p; /^## 5\./,/^## 8\./p' docs/mds/stage-workflow/writing-workflow-conventions.md
   ```
   ```bash
   sed -n '/^## 8\./,/^## 9\./p; /^## 11\./,$p' docs/mds/stage-workflow/writing-workflow-conventions.md
   ```
   ```bash
   sed -n '/^## 9\./,/^## 10\./p' docs/mds/stage-workflow/writing-workflow-conventions.md
   ```
   ```bash
   bash <this skill's directory>/scripts/scan.sh
   ```
   ```bash
   bash execs/scpts/lint.sh --no-build; bash execs/scpts/import.sh --diff
   ```

   The conventions ride in three calls rather than one because each tool result has its own size
   limit, and a Bash result past roughly 30 KB is spilled to a file that costs a round trip to
   read back — the exact round trip the single message exists to avoid. The eight loaded sections
   are 60 KB together, so they cannot share one result; split this way each is comfortably under,
   the digest gets a result to itself since it is the one part that grows with the paper, and the
   two script signals get a fifth because their few lines would otherwise ride on whichever
   result is closest to spilling. If an extraction prints nothing — a synced conventions copy may
   number its sections differently — load the whole file with `sed -n '/^## 0\./,$p'` and say in
   the reply that the excerpts fell back.

   The digest is the registry (§8) in one pass: the frontmatter and table rows of `notes/story.md`,
   `outline.md`, `claims.md`, `notation.md`, `style.md` and `adopt.md`; `mates/MANIFEST.md`
   entries with their `imported:` stamps; `notes/refs/` notes, the index rows, and every
   `reference.bib` citekey; each cycle's `venue.yml`, `reviews/`, `response/`, submission records
   and template; the `tasks/` checkboxes; depth-1 listings under `manus/`; `wkdrs/builds` and
   `wkdrs/reports` with modification times; and the read-only git surface, freeze tags included.
   It gathers and never judges — no status glyphs, no drift check, no ordering, no scoping — so
   every rule stays in this file and in the conventions. Read what it prints as file content, as
   if you had opened each file yourself. If it is missing or fails, read the files directly and
   say in the reply that the scan fell back; if this skill's own directory cannot be resolved,
   any copy in the repository will do, since all four harness trees carry the same script:
   `bash "$(find . -path '*stage-flow-status/scripts/scan.sh' | head -1)"`.

   Resolve SECTION when given (§5); the scan is always project-wide, and scoping happens here,
   over what it returned.
2. **Cycle state.** One line: cycle name; `confirmed:` set or not; reviews present (`SIM_*` and
   `received_*` counts); response present; promises open/total; frozen (tag or SUBMISSION file)
   or not. No story file → the flow has not started: say that in one sentence, skip steps 3–6
   whole — no outline board, no claim tally, no evidence line, no lint verdict, no provenance —
   and go to step 7. Every board below reads a file that does not exist yet, and a scaffold
   repository's honest report is that sentence and the next action, nothing more.
3. **Outline board.** Sections, Figures, and Tables tallies by status (planned / skeleton /
   drafted / polished / frozen; planned / sketch / draft / final), per-row detail when
   SECTION-scoped. A row whose file is missing on disk, or a file with no row, is drift — flag
   it, never fix it.
4. **Claim coverage.** Ledger counts by status: proposed / drafted / verified / unsourced /
   weakened / dropped. `unsourced > 0` is always a gap line naming /stage-clms-auditor.
5. **Evidence, refs, and style.** MANIFEST entry count and newest `imported:`; `import.sh --diff`
   verdict (clean / drifted / unknown); bib keys against refs-index rows — a cited work with no
   reading note is /stage-refs-curator's. Then one line for the style profile (§8.11): present
   with its `source:` and `updated:`, or absent — absent is the default state of a repository, not
   a gap, and it never becomes the next action.
6. **Build and lint.** Newest PDF under `wkdrs/builds/` with its date, from the digest's `WKDRS`
   block (or `build: none`); the lint verdict came back with step 1's message. `--no-build: no
   finished build` is not a red gate — it is `build: none` under another name, and the report
   says the paper has not been built rather than that lint failed.
7. **Next action.** First match wins: (1) no `notes/adopt.md` → /stage-proj-adopt; (2) story
   missing or unfinalized → /stage-stry-coach; (3) outline missing or unfinalized →
   /stage-outl-planner; (4) evidence drifted → /stage-evid-curator; (5) open promises → the
   skill the first open box's change needs (/stage-sect-drafter, /stage-tabs-builder,
   /stage-figs-designer); (6) an outline row still planned / skeleton / sketch → its owner among
   those three, with the row named; (7) claims at `unsourced`, or `drafted` never verified →
   /stage-clms-auditor; (8) all rows drafted but the newest `CITES_*` / `POLISH_*` report date
   trails the outline's `updated:` → /stage-cite-auditor, then /stage-copy-editor; (9) no
   simulated review this cycle → /stage-peer-reviewer; (10) all green → /stage-subm-packer.
   Give the one-line reason with the exact command. When that command names one of the ten the
   agent may start (conventions §11.4) and its target is settled, it is picked up once this
   report is done rather than left for the author to type — this skill starts nothing itself.

   **A red gate outranks the list.** When step 6 found `lint.sh` failing hard — the build broken, a `\todo{` that would ship, a page count over the limit, an identity leak under `ANON=true` — that is the next action whichever numbered rule matched, routed to the owner lint itself names: a marker to `/stage-sect-drafter` or `/stage-tabs-builder`, an over-limit paper to `/stage-copy-editor`, an undefined citation to `/stage-cite-auditor` or `/stage-refs-curator`. Nothing downstream of a red gate is worth recommending — `/stage-subm-packer` refuses it, and a simulated review of a manuscript that does not build reviews the wrong artifact. The list resumes once the gate is green.
8. **Report and stop.** Render in the Output order, then stop: never writes, never commits — and
   for the same reason, never state or imply that anything was changed.

## Output

Registry row (conventions §8): Status — no artifact on disk; read-only, reports in chat; no state
field.

Report order: cycle state → outline board → claim coverage → evidence, refs, and style → build and lint →
provenance → gap lines (omitted when none fire) → the one next action with its exact /stage-* command and
reason. Compact tables and tallies, never prose per row; "unknown" where a field is missing; the
whole reply under ~500 words.

**Provenance** is one line (§8): the models this paper's artifacts name as their last writer,
with a count each — `claude-opus-5[1m] ×7, gpt-5 ×2` — followed by how many registry artifacts
carry no `model_trail` yet, named when there are three or fewer. It reports, never gates: a
missing trail is a file written before the field existed, not a next action.
