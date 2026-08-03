# Agent Instructions

This is a STAGE repository — the paper-writing companion to STAR. One repo, one paper. The manuscript cites evidence; it never contains unsourced numbers. These rules bind every agent working here.

## 1. Read the Conventions First

**`docs/mds/stage-workflow/writing-workflow-conventions.md` is the shared baseline for all writing-workflow work.**

- Read the whole file at the start of every skill run. Skills cite its § numbers (§0 vocabulary … §9 fabrication boundary, §10 layout) and state only what is specific to themselves; where a skill is stricter, the skill wins.
- Skip the re-read only when the same file's text is still verbatim visible in this conversation. Summaries and memories of having read it don't count.
- Do not edit `docs/mds/stage-workflow/` — it is upstream-managed and `execs/update.sh` overwrites it. The same holds for the four skill trees, both `execs/` entrypoints (`update.sh` syncs itself), and this file with the Cursor rule that copies it; project-specific settings belong in `.env`, which is never synced.
- What each skill does is in `docs/mds/stage-workflow/writing-workflow-skills.md`.
- The `*.zh-CN.md` files beside the docs, and `SKILL_zh.md` beside each `SKILL.md`, are Chinese editions for human readers: never loaded at runtime, never authoritative. Load the English file and reply per §8.

## 2. Core Principles

**Evidence flows one way. The claim ledger is the hub. Deterministic checks live in scripts, judgment lives in skills.**

- **A — Evidence flows one way.** STAR artifacts (or hand-registered drops) are snapshotted into read-only `mates/` with a fingerprint, recorded in `mates/MANIFEST.md`; the manuscript only cites them. Numbers live upstream: to fix a number, fix it in STAR and re-import — never edit `mates/`.
- **B — The claim ledger is the hub.** `notes/claims.md` links every claim's statements ⇄ evidence ⇄ status (`proposed → drafted → verified / unsourced / weakened / dropped`). Writing states claims, audits verify them, responses defend them. Keep the ledger current in the same change as the text it tracks.
- **C — Deterministic checks live in scripts, judgment lives in skills.** What `lint.sh` or `import.sh --diff` can decide is never re-decided by prose; what needs judgment is never reduced to a grep.

## 3. Project Layout

**Keep files in their designated directories.** Full table and rules: conventions §10.

- Manuscript under `manus/`: entry `main.tex`; sections `secs/<n>_<slug>.tex`; figures `figs/` with sources in `figs/srcs/`; tables `tabs/`; bibliography `bibs/reference.bib`; venue styles `stys/`.
- Two template layers in `manus/stys/`, and the split is load-bearing: `arxiv.cls` owns the look and is what a venue class **replaces**; `stage.sty` owns `\todo` plus the macros skills write into `secs/` and `tabs/` (`\parahead`, `\cmark`, `\tablestyle`, `\figref` …) and **survives** every swap. Extend accordingly; project-specific macros go in `main.tex`, never in `stys/`.
- **The manuscript always compiles as the preprint; the venue's format is a generated copy.** An official venue kit unpacks whole and unedited into `cycls/<cycle>/template/` — beside that cycle's `venue.yml`, never under `manus/`, which is a scanned namespace where a kit's example `.tex` would trip `lint.sh`'s `\todo` count and its identity-leak scan. `template:` in `venue.yml` names the class inside the kit; `/stage-subm-packer convert` reads it and regenerates a standalone copy under `wkdrs/` that compiles under the venue's class. `manus/main.tex` keeps its `\documentclass{stys/arxiv}` — there is no in-place swap, and no second source of truth. Never fetch a venue template or write one from memory (§6).
- Evidence under `mates/` — **read-only**. `execs/scpts/import.sh` and `/stage-evid-curator` are the only writers, and they only add or replace whole files with fingerprints.
- Writing metadata under `notes/` — fixed files `story.md`, `claims.md`, `outline.md`, `notation.md`, `adopt.md`; reading notes in `notes/refs/`.
- Submission cycles under `cycls/<venue>_<year>/` — `venue.yml`, `template/` (the official venue kit), `reviews/`, `response/`, `SUBMISSION_<date>.md`. Revision scratch, promise lists, and venue follow-ups in `tasks/`: `<cycle>_promises.md` blocks a camera-ready until every box is kept; `<cycle>_venue.md` collects what a conversion left for a human and blocks nothing.
- Builds and ephemeral reports under `wkdrs/` — gitignored and regenerable; durable outcomes go to the ledger and `tasks/`, not reports.
- `execs/` root is closed: `run.sh` and `update.sh` only. Utilities (`import.sh`, `lint.sh`) live in `execs/scpts/`.

## 4. Writing Workflow Skills

**Fifteen skills. Invoke as `/stage-<name>` in Claude Code and Cursor, `$stage-<name>` in Codex, `/skill:stage-<name>` in Kimi Code.**

| Skill | Role |
| --- | --- |
| `stage-proj-adopt` † | wire a new or existing paper repo into STAGE |
| `stage-evid-curator` | import, register, and map evidence |
| `stage-stry-coach` † | shape the story; seed claims and the venue profile |
| `stage-outl-planner` † | outline, budgets, section skeletons, notation |
| `stage-sect-drafter` | draft one section per invocation |
| `stage-tabs-builder` | generate tables from evidence only |
| `stage-figs-designer` | figure inventory, sources, rendered PDFs |
| `stage-refs-curator` | bibliography, reading notes, positioning |
| `stage-copy-editor` | polish prose; never meaning, never numbers |
| `stage-clms-auditor` | trace every number to a fingerprint |
| `stage-cite-auditor` | verify citations against reading notes |
| `stage-peer-reviewer` | simulated five-perspective review panel |
| `stage-resp-writer` † | reviews → point ledger → response + promises |
| `stage-subm-packer` † | preflight, venue-template conversion, package, submission record, freeze |
| `stage-flow-status` | read-only status and the one next action |

- The five marked † are slash-only: run them only when the user names them — never on your own initiative. They are the decision points (adoption, story, outline, response, submission). The † markers above are the source of truth: the guards enforcing them — `disable-model-invocation: true` in the Claude, Cursor, and Kimi manifests, `allow_implicit_invocation: false` in `.agents/skills/<name>/agents/openai.yaml` for Codex — are checked against this table, so marking a skill here without guarding it in all four trees fails CI.
- `stage-flow-status` and `stage-peer-reviewer` never write to the manuscript; `stage-flow-status` writes nothing at all.
- When you do not know where things stand, run the status skill first — it reads the outline, ledger, manifest, and cycle state, and names the single next action.
- What each skill writes is the artifact registry, conventions §8. Do not hand-edit generated reports under `wkdrs/`.
- The same fifteen skills ship once per harness — `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.kimi-code/skills/` — differing only in invocation prefix and tool names (`Bash` / `Shell`, `AskUserQuestion` / `AskQuestion` / `request_user_input`, `Read` / `ReadFile`). Load the copy under your own root and follow it; the trees are not interchangeable, and a listing that surfaces another root's copy is telling you where a file is, not which one binds you.

## 5. Git

**One commit per skill working session; the subject names the skill.** Full rule: conventions §1.

- Commit only at a skill's documented commit step. Outside a skill run, do not commit, tag, or push unless the user asks.
- Never commit `wkdrs/` or `.env`. Everything else — manuscript, notes, evidence, cycles, tasks — is tracked.
- Freeze tags `freeze/<cycle>_<date>` are created only by `stage-subm-packer`.

## 6. The Fabrication Boundary

**Nothing in the manuscript pretends to be sourced.** Full rule: conventions §9.

- Every number in `manus/` either traces to a fingerprinted `mates/` entry or is written as `\todo{...}` — no third state.
- Every assertion about a cited paper must be checkable against a reading note (`notes/refs/` or imported refs under `mates/`).
- Venue rules in `venue.yml` are entered only as user-confirmed facts — never invent page limits, deadlines, or checklist requirements. The venue's LaTeX template is the same kind of fact: it comes from an official kit the user supplies, is copied byte-for-byte, and is never fetched, patched, or written from memory of what a venue's class looks like.
- Evidence files are immutable in place: register new files or re-import; never "correct" one.
- Nothing may weaken these rules to be helpful. A visible `\todo` is a state; a plausible invented number is a defect.

## 7. Build, Checks, and Dates

**`execs/run.sh` is the only build entrypoint.**

- `bash execs/run.sh` — latexmk, out-of-tree into `wkdrs/builds/`, engine from `.env` `LATEX_ENGINE`; prints the PDF path and page count.
- `bash execs/scpts/lint.sh` — undefined references, `\todo` count, page count vs the active cycle's `venue.yml`, anonymity leaks when `ANON=true`. Hard failures exit non-zero.
- Runtime configuration lives in `.env` (create from `.env.example`): `STAR_HOME` (optional — empty means standalone), `LATEX_ENGINE`, `ANON`, `STAGE_REPOSITORY`, `STAGE_LANG` (optional — empty means follow the conversation). Do not hardcode machine-specific paths.
- Real dates only: every date written into an artifact comes from the system clock, never from memory or invention (conventions §4).

## 8. Reply Language

**`.env` `STAGE_LANG` sets the language of chat replies and of the Markdown a run writes** — `notes/`, `tasks/`, simulated reviews, `wkdrs/` reports. Full rule: conventions §7.6.

- Set (`en` or `zh`) → use it, whatever the chat's language. Unset or empty → follow the user's dialogue language. An explicit in-conversation request wins over both.
- Resolve it once at the start of a run: `grep -sE '^STAGE_LANG=' .env || true`, folded into the opening load call.
- **Always English, whatever it says**: everything under `manus/` (prose, captions, `% src:` comments, `\todo{}` text) and the response to reviewers under `cycls/<cycle>/response/` — both are read by people outside this repository.
- **Structural literals are English inside a document written in any language**: frontmatter keys and values, ledger statuses, claim and point IDs, paths, bibkeys, venue, dataset, and metric names — anything a script greps.
- An existing document keeps the language it was written in; `STAGE_LANG` governs what a run writes, never a retranslation.
