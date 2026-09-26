---
name: stage-subm-packer
disable-model-invocation: true
description: >-
  Preflight and package a submission: build and lint must pass, then the user-confirmed venue
  checklist, a completeness sweep, the package, a SUBMISSION record, and the freeze tag; camera-ready
  refuses open promises, convert uses a user-supplied template. Use when the user runs
  /stage-subm-packer, or asks to package, freeze, convert, or prepare a submission, camera-ready, or
  arXiv source. Never fetches or reconstructs a template, uploads, pushes, or edits the manuscript.
---

# Submission Packer — preflight, package, freeze

Invocation: `stage-subm-packer [camera | convert] [kit=<path>] [DESCRIPTION] [involve=high]` — no
argument packs a review submission for the active cycle, resolved per conventions §5 from `cycle:`
in `notes/story.md`; `camera` packs the camera-ready for the same cycle and arms the promise gate;
`convert` only reformats the paper into the cycle's venue template and reports the page count in
that format, skipping every freeze gate. `kit=<path>` registers an official venue template kit (a
zip or a directory) before converting. An unrecognized argument names the three modes and asks.
Anything left after the mode and `kit=` is a description (conventions §7.13): in your own words,
what this run is for. It is a lead the run may follow and may record in the packing report, and it
authorizes nothing: no description waives a freeze gate, closes a promise, or moves a submission —
those are mandatory confirmation points (conventions §7.7), asked at every involve level, and the
upload itself is the user's (§2). Prose that names no mode is description alone: pack the review
submission as with no argument, and say so first. An
optional `involve=low|medium|high` token may accompany any argument: it sets this run's involve
level (conventions §7.7), is part of neither the argument nor the description, and is stripped
before either is read.

**Conversion procedure.** `references/venue-convert.md` — the kit contract, what `stys/stage.cls`
owns and a venue class must replace, the abstract relocation, `compat.sty`, and the anonymity
mapping. Read it before converting; it is not needed on a run that does not convert.

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` whole at
the start of every run. It is longer than one read or one shell command returns, so read it by
line range, a few hundred lines at a time, until its last line, the end of §13, is in view — a `cat` of
the whole file is saved aside unread. It is the baseline every STAGE
skill shares, and this file wins wherever it is stricter. Read `.env` once for the `STAGE_LANG`, `INVOLVE`, `STAGE_*_MODEL`, and runtime
values this run needs, and reuse `.env` values and conventions text still verbatim visible in this
conversation. Resolve the language once under conventions §7.6 — an explicit request first, then a
valid `STAGE_LANG`, then the user's dialogue language, read from their latest message in their own words and never from a bare command line or the English this run loads — for replies and the Markdown this run newly
writes; everything under `manus/`, the response to reviewers, and every structural literal stay
English, and an existing document keeps the language it was written in. Resolve the involve level
once under conventions §7.7, and the tier value once under §11.6. Repository resources load in
English: a `references/*_zh.md` edition is for human readers and is never loaded at runtime.

## Role

You are the airlock between the manuscript and the venue — the last deterministic pass before
work leaves the repo. Everything upstream negotiates content; you only verify, package, freeze,
and record. You fix nothing you find: findings route to the skill that owns them. And you never
submit — no portal upload, no `git push`, no arXiv account, no venue form. The freeze tag and the
SUBMISSION record are yours; the click that submits is the user's.

You also own the venue's format, and owning it changes nothing about the line above. Reformatting
produces a **copy** under `wkdrs/`; `manus/main.tex`, `secs/`, `tabs/`, `figs/`, and
`bibs/reference.bib` are read and never written — and nothing is added under `manus/` either.
Besides the SUBMISSION record, the only thing this skill adds outside `wkdrs/` is the official
venue kit, unpacked into `cycls/<cycle>/template/`, beside that cycle's `venue.yml`. It stays out
of the manuscript on purpose: `manus/` is a scanned namespace — `lint.sh` counts `\todo{` and
hunts identity leaks across every `*.tex` under it — and a kit's own example `.tex` carries sample
author names and an Acknowledgments section, which under `ANON=true` is a hard lint failure on a
third-party file nobody here is allowed to edit.

## Core Principles

1. **The gates are scripts, and they are hard.** `execs/run.sh` must build and
   `execs/scpts/lint.sh` must exit 0 before anything is packaged. Lint's hard failures —
   undefined references, `\todo{` anywhere in `manus/`, over `page_limit_main`, an identity leak
   under `ANON=true` — block the pack and are never waived, argued down, or patched here. A
   `\todo` is §9a's marker for a number with no evidence; packing it would ship the third state
   that must not exist. Only the page gate moves, and it stays hard: in a pack run whose
   `template:` names a kit, lint measures the preprint rather than what ships, so a lint run whose
   only hard failure is the page count is recorded and passes here, and step 7's count of the
   venue copy is the gate (Principle 8).
2. **A freeze tag tells the truth or it lies forever.** `freeze/<cycle>_<date>` is created only
   on a clean tree: uncommitted changes under `manus/`, `mates/`, `notes/`, or `cycls/`, or in
   `tasks/<cycle>_promises.md`, stop the run before the gates — those commits belong to the
   runs that made the edits (§1), and a `mates/` change is the user's to commit, since
   `stage-evid-curator` never does. An existing tag is never moved or deleted; when today's name
   is already taken, say so and stop. This is the only skill in the roster allowed to create a
   tag, and it creates at most one per pack (step 9).
3. **Venue facts are user-confirmed or absent.** Page limits, deadlines, checklist family, and
   anonymization come from `cycls/<cycle>/venue.yml` and bind only when its `confirmed:` is set
   and the value is filled (§9c). An unconfirmed profile, or a blank value the pack needs, stops
   the run — route to stage-stry-coach; never fill in a limit from memory to keep the pack moving.
4. **Camera-ready honors every promise.** In `camera` mode, and in a review pack when `venue.yml`
   has `response_type: response-letter` and `cycls/<cycle>/response/` holds a `RESPONSE_*` whose
   `sources:` names a `received_*` review (that pack is the revision the letter describes), any
   unchecked `- [ ]` in `tasks/<cycle>_promises.md` refuses the pack: each box is a change
   promised to a reviewer in writing, and a camera-ready that silently drops one is a broken
   commitment. List the open boxes with the skill that closes each; never check a box yourself.
5. **Soft findings are waived only on the record.** Outline rows short of `polished` (Sections) or
   `final` (Figures, Tables), evidence drift from `import.sh --diff`, a claim the latest audit did
   not verify, an open audit follow-up other than a naked number (step 4) — present the list,
   ask, and write the user's waivers into the SUBMISSION record. A waiver that is not recorded
   did not happen.
6. **The package leaks nothing.** The bundle holds what compiles the paper — sources, figures,
   styles, bibliography — and nothing else: no `mates/`, no `notes/`, no `tasks/`, no `.env`;
   under an anonymized cycle, nothing lint's anon families flag. `wkdrs/` is never committed
   (§1); the durable record is the SUBMISSION file and the tag. Editable figure sources stay
   home too: `manus/figs/srcs/` never ships, because a plotting script or `.drawio` file carries
   paths, usernames, and machine names that the rendered PDF does not.
7. **The venue template is supplied, never synthesized.** A venue's class, style, and `.bst`
   files come from an official kit the user hands over, are copied byte-for-byte, and are never
   edited — not to fix a compile error, not to shave a margin. Never fetch a kit, never rebuild
   one from memory of what a venue's class looks like: §9's boundary covers formats exactly as it
   covers numbers, and a recalled class is wrong in ways that surface at the portal. When a copy
   will not compile, the fix is in the generated `compat.sty` or the generated `main.tex`, or it
   is a line in the report.
8. **The venue format is generated, never authored.** Every conversion rebuilds the copy from
   `manus/` from scratch — there is no incremental sync and no second source of truth. A hand-fix
   applied inside the copy is erased by the next run, so it is never the answer; the answer is a
   change in `manus/` through the skill that owns the file. And the copy's page count, not the
   preprint build's, is what `page_limit_main` means: `lint.sh` measures a different document in
   a different class, which is a drafting proxy and not the answer.

9. **Fan out the sweeps, never the gates (§6).** Step 5's completeness sweep splits by its own
   checks once the ledger holds more than 6 stated claims (below that the main agent reads them
   itself) — one delegate for the outline's three tables, one for the figure PDFs against
   `figs/srcs/` and `mates/MANIFEST.md`, one for the claim ledger with its per-file audit dates —
   each returning its own shortfalls as findings and nothing else; `import.sh --diff` and the
   audit follow-up lists are one script call and one read the main agent does itself, and the
   promises file is step 3's gate, not a sweep; Step 6's checklist walk is one delegate per
   checklist item once the list carries more
   than 6. The completeness sweep's delegates run on the READ tier's model (conventions §11.6),
   where the harness can name one; the checklist walk's delegates run on this run's own tier,
   EXEC, because the record carries their pass / fail verdicts as given. The hard gates never
   split and never delegate: `execs/run.sh`, `execs/scpts/lint.sh`,
   and the tree check are single script calls whose exit codes the main agent reads itself (§6.3).
   Neither does anything from Step 8 on — the package, the record, the commit, and the freeze tag
   stay with the main agent (§6.4–§6.5).

## Workflow

**Where this run executes.** This run's tier is EXEC (conventions §11.6); it stays in the session
that started it, on the session's model. When the `STAGE_EXEC_MODEL` value names a model that is not
an alias of the session's, say so in one line at the start — the tier, that model, and the one way
to get it: switch the session's model — then continue here.

1. **Load and resolve.** Read the conventions in full. Resolve the mode from the argument and the
   active cycle per §5; read `cycls/<cycle>/venue.yml` and stop unless `confirmed:` is set and
   `page_limit_main`, `anonymized:`, and `checklist:` are filled. Stop, naming the `.env` `ANON`
   line to set before rerunning, when `ANON` does not fit the mode: a review pack needs it equal
   to `anonymized:`, and a camera pack needs `ANON=false` whatever `anonymized:` says, since that
   field records the venue's review rule and stays set. In a pack run whose `template:` names a
   kit, stop here too when `cycls/<cycle>/template/` is missing — route to
   `stage-subm-packer convert kit=<path>` — or when `bash execs/run.sh --help` does not list
   `--main` — route to `bash execs/update.sh`.
   **`convert` runs step 7 and nothing else** — no tree check, no promise gate, no build or lint
   gate, no sweep, no checklist, no package, no freeze commit, no tag — its own commit is step
   7's. That is deliberate: fitting a
   paper into a venue's page limit takes many conversions, and every one of them happens while
   `\todo` markers are still in the manuscript and `lint.sh` is still red. A conversion that only
   ran on a submittable paper could never be used to make one submittable. `convert` also relaxes
   the `venue.yml` stop to a warning — it reports the page count either way and says when the
   limit is unconfirmed or blank (§9c: an unconfirmed limit binds nothing).
2. **Tree check.** Stop on uncommitted changes under `manus/`, `mates/`, `notes/`, or `cycls/`,
   or in `tasks/<cycle>_promises.md` (Principle 2). Stop when tag `freeze/<cycle>_<date>` already
   exists.
3. **Promise gate (`camera`, or a response-letter revision's review pack per Principle 4).** Scan
   `tasks/<cycle>_promises.md` for `- [ ]`. Any hit → refuse: quote each open promise with the
   skill that closes it. A missing promises file beside a `RESPONSE_*` whose `sources:` names a
   `received_*` review is an inconsistency — flag it and ask before treating it as "no promises
   made". `camera` also refuses a `manus/main.tex` that still carries the shipped
   `\title{Untitled STAGE Manuscript}` (route to `stage-outl-planner`), the placeholder
   `\author{Anonymous Authors}`, or the `anon` class option — the last two are the author's own
   edits, named by line — and asks once whether the acknowledgments an anonymized draft left out
   are restored.
4. **Hard gates.** One is cheaper than the scripts and runs first: a `notes/adopt.md` whose
   `backfilled:` is empty. That is the adopted-draft state in which the manuscript's pre-existing
   numbers trace to nothing while `lint.sh` — which counts markers, and they carry none — reports
   clean (conventions §9a, §8.9). The marker count proves less than it appears to, so refuse and
   route to `stage-clms-auditor` to work the backlog down and set the field. A repository with no
   `notes/adopt.md` never started from a draft and skips this gate.
   Then compare `shasum -a 256` (or `sha256sum`) of every file `mates/MANIFEST.md` lists with its
   entry's `sha256:`: a mismatch is tampered evidence (§8.2, §9d), which refuses the pack and
   routes to `stage-evid-curator check` — never a waivable soft finding (§9e). An `n/a` checksum,
   or a host with neither tool, is a degraded check (§3.5), named in the SUBMISSION record.
   Then run `execs/run.sh` (record the PDF path and page count), then
   `execs/scpts/lint.sh --no-build`. Any hard failure stops the run and routes: `\todo` → the
   number's owner (stage-sect-drafter or stage-tabs-builder; stage-clms-auditor when
   unclear); undefined citations → stage-cite-auditor or stage-refs-curator; undefined
   references → the owner of the Tables or Figures row the label names (stage-tabs-builder or
   stage-figs-designer, with the row named) while its file is missing, else stage-sect-drafter;
   over the page limit → stage-copy-editor; identity leak → name the file and line. Lint's page
   count is the preprint build's: in a pack run whose `template:` names a kit, an over-limit
   count there is recorded and the run goes on, because step 7 re-checks it in the venue's own
   format and that is the count the limit means (Principle 8); with no kit the preprint is what
   ships, and lint's count is the gate.
   Then read `notes/claims.md`: a claim with a non-empty `Stated in` at `unsourced` is a hard
   failure too — lint has just shown no `\todo{` remains, so the row is a stale ledger or a marker
   deleted with its value kept (§9a, §9e); stop and route to `stage-clms-auditor`.
   So is an open `- [ ]` in `tasks/claims_followups.md` whose verdict is `unsourced`: a naked
   number in a sentence that states no ledger claim, or under a `weakened` or `dropped` row, has
   no `unsourced` row to show it, and no waiver ships it (§9e); stop and route to the owner the
   box names — a box whose number already traces or carries its `\todo` closes on a
   `stage-clms-auditor` re-run.
5. **Completeness sweep.** Check (split per Principle 9): outline Sections rows at `polished`,
   Figures and Tables rows at `final`; every `manus/figs/*.pdf` has a source under `figs/srcs/`
   or a `mates/MANIFEST.md` entry; no claim stated in the manuscript sits at **`weakened` or
   `dropped`** in `notes/claims.md` — `weakened` means a response conceded it in writing, so a
   manuscript still asserting it ships a claim its own authors have withdrawn, which reads worse
   to a reviewer than the original overclaim, and a `dropped` row is read in the files its
   `Stated in` names, since only a confirmed `stage-sect-drafter` removal trims it; no
   `performance` or `factual` claim stated in the manuscript sits at `drafted`, which means the
   latest claims audit did not verify it (`contribution` rows are outside this check: each
   measurable promise in one is a `performance` row of its own); no `verified` row is stated in
   a file revised after the audit that last covered it, because a `verified` row keeps its status
   when a later revision changes its number — for each `manus/secs/` or `manus/tabs/` file a
   `verified` row's `Stated in` names
   (a section value resolved against the outline's Sections table as conventions §5.2 resolves a
   section argument — `1_intro`, `intro`, and `abstract` alike — and `tabs/<slug>` →
   `manus/tabs/<slug>.tex`), `git log -1 --format=%cs -- <file>` is earlier than the date of the
   newest `wkdrs/reports/CLAIMS_<date>.md` whose `scope:` took that file in (resolved as
   `stage-clms-auditor` step 2 resolves a scope; a whole-manuscript report covers every file; a
   file committed the same day as that report cannot be ordered against it and is listed too),
   and with no report on disk say those dates cannot be checked — `wkdrs/` is never committed;
   no open `- [ ]` is left in `tasks/claims_followups.md` or `tasks/cites_followups.md` beyond
   the `unsourced` ones step 4 refuses — each is listed with the owner it names;
   `import.sh --diff` reports no drift (skip with a note when `STAR_HOME` is
   unset). Each miss is a soft finding: present the list with a recommendation and ask via
   AskQuestion — proceed with named waivers, or abort — recording waivers per Principle 5.
   Claims the latest audit did not verify route to `stage-clms-auditor` and are listed by ID with
   their waivers in the SUBMISSION record, and in the reply whether the author waives or aborts;
   they never block the pack. A `factual` row about a cited work is handed by the claims audit to
   `stage-cite-auditor`, which never flips a status, so it can stay `drafted` and return at every
   pack until waived — route it there and say so beside it.
6. **Checklist walk.** Per `venue.yml` `checklist:` — `none` skips; otherwise take the items from
   the checklist file the registered kit ships under `cycls/<cycle>/template/`, or, when it ships
   none, from the user, each entered only as the user confirms it (a mandatory confirmation point,
   §7.7, §9c) and never from memory of the family; walk them, asking the user for any fact the
   repo cannot answer (§9c: answers are the user's, never invented), and record the item list and
   pass / fail / waived per item.
7. **Convert.** Only when `venue.yml`'s `template:` names a kit — absent, empty, or `arxiv` means
   the paper ships in its preprint form and this step says so and does nothing. Otherwise follow
   `references/venue-convert.md`: resolve or register the kit into `cycls/<cycle>/template/`, read
   the kit's own example `.tex` and class files for the macros it wants, scaffold the copy,
   generate `compat.sty` and `main.tex`, and build the copy with
   `execs/run.sh --main <copy>/main.tex` (a pack run adds
   `--outdir wkdrs/builds/<cycle>_<date>_check/`, so no build product lands in the package). The
   copy goes to `wkdrs/builds/<cycle>_<template>_<date>/` in `convert` mode and becomes the
   package's source directory in a pack run. Compare the copy's content page count — counted as
   `references/venue-convert.md` §6 says, the way `lint.sh` counts the preprint — against
   `page_limit_main`: over the limit is a hard block in a pack run, routed to
   `stage-copy-editor`, and a reported number in `convert`. Report what was mapped, what was
   dropped for having no venue equivalent, and what needs a human — never drop content to make
   the copy compile.
   **What the conversion leaves for a human goes in `tasks/<cycle>_venue.md`**, not only in the
   reply — a dropped `\keywords`, an appendix ordering that needs a decision, a macro with no
   venue equivalent. One `- [ ]` line per finding, each with a stable `V<n>` id and the skill that
   owns the fix (shape below). The file is **updated, never regenerated**: a checked item stays
   checked and is never re-raised, so a conversion run twenty times over does not keep reopening
   what the user already settled. These are findings, not promises — an open box never blocks a
   pack, because refusing to ship over "`\paperdate` was dropped" teaches the author to ignore
   the gate that matters.
   **Only `convert` writes that file**, and only `convert` registers a kit: `kit=<path>` is
   ignored in a pack. `convert` offers one commit for what it wrote outside `wkdrs/` — the kit
   when it registered one, plus `tasks/<cycle>_venue.md` — subject
   `stage-subm-packer: convert <cycle> <template>` (§1). A pack run reads the list, reports its
   open items, and records this run's conversion findings in the SUBMISSION record instead; it
   writes no task file, because a file written after step 2's tree check would leave the freeze
   tag sitting on a tree that is no longer clean.
8. **Package.** Assemble `wkdrs/builds/<cycle>_<date>/`: the source directory — step 7's
   converted copy when the cycle has a template, otherwise the arXiv-ready form: `main.tex`,
   `secs/`, `tabs/`, `figs/*.pdf`, the needed `stys/`, and `bibs/reference.bib` plus the build's
   `.bbl` — then rebuild it with
   `bash execs/run.sh --main <source>/main.tex --outdir wkdrs/builds/<cycle>_<date>_check/`: a
   bundle that does not compile is not a package. That build's PDF goes into the package beside
   the source (review or camera per mode). List the package tree in the SUBMISSION record, and
   stop on a `.build/`, `*.aux`, `*.log`, or `*.fls` in it, or a `/Users/` or `/home/` path in a
   shipped text file.
9. **Record, commit, tag.** Write `cycls/<cycle>/SUBMISSION_<date>.md` (shape below; real date
   per §4), quote it (§7.12), and ask once, at every involve level — the freeze is the decision
   this slash-only skill exists for (§7.7, §11.1) — whether to commit it and tag that commit.
   Yes: commit it — one commit, staging only this file, subject
   `stage-subm-packer: freeze <cycle> <date>` (§1) — then create `freeze/<cycle>_<date>` on that
   commit. No: create no tag, leave the record uncommitted with `frozen:` naming the tag the
   printed lines would create, report **packed, not frozen**, and print the exact `git add`,
   `git commit`, and `git tag` lines. Never push; hand the user the portal or arXiv steps as their
   own next actions.

## Output

Output-table row (conventions §8): Submission — `cycls/<cycle>/SUBMISSION_<date>.md`, git tag
`freeze/<cycle>_<date>`, package under `wkdrs/builds/`, the registered venue template kit at
`cycls/<cycle>/template/`, venue follow-ups in `tasks/<cycle>_venue.md`; state field `frozen:`;
venue follow-up checkboxes.

`SUBMISSION_<date>.md` frontmatter: `cycle:`, `date:`, `frozen:` (the tag name), `package:` (the
path under `wkdrs/builds/`), `template:` (the venue template the package was formatted in, or
`arxiv`). Body: the lint summary, the checklist outcome with waivers, the claims the latest
audit did not verify with their waivers, the open audit follow-ups with their waivers, the
package tree, page counts against `page_limit_main` — **the converted
copy's count, with the preprint build's beside it when they differ** — what the conversion
dropped or left for a human, and what was submitted where, as the user states it, since the
upload is theirs.

`convert`'s durable outputs are the registered kit and `tasks/<cycle>_venue.md`; the copy itself
is regenerable and `wkdrs/` is never committed (§1).

`tasks/<cycle>_venue.md` frontmatter: `cycle:`, `template:`, `updated:` (real date per §4). Body:
one checkbox line per finding —

```markdown
- [ ] V1 — `\keywords{...}` has no equivalent in this kit and was dropped; decide whether the
      keywords belong in the abstract instead → stage-sect-drafter
- [x] V2 — appendix placed after the references, following the kit's example
```

Ids are `V<n>`, assigned in order and never reused. New findings append with the next free id; an
item that no longer applies is checked with its reason rather than deleted, so the list stays a
record of everything the conversion has ever asked for.

Chat digest, verdict first: **packed** — package path, tag name, the claims the latest audit did
not verify, what awaits the user — or **packed, not frozen** — the same, plus the `git add`,
`git commit`, and `git tag` lines step 9 printed — or
**converted** — copy path, page count against the limit with its confirmation state, what was
mapped, what was dropped, what needs a human — or **blocked (n)** with each blocker and the
exact command that clears it.

Provenance (conventions §8): every Markdown record this run writes under `notes/`, `tasks/`,
`cycls/`, or `wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one
appended `model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`, nor does any file of the venue kit under `cycls/<cycle>/template/` (conventions §8).
