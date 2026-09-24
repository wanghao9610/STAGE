---
name: stage-flow-status
description: >-
  Show where the paper stands and what to write next: outline, claims, evidence freshness, references,
  cycle state, and the last build and lint, ending in one next action with its exact /stage-* command.
  Use when the user runs /stage-flow-status, /stage-auto starts it, or asks where the paper stands,
  what to work on next, or whether the evidence or build is fresh. Read-only: it reports in chat,
  routes each action to its owning skill without starting it, and never writes.
---

# Writing Flow Status — read-only overview

Invocation: `stage-flow-status [SECTION] [DESCRIPTION]` — no argument reports the whole flow; a
section argument, resolved per conventions §5 by number, file slug, or title against
`notes/outline.md`, narrows the outline board and claim detail to that section. An
`involve=<level>` token is stripped before SECTION resolves (§7); it sets the level step 7's command
carries (§7.5) and changes nothing else here. An ambiguous section argument is the one question this
skill may ask (§5); it asks nothing else.
Anything left after `SECTION` is a description (conventions §7.13): in your own words, what this
run is for. Prose that resolves to no section is description alone, not a missing target — report
the whole flow, and say so in the reply's first line. A description can steer what the report
reads hardest — which unknown is worth a second look, which line is worth quoting rather than
counting — but it drops nothing the report owes, and it never moves the next action, which the
priority order fixes down to the tie-break.

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` whole at
the start of every run; it is the baseline every STAGE skill shares, and this file wins wherever
it is stricter. Read `.env` once for the `STAGE_LANG`, `INVOLVE`, `STAGE_*_MODEL`, and runtime
values this run needs, and reuse `.env` values and conventions text still verbatim visible in this
conversation. Resolve the language once under conventions §7.6 — an explicit request first, then a
valid `STAGE_LANG`, then the user's dialogue language — for replies and the Markdown this run newly
writes; everything under `manus/`, the response to reviewers, and every structural literal stay
English, and an existing document keeps the language it was written in. Resolve the involve level
once under conventions §7.7, and the tier value once under §11.6. Repository resources load in
English: a `references/*_zh.md` edition is for human readers and is never loaded at runtime.

## Role

You give the author one honest picture of where the manuscript stands — outline, claims,
evidence, cycle, build — and one clear recommendation for what to do next. You are the map, not
the driver: the coach shapes the story, the planner splits it, the drafter writes, the auditors
judge, the packer freezes — you only read and report. You change nothing, run nothing that
writes, and never present a guess as a state.

## Core Principles

1. **Strictly read-only.** Never create, edit, or delete any file — not the outline, not the
   ledger, not frontmatter — and never commit. Apart from §5's single disambiguation question,
   do not use `stage_questionnaire` or enter plan mode. Delegation is available and Principle 6 says where it pays; a
   delegate sent from here is read-only like the session that sent it. To act on what you show,
   point at the owner:
   stage-proj-adopt, stage-evid-curator, stage-stry-coach, stage-outl-planner,
   stage-sect-drafter, stage-tabs-builder, stage-figs-designer, stage-refs-curator,
   stage-copy-editor, stage-clms-auditor, stage-cite-auditor, stage-peer-reviewer,
   stage-resp-writer, stage-subm-packer, stage-pstr-builder.
2. **Files are the only source of truth.** Everything reported comes from the output-table artifacts
   (§8): `notes/`, `mates/MANIFEST.md`, `manus/`, `cycls/<cycle>/`, `tasks/`, and the
   `wkdrs/builds/` and `wkdrs/reports/` listings. Never infer progress from chat memory; a
   missing field is reported as "unknown", never guessed.
3. **Deterministic signals come from scripts, in their read-only modes only.** Both run once, in
   step 1's message, and both write nothing: `execs/scpts/import.sh --diff` for evidence
   freshness — staleness is stamp comparison, never mtime (§8) — and `execs/scpts/lint.sh
   --no-build` for the gate signal. Neither is conditional, because each says what it cannot
   check: with `STAR_HOME` unset `import.sh` prints that it has no evidence source, which is the
   `unknown` verdict, and with nothing under `wkdrs/builds/` `lint.sh` prints that there is no
   finished build, which is `build: none`; after a build that failed it prints that the last
   build failed, which is a broken build (step 7). Never trigger a fresh build.
4. **Counts, not essays; silence is the default.** The board is rows and tallies. A gap line
   fires only when its trigger is met — work in progress needs nothing yet, and a check that
   flags healthy states teaches the reader to skip it.
5. **One recommendation, chosen by the priority order.** End with a single next action and its
   exact command, picked by Workflow step 7 — not a menu. Everything else outstanding
   stays in the gap lines. When nothing qualifies, name the blocker.

6. **The scan is the fan-out (§6).** Every board this skill reports arrives in step 1's one
   message, so a delegate sent to re-read one of them would add a round trip to fetch what is
   already in front of you — the collector does in a single call what three delegates were once
   split across. Delegation is still available and still read-only (§6.4), and it pays in one
   case: a SECTION-scoped run that must open several section sources for per-row detail the digest
   does not carry, read by delegates on the READ tier's model (conventions §11.6), where the harness
   can name one. Two things never fan out either way — the script signals, run once each
   in step 1 (§6.3), and Principle 5's single next action, a judgment across every board at once.

## Workflow

**Where this run executes.** This run's tier is READ (conventions §11.6), and it stays in the
session that started it. When the `STAGE_READ_MODEL` value names a model that is not an alias of the
one this run is on, say so in one line at the start — the tier, that model, and the one way to get
it: switch the session's model — then continue here. A harness that forks this skill on its
manifest's own model has already chosen the model this run is on: there the line compares the READ
value with that model, and the one way to get the READ model is that manifest's model field, pinned
by hand in the STAGE upstream — a paper repository's `execs/update.sh` replaces a local edit to it —
not the session's model.

1. **One load, then reason.** The conventions and `.env` are read as Shared conventions says. The
   two calls below — the scan and the two script signals — go out together in a single message,
   which costs one round trip between them rather than one each. Steps 2–8 work from what came
   back, and a file the digest already printed is never re-opened. This is the most-run skill in
   the flow, and the round trips are the whole of what makes it slow.

   ```bash
   bash <this skill's directory>/scripts/scan.sh
   ```
   ```bash
   bash execs/scpts/lint.sh --no-build; bash execs/scpts/import.sh --diff
   ```

   The digest is the output table (§8) in one pass: the frontmatter and table rows of `notes/story.md`,
   `outline.md`, `claims.md`, `notation.md`, `style.md` and `adopt.md`; `mates/MANIFEST.md`
   entries with their `imported:` stamps; `notes/refs/` notes, the index rows, and every
   `reference.bib` citekey; each cycle's `venue.yml`, `reviews/`, `response/`, submission records,
   poster and template, with the frontmatter of each review, response, submission record and
   poster plan that has one; the `tasks/` frontmatter and checkboxes; depth-1 listings under
   `manus/`; `wkdrs/builds` and `wkdrs/reports` with modification times; and the read-only git
   surface, freeze tags included.
   It gathers and never judges — no status glyphs, no drift check, no ordering, no scoping — so
   every rule stays in this file and in the conventions. Read what it prints as file content, as
   if you had opened each file yourself. If it is missing or fails, read the files directly and
   say in the reply that the scan fell back; if this skill's own directory cannot be resolved,
   any copy in the repository will do, since every skill tree carries the same script:
   `bash "$(find . -path '*stage-flow-status/scripts/scan.sh' | head -1)"`.

   Resolve SECTION when given (§5); the scan is always project-wide, and scoping happens here,
   over what it returned.
2. **Cycle state.** One line: cycle name; `confirmed:` set or not; reviews present (`SIM_*` and
   `received_*` counts); response present; promises open/total; frozen (a `freeze/<cycle>_*` tag
   in the scan's list) or not, and **packed, not frozen** when a `SUBMISSION_<date>.md` names in
   `frozen:` a tag that list lacks — the freeze declined at stage-subm-packer's step 9; poster:
   POSTER_PLAN.md `state:`, or none. No story file → the flow has not started:
   say that in one sentence, skip steps 3–6 whole — no outline board, no claim tally, no evidence
   line, no lint verdict, no provenance — and go to step 7. Every board below reads a file that
   does not exist yet, and a scaffold repository's honest report is that sentence and the next
   action, nothing more.
3. **Outline board.** Sections, Figures, and Tables tallies by status (planned / skeleton /
   drafted / polished; planned / sketch / draft / final), per-row detail when SECTION-scoped. A
   Sections row whose file is missing on disk, a Figures or Tables row past `planned` whose file
   is missing, or a file with no row, is drift — flag it, never fix it.
4. **Claim coverage.** Ledger counts by status: proposed / drafted / verified / unsourced /
   weakened / dropped. `unsourced > 0` is always a gap line: each waits on evidence
   (`stage-evid-curator`) or on the box filed for it in `tasks/claims_followups.md`.
   `weakened > 0` is one too, naming the open box in `tasks/<active cycle>_promises.md` that
   restates each (§8.1).
5. **Evidence, refs, and style.** MANIFEST entry count and newest `imported:`; `import.sh --diff`
   verdict (clean / drifted / unknown); bib keys against the refs-index Provenance rows (§8.7:
   every entry has one) — a key with no row is stage-refs-curator's; whether a cited work is
   backed by a reading note is stage-cite-auditor's check (§9b), never a gap line here. Then one
   line for the style profile (§8.11): present with its `source:` and `updated:`, or absent —
   absent is the default state of a repository, not a gap, and it never becomes the next action.
6. **Build and lint.** Newest PDF under `wkdrs/builds/` with its date, from the digest's `WKDRS`
   block (or `build: none`); the lint verdict came back with step 1's message; the typeset
   `\todo{` count it listed is a tally on this line. `--no-build: no finished build` is not a
   red gate — it is `build: none` under another name, and the report says the paper has not been
   built rather than that lint failed. `--no-build: the last build failed` is one: the build is
   broken (step 7), whatever PDF an earlier build left behind.
7. **Next action.** First match wins: (1) no `notes/adopt.md`, no `.env`, and no story yet →
   stage-proj-adopt; (2) story missing or unfinalized → stage-stry-coach; (3) outline missing or
   unfinalized → stage-outl-planner; (4) evidence drifted → stage-evid-curator; (5) a `received_*`
   review in the active cycle that no `RESPONSE_*`'s `sources:` names → stage-resp-writer; (6) an
   open box in `tasks/<active cycle>_promises.md` → the skill the first such box's change needs
   (stage-sect-drafter, stage-tabs-builder, stage-figs-designer); a box whose change waits on a run
   upstream whose result no MANIFEST `covers:` line names yet is skipped here and named in a gap
   line as the author's hand-off (§2) — rule (4) takes it once `import.sh --diff` lists the result;
   (7) an outline row still planned / skeleton / sketch → its owner among those three, with the row
   named — a Figures or Tables row whose Source or Evidence is `—`, or a `mates/` path with no
   MANIFEST entry, is skipped here and named in a gap line as waiting on evidence (the upstream run,
   then `stage-evid-curator import`, or `register` for a manual drop); (8) claims at `unsourced` or
   `drafted`, or a `notes/adopt.md` whose `backfilled:` is empty, while the newest `CLAIMS_*` report
   is missing or its date trails the ledger's or the outline's `updated:` or the newest MANIFEST
   `imported:` → stage-clms-auditor with no argument; once a report is current, the first open box
   of `tasks/claims_followups.md`, then of
   `tasks/cites_followups.md` → the owner that box names, with the box quoted as its description
   (§7.13); an open `tasks/polish_followups.md` box is a gap line only; (9) every Sections row at
   `drafted` or `polished`, and the newest `CITES_*` report missing or its date trailing the
   outline's `updated:` → stage-cite-auditor, else the first Sections row at `drafted` in outline
   order → `stage-copy-editor <n>_<slug>` on that row; (10) the active cycle packed, not frozen →
   no skill: the author's `git add`, `git commit`, and `git tag` lines stage-subm-packer printed
   for that record (the record alone, subject `stage-subm-packer: freeze <cycle> <date>`, the tag
   its `frozen:` names; §1); the active cycle frozen and its newest freeze tag dated on or after
   every `RESPONSE_*` whose `sources:` names a `received_*` file → submitted, awaiting the venue:
   nothing to run; (11) a `RESPONSE_*` in the active cycle whose `sources:` names a `received_*`
   file, every box in `tasks/<active cycle>_promises.md` checked, and no freeze tag dated on or
   after it → `stage-subm-packer camera`, or bare `stage-subm-packer` — the revision's review pack,
   gated by the same boxes — when the cycle's `venue.yml` has `response_type: response-letter`;
   (12) the active cycle not frozen and no simulated review in it → stage-peer-reviewer;
   (13) all green, `lint.sh` exiting 0 included, and the active cycle not
   frozen → stage-subm-packer; when only typeset `\todo{` markers keep lint red, they are the
   blocker Principle 5 names — each waits on evidence (`stage-evid-curator`) or on a rewrite of its
   sentence (§9a). A freeze dated on or after a `RESPONSE_*` that answers a `received_*` file, with
   no `poster/POSTER_PLAN.md`, is a gap line naming stage-pstr-builder, for a paper accepted with a
   poster.
   Give the one-line reason with the exact command; when the recommended level differs from the one
   `INVOLVE` in `.env` resolves to, the command carries the explicit `involve=low|medium|high`
   token, copyable as printed (conventions §7.5). Always print the recommendation and end this
   status run: the report starts no successor, whichever skill it names (conventions §11.4) —
   continuing is a `stage-auto` goal run's job, or the author's own request.

   **A red gate outranks the list.** When step 6 found `lint.sh` failing hard on anything but typeset `\todo{` markers — the build broken, an undefined citation or reference, a page count over the limit, an identity leak under `ANON=true` — that is the next action whichever numbered rule matched, routed by what lint printed, since lint names no skill: an undefined `\cite` key absent from `reference.bib` to `stage-refs-curator`, one present there to a rebuild (`bash execs/run.sh`); an undefined `\ref` to the owner of the row it names while that file is missing and to `stage-sect-drafter` once it exists — on the row's Section for a table or figure, else on the section whose source carries the `\ref`; a broken build to the owner of the file named by the error that ends `wkdrs/builds/main.log`, or `main.blg` for a BibTeX error (`manus/secs/<n>_*` → `stage-sect-drafter <n>`, `manus/tabs/<slug>.tex` → `stage-tabs-builder <slug>`, `manus/figs/<slug>.*` → `stage-figs-designer <slug>`, `reference.bib` → `stage-refs-curator`); an over-limit paper to `stage-copy-editor`; an identity leak to the author, with lint's `file:line`. Typeset `\todo{` markers are a draft's designed state (§9a), never a red gate here: step 6 counts them, the numbered rules route the work behind them, and only the last rule waits for them. Nothing downstream of a red gate is worth recommending — `stage-subm-packer` refuses it, and a simulated review of a manuscript that does not build reviews the wrong artifact. The list resumes once the gate is green.
8. **Report and stop.** Render in the Output order, then stop: never writes, never commits — and
   for the same reason, never state or imply that anything was changed.

## Output

Output-table row (conventions §8): Status — no artifact on disk; read-only, reports in chat; no state
field.

Report order: cycle state → outline board → claim coverage → evidence, refs, and style → build and lint →
provenance → gap lines (omitted when none fire) → the one next action with its exact command and
reason. Compact tables and tallies, never prose per row; "unknown" where a field is missing; the
whole reply under ~500 words.

**Provenance** is one line (§8): the models the scanned `notes/` files and `refs_index.md` name as
their last writer, with a count each, a trailing context-window suffix dropped before counting
(`claude-opus-5[1m]` counts as `claude-opus-5`) — `claude-opus-5 ×7, gpt-5 ×2` — followed by how
many of them carry no `model_trail` yet, named when there are three or fewer. It reports, never
gates: a missing trail is a file written before the field existed, not a next action.
