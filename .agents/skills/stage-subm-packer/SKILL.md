---
name: stage-subm-packer
description: >-
  Preflight and package a submission for the active cycle: the execs/run.sh build and
  execs/scpts/lint.sh gate must both pass, then a checklist walk over user-confirmed venue.yml
  facts, a figure/table/bibliography completeness sweep, a package (camera PDF, supplementary,
  arXiv-ready source) under wkdrs/builds/, the durable record cycls/<cycle>/SUBMISSION_<date>.md,
  and the freeze tag freeze/<cycle>_<date> — the one skill in the family allowed to create a git
  tag. Camera-ready mode additionally refuses to pack while tasks/<cycle>_promises.md holds
  unchecked promise boxes. It packages and records; it never uploads to a portal, never pushes,
  never edits the manuscript. Use when the user invokes $stage-subm-packer, or asks to package,
  freeze, or prepare the submission, the camera-ready, or the arXiv source.
---

# Submission Packer — preflight, package, freeze

Match the user's language in dialogue: for Chinese dialogue, reply in Chinese. All repo resources
(the conventions, this skill) are English-only in v1 and are loaded as-is; zh-CN editions are on
the roadmap and, when they exist, are kept in step for human readers only — this SKILL.md stays
authoritative.

Invocation: `$stage-subm-packer [camera]` — no argument packs a review submission for the active
cycle, resolved per conventions §5 from `cycle:` in `notes/story.md`; `camera` packs the
camera-ready for the same cycle and arms the promise gate; an unrecognized argument names the two
modes and asks.

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` in full at
the start of every run — v1 has no section-selective loading. It is the baseline every STAGE
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
   (§9c). An unconfirmed profile stops the run — route to $stage-stry-coach; never fill in a
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
   (§1); the durable record is the SUBMISSION file and the tag.

## Workflow

1. **Load and resolve.** Read the conventions in full. Resolve the mode from the argument and the
   active cycle per §5; read `cycls/<cycle>/venue.yml` and stop unless `confirmed:` is set. When
   `anonymized: true` disagrees with `.env`'s `ANON` (review pack needs `true`; camera needs
   `false`), stop and say which `.env` line to flip before rerunning.
2. **Tree check.** Stop on uncommitted changes under `manus/`, `notes/`, or `cycls/`
   (Principle 2). Stop when tag `freeze/<cycle>_<date>` already exists.
3. **Camera gate (`camera` only).** Scan `tasks/<cycle>_promises.md` for `- [ ]`. Any hit →
   refuse: quote each open promise with the skill that closes it. A missing promises file beside
   an existing `cycls/<cycle>/response/` is an inconsistency — flag it and ask before treating it
   as "no promises made".
4. **Hard gates.** Run `execs/run.sh` (record the PDF path and page count), then
   `execs/scpts/lint.sh --no-build`. Any hard failure stops the run and routes: `\todo` → the
   number's owner ($stage-sect-drafter or $stage-tabs-builder; $stage-clms-auditor when
   unclear); undefined citations → $stage-cite-auditor or $stage-refs-curator; over the page
   limit → $stage-copy-editor; identity leak → name the file and line.
5. **Completeness sweep.** Check: outline Sections rows at `polished` or better, Figures and
   Tables rows at `final`; every `manus/figs/*.pdf` has a source under `figs/srcs/` or a
   `mates/MANIFEST.md` entry; no claim stated in the manuscript sits at `unsourced` in
   `notes/claims.md`; `import.sh --diff` reports no drift (skip with a note when `STAR_HOME` is
   unset). Each miss is a soft finding: present the list with a recommendation and ask via
   `request_user_input` — proceed with named waivers, or abort — recording waivers per Principle 5.
6. **Checklist walk.** Per `venue.yml` `checklist:` — `none` skips; otherwise walk the family's
   items, asking the user for any fact the repo cannot answer (§9c: answers are the user's, never
   invented), and record pass / fail / waived per item.
7. **Package.** Assemble `wkdrs/builds/<cycle>_<date>/`: the built PDF (review or camera per
   mode), the supplementary when the venue and outline define one, and an arXiv-ready source
   directory — `main.tex`, `secs/`, `tabs/`, `figs/*.pdf`, the needed `stys/`, and
   `bibs/reference.bib` plus the build's `.bbl` — then rebuild from inside the package with the
   same engine: a bundle that does not compile is not a package.
8. **Record, commit, tag.** Write `cycls/<cycle>/SUBMISSION_<date>.md` (shape below; real date
   per §4). Commit it — one commit, staging only this file, subject
   `stage-subm-packer: freeze <cycle> <date>` (§1) — then create `freeze/<cycle>_<date>` on that
   commit. Never push; hand the user the portal or arXiv steps as their own next actions.

## Output

Registry row (conventions §8): Submission — `cycls/<cycle>/SUBMISSION_<date>.md`, git tag
`freeze/<cycle>_<date>`, package under `wkdrs/builds/`; state field `frozen:`.

`SUBMISSION_<date>.md` frontmatter: `cycle:`, `date:`, `frozen:` (the tag name), `package:` (the
path under `wkdrs/builds/`). Body: the lint summary, the checklist outcome with waivers, page
counts against `page_limit_main`, and what was submitted where — as the user states it, since the
upload is theirs.

Chat digest, verdict first: **packed** — package path, tag name, what awaits the user — or
**blocked (n)** with each blocker and the $stage-* skill that clears it.
