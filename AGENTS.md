# Agent Instructions

This is a STAGE repository — the paper-writing companion to STAR. One repo, one paper. The manuscript cites evidence; it never contains unsourced numbers. These rules bind every agent working here.

## 1. Read the Conventions First

**`docs/mds/stage-workflow/writing-workflow-conventions.md` is the shared baseline for all writing-workflow work.**

- Read the whole file at the start of every skill run. Skills cite its § numbers (§0 vocabulary … §9 fabrication boundary, §10 layout) and state only what is specific to themselves; where a skill is stricter, the skill wins.
- Skip the re-read only when the same file's text is still verbatim visible in this conversation. Summaries and memories of having read it don't count.
- Do not edit `docs/mds/stage-workflow/` — it is upstream-managed and `execs/update.sh` overwrites it.
- What each skill does is in `docs/mds/stage-workflow/writing-workflow-skills.md`.

## 2. Core Principles

**Evidence flows one way. The claim ledger is the hub. Deterministic checks live in scripts, judgment lives in skills.**

- **A — Evidence flows one way.** STAR artifacts (or hand-registered drops) are snapshotted into read-only `mates/` with a fingerprint, recorded in `mates/MANIFEST.md`; the manuscript only cites them. Numbers live upstream: to fix a number, fix it in STAR and re-import — never edit `mates/`.
- **B — The claim ledger is the hub.** `notes/claims.md` links every claim's statements ⇄ evidence ⇄ status (`proposed → drafted → verified / unsourced / weakened / dropped`). Writing states claims, audits verify them, responses defend them. Keep the ledger current in the same change as the text it tracks.
- **C — Deterministic checks live in scripts, judgment lives in skills.** What `lint.sh` or `import.sh --diff` can decide is never re-decided by prose; what needs judgment is never reduced to a grep.

## 3. Project Layout

**Keep files in their designated directories.** Full table and rules: conventions §10.

- Manuscript under `manus/`: entry `main.tex`; sections `secs/<n>_<slug>.tex`; figures `figs/` with sources in `figs/srcs/`; tables `tabs/`; bibliography `bibs/reference.bib`; venue styles `stys/`.
- Evidence under `mates/` — **read-only**. `execs/scpts/import.sh` and `/stage-evid-curator` are the only writers, and they only add or replace whole files with fingerprints.
- Writing metadata under `notes/` — fixed files `story.md`, `claims.md`, `outline.md`, `notation.md`, `adopt.md`; reading notes in `notes/refs/`.
- Submission cycles under `cycls/<venue>_<year>/` — `venue.yml`, `reviews/`, `response/`, `SUBMISSION_<date>.md`. Revision scratch and promise lists in `tasks/`.
- Builds and ephemeral reports under `wkdrs/` — gitignored and regenerable; durable outcomes go to the ledger and `tasks/`, not reports.
- `execs/` root is closed: `run.sh` and `update.sh` only. Utilities (`import.sh`, `lint.sh`) live in `execs/scpts/`.

## 4. Writing Workflow Skills

**Fifteen skills. Invoke as `/stage-<name>` in Claude Code, `$stage-<name>` in Codex.**

| Skill | Role |
| --- | --- |
| `stage-proj-adopt` † | wire a new or existing paper repo into STAGE |
| `stage-evid-curator` | import, register, and map evidence |
| `stage-stry-coach` † | shape the story; seed claims and the venue profile |
| `stage-plan-outliner` † | outline, budgets, section skeletons, notation |
| `stage-sect-drafter` | draft one section per invocation |
| `stage-tabs-builder` | generate tables from evidence only |
| `stage-figs-designer` | figure inventory, sources, rendered PDFs |
| `stage-refs-curator` | bibliography, reading notes, positioning |
| `stage-copy-editor` | polish prose; never meaning, never numbers |
| `stage-clms-auditor` | trace every number to a fingerprint |
| `stage-cite-auditor` | verify citations against reading notes |
| `stage-peer-reviewer` | simulated review, one lens per run |
| `stage-resp-writer` † | reviews → point ledger → response + promises |
| `stage-subm-packer` † | preflight, package, submission record, freeze |
| `stage-flow-status` | read-only status and the one next action |

- The five marked † are slash-only: run them only when the user names them — never on your own initiative. They are the decision points (adoption, story, outline, response, submission).
- `stage-flow-status` and `stage-peer-reviewer` never write to the manuscript; `stage-flow-status` writes nothing at all.
- When you do not know where things stand, run the status skill first — it reads the outline, ledger, manifest, and cycle state, and names the single next action.
- What each skill writes is the artifact registry, conventions §8. Do not hand-edit generated reports under `wkdrs/`.

## 5. Git

**One commit per skill working session; the subject names the skill.** Full rule: conventions §1.

- Commit only at a skill's documented commit step. Outside a skill run, do not commit, tag, or push unless the user asks.
- Never commit `wkdrs/` or `.env`. Everything else — manuscript, notes, evidence, cycles, tasks — is tracked.
- Freeze tags `freeze/<cycle>_<date>` are created only by `stage-subm-packer`.

## 6. The Fabrication Boundary

**Nothing in the manuscript pretends to be sourced.** Full rule: conventions §9.

- Every number in `manus/` either traces to a fingerprinted `mates/` entry or is written as `\todo{...}` — no third state.
- Every assertion about a cited paper must be checkable against a reading note (`notes/refs/` or imported refs under `mates/`).
- Venue rules in `venue.yml` are entered only as user-confirmed facts — never invent page limits, deadlines, or checklist requirements.
- Evidence files are immutable in place: register new files or re-import; never "correct" one.
- Nothing may weaken these rules to be helpful. A visible `\todo` is a state; a plausible invented number is a defect.

## 7. Build, Checks, and Dates

**`execs/run.sh` is the only build entrypoint.**

- `bash execs/run.sh` — latexmk, out-of-tree into `wkdrs/builds/`, engine from `.env` `LATEX_ENGINE`; prints the PDF path and page count.
- `bash execs/scpts/lint.sh` — undefined references, `\todo` count, page count vs the active cycle's `venue.yml`, anonymity leaks when `ANON=true`. Hard failures exit non-zero.
- Runtime configuration lives in `.env` (create from `.env.example`): `STAR_HOME` (optional — empty means standalone), `LATEX_ENGINE`, `ANON`, `STAGE_REPOSITORY`. Do not hardcode machine-specific paths.
- Real dates only: every date written into an artifact comes from the system clock, never from memory or invention (conventions §4).
