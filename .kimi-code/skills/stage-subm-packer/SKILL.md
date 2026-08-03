---
name: stage-subm-packer
disable-model-invocation: true
description: >-
  Preflight and package a submission for the active cycle: the execs/run.sh build and
  execs/scpts/lint.sh gate must both pass, then a checklist walk over user-confirmed venue.yml
  facts, a figure/table/bibliography completeness sweep, a package (camera PDF, supplementary,
  arXiv-ready source) under wkdrs/builds/, the durable record cycls/<cycle>/SUBMISSION_<date>.md,
  and the freeze tag freeze/<cycle>_<date> — the one skill in the family allowed to create a git
  tag. Camera-ready mode additionally refuses to pack while tasks/<cycle>_promises.md holds
  unchecked promise boxes; convert mode reformats the paper into a user-supplied official venue
  template as a regenerable copy under wkdrs/, never fetching or reconstructing one. It packages
  and records; it never uploads to a portal, never pushes, never edits the manuscript. Use when
  the user runs /skill:stage-subm-packer, or asks to package, freeze, convert to a venue template, or
  prepare the submission, the camera-ready, or the arXiv source.
---

# Submission Packer — preflight, package, freeze

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

Invocation: `/skill:stage-subm-packer [camera | convert] [kit=<path>]` — no argument packs a review
submission for the active cycle, resolved per conventions §5 from `cycle:` in `notes/story.md`;
`camera` packs the camera-ready for the same cycle and arms the promise gate; `convert` only
reformats the paper into the cycle's venue template and reports the page count in that format,
skipping every freeze gate. `kit=<path>` registers an official venue template kit (a zip or a
directory) before converting. An unrecognized argument names the three modes and asks.

**Conversion procedure.** `references/venue-convert.md` — the kit contract, what `stys/arxiv.cls`
owns and a venue class must replace, the abstract relocation, `compat.sty`, and the anonymity
mapping. Read it before converting; it is not needed on a run that does not convert.

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` in full at
the start of every run — there is no section-selective loading. It is the baseline every STAGE
skill shares; the sections that bind this skill hardest are §1 git (freeze tags
`freeze/<cycle>_<date>` are created only here), §3 the build toolchain and `ANON`, §5 cycle
resolution, and §9 the fabrication boundary. This file states what is specific to this skill and
wins wherever it is stricter.

**Reusing an earlier load.** Skip the re-read only when the conventions file's own text is still
verbatim visible in this conversation. A summary that survived a context compaction and a memory
of having read it both fail that test — when in doubt, read it again; a wasted read costs one
message, a wrong assumption costs the freeze.

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
   that must not exist.
2. **A freeze tag tells the truth or it lies forever.** `freeze/<cycle>_<date>` is created only
   on a clean tree: uncommitted changes under `manus/`, `notes/`, or `cycls/` stop the run before
   the gates — those commits belong to the sessions that made the edits (§1). An existing tag is
   never moved or deleted; when today's name is already taken, say so and stop. This is the only
   skill in the roster allowed to create a tag, and it creates exactly one per pack.
3. **Venue facts are user-confirmed or absent.** Page limits, deadlines, checklist family, and
   anonymization come from `cycls/<cycle>/venue.yml` and bind only when its `confirmed:` is set
   (§9c). An unconfirmed profile stops the run — route to /skill:stage-stry-coach; never fill in a
   limit from memory to keep the pack moving.
4. **Camera-ready honors every promise.** In `camera` mode, any unchecked `- [ ]` in
   `tasks/<cycle>_promises.md` refuses the pack: each box is a change promised to a reviewer in
   writing, and a camera-ready that silently drops one is a broken commitment. List the open
   boxes with the skill that closes each; never check a box yourself.
5. **Soft findings are waived only on the record.** Outline rows short of final, evidence drift
   from `import.sh --diff`, a missing supplementary — present the list, ask, and write the user's
   waivers into the SUBMISSION record. A waiver that is not recorded did not happen.
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

## Workflow

1. **Load and resolve.** Read the conventions in full. Resolve the mode from the argument and the
   active cycle per §5; read `cycls/<cycle>/venue.yml` and stop unless `confirmed:` is set. When
   `anonymized: true` disagrees with `.env`'s `ANON` (review pack needs `true`; camera needs
   `false`), stop and say which `.env` line to flip before rerunning.
   **`convert` runs step 7 and nothing else** — no tree check, no promise gate, no build or lint
   gate, no sweep, no checklist, no package, no commit, no tag. That is deliberate: fitting a
   paper into a venue's page limit takes many conversions, and every one of them happens while
   `\todo` markers are still in the manuscript and `lint.sh` is still red. A conversion that only
   ran on a submittable paper could never be used to make one submittable. `convert` also relaxes
   the `confirmed:` stop to a warning — it reports the page count either way and says the limit
   is unconfirmed (§9c: an unconfirmed limit binds nothing).
2. **Tree check.** Stop on uncommitted changes under `manus/`, `notes/`, or `cycls/`
   (Principle 2). Stop when tag `freeze/<cycle>_<date>` already exists.
3. **Camera gate (`camera` only).** Scan `tasks/<cycle>_promises.md` for `- [ ]`. Any hit →
   refuse: quote each open promise with the skill that closes it. A missing promises file beside
   an existing `cycls/<cycle>/response/` is an inconsistency — flag it and ask before treating it
   as "no promises made".
4. **Hard gates.** One is cheaper than the scripts and runs first: a `notes/adopt.md` whose
   `backfilled:` is empty. That is the adopted-draft state in which the manuscript's pre-existing
   numbers trace to nothing while `lint.sh` — which counts markers, and they carry none — reports
   clean (conventions §9a, §8.9). The marker count proves less than it appears to, so refuse and
   route to `/skill:stage-clms-auditor` to work the backlog down and set the field. A repository with no
   `notes/adopt.md` never started from a draft and skips this gate.
   Then run `execs/run.sh` (record the PDF path and page count), then
   `execs/scpts/lint.sh --no-build`. Any hard failure stops the run and routes: `\todo` → the
   number's owner (/skill:stage-sect-drafter or /skill:stage-tabs-builder; /skill:stage-clms-auditor when
   unclear); undefined citations → /skill:stage-cite-auditor or /skill:stage-refs-curator; over the page
   limit → /skill:stage-copy-editor; identity leak → name the file and line. Lint's page count is the
   preprint build's; step 7 re-checks it in the venue's own format, and that is the count the
   limit means (Principle 8).
5. **Completeness sweep.** Check: outline Sections rows at `polished` or better, Figures and
   Tables rows at `final`; every `manus/figs/*.pdf` has a source under `figs/srcs/` or a
   `mates/MANIFEST.md` entry; no claim stated in the manuscript sits at `unsourced` **or
   `weakened`** in `notes/claims.md` — `weakened` means a response conceded it in writing, so a
   manuscript still asserting it ships a claim its own authors have withdrawn, which reads worse
   to a reviewer than the original overclaim; `import.sh --diff` reports no drift (skip with a note when `STAR_HOME` is
   unset). Each miss is a soft finding: present the list with a recommendation and ask via
   AskUserQuestion — proceed with named waivers, or abort — recording waivers per Principle 5.
6. **Checklist walk.** Per `venue.yml` `checklist:` — `none` skips; otherwise walk the family's
   items, asking the user for any fact the repo cannot answer (§9c: answers are the user's, never
   invented), and record pass / fail / waived per item.
7. **Convert.** Only when `venue.yml`'s `template:` names a kit — absent, empty, or `arxiv` means
   the paper ships in its preprint form and this step says so and does nothing. Otherwise follow
   `references/venue-convert.md`: resolve or register the kit into `cycls/<cycle>/template/`, read
   the kit's own example `.tex` and class files for the macros it wants, scaffold the copy,
   generate `compat.sty` and `main.tex`, and build the copy with
   `execs/run.sh --main <copy>/main.tex`. The copy goes to
   `wkdrs/builds/<cycle>_<template>_<date>/` in `convert` mode and becomes the package's source
   directory in a pack run. Compare the copy's page count against `page_limit_main`: over the
   limit is a hard block in a pack run, routed to `/skill:stage-copy-editor`, and a reported number in
   `convert`. Report what was mapped, what was dropped for having no venue equivalent, and what
   needs a human — never drop content to make the copy compile.
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
   tag sitting on a tree that is no longer clean. A pack whose `cycls/<cycle>/template/` is
   missing stops and routes to `/skill:stage-subm-packer convert kit=<path>`.
8. **Package.** Assemble `wkdrs/builds/<cycle>_<date>/`: the built PDF (review or camera per
   mode), the supplementary when the venue and outline define one, and the source directory —
   step 7's converted copy when the cycle has a template, otherwise the arXiv-ready form:
   `main.tex`, `secs/`, `tabs/`, `figs/*.pdf`, the needed `stys/`, and `bibs/reference.bib` plus
   the build's `.bbl` — then rebuild from inside the package with the same engine: a bundle that
   does not compile is not a package.
9. **Record, commit, tag.** Write `cycls/<cycle>/SUBMISSION_<date>.md` (shape below; real date
   per §4). Commit it — one commit, staging only this file, subject
   `stage-subm-packer: freeze <cycle> <date>` (§1) — then create `freeze/<cycle>_<date>` on that
   commit. Never push; hand the user the portal or arXiv steps as their own next actions.

## Output

Registry row (conventions §8): Submission — `cycls/<cycle>/SUBMISSION_<date>.md`, git tag
`freeze/<cycle>_<date>`, package under `wkdrs/builds/`; state field `frozen:`.

`SUBMISSION_<date>.md` frontmatter: `cycle:`, `date:`, `frozen:` (the tag name), `package:` (the
path under `wkdrs/builds/`), `template:` (the venue template the package was formatted in, or
`arxiv`). Body: the lint summary, the checklist outcome with waivers, page counts against
`page_limit_main` — **the converted copy's count, with the preprint build's beside it when they
differ** — what the conversion dropped or left for a human, and what was submitted where, as the
user states it, since the upload is theirs.

`convert`'s durable outputs are the registered kit and `tasks/<cycle>_venue.md`; the copy itself
is regenerable and `wkdrs/` is never committed (§1).

`tasks/<cycle>_venue.md` frontmatter: `cycle:`, `template:`, `updated:` (real date per §4). Body:
one checkbox line per finding —

```markdown
- [ ] V1 — `\keywords{...}` has no equivalent in this kit and was dropped; decide whether the
      keywords belong in the abstract instead → /skill:stage-sect-drafter
- [x] V2 — appendix placed after the references, following the kit's example
```

Ids are `V<n>`, assigned in order and never reused. New findings append with the next free id; an
item that no longer applies is checked with its reason rather than deleted, so the list stays a
record of everything the conversion has ever asked for.

Chat digest, verdict first: **packed** — package path, tag name, what awaits the user — or
**converted** — copy path, page count against the limit with its confirmation state, what was
mapped, what was dropped, what needs a human — or **blocked (n)** with each blocker and the
/skill:stage-* skill that clears it.
