<div align="center">
  <h1>STAGE</h1>
  <p><strong>Systematic Toolchain for Authoring, Guiding, and Editing</strong></p>
  <p><em>The academic-writing companion to STAR — every STAR needs a STAGE.</em></p>
</div>

**Language:** English | [简体中文](README.zh-CN.md)

STAGE turns a research project into a submitted paper without losing the chain of custody along the way. It keeps the manuscript, imported experimental evidence, writing metadata, and submission cycles in predictable locations, gives researchers and AI writing agents one build entrypoint and one shared set of instructions, and runs a complete writing workflow — evidence import, story, outline, drafting, figures and tables, audits, simulated review, response, and submission packaging. Every number in the manuscript traces to a fingerprinted evidence file or is visibly marked as missing; every claim is tracked from proposal to verification in a single ledger.

STAGE is the writing-side companion to [STAR](https://github.com/wanghao9610/STAR) (*Systematic Toolchain for AI Research*): STAR runs the research and produces the method documents, results, and digests; STAGE snapshots them as read-only evidence and writes the paper on top. The pairing is optional — STAGE also works standalone, with evidence registered by hand.

STAGE is double-layered: this repository is the **template**; one paper = one **instance**, created by cloning the template or by installing its skeleton into an existing paper repo with `execs/update.sh --adopt`. Instances later sync STAGE-managed skills and workflow docs from upstream via `update.sh`, without touching the manuscript.

## Contents

- [Contents](#contents)
- [What STAGE provides](#what-stage-provides)
- [Project structure](#project-structure)
- [Manuscript template](#manuscript-template)
- [Quick start](#quick-start)
  - [1. Create the paper repo](#1-create-the-paper-repo)
  - [1b. Or adopt a paper repo that already exists](#1b-or-adopt-a-paper-repo-that-already-exists)
  - [2. Configure `.env`](#2-configure-env)
  - [3. Path A: paired with a STAR repo](#3-path-a-paired-with-a-star-repo)
  - [4. Path B: standalone](#4-path-b-standalone)
  - [5. Build and lint](#5-build-and-lint)
  - [6. Start the writing workflow](#6-start-the-writing-workflow)
- [Writing workflow](#writing-workflow)
- [The ten-step path to a submission](#the-ten-step-path-to-a-submission)
- [Evidence, fingerprints, and the claim ledger](#evidence-fingerprints-and-the-claim-ledger)
- [Updating STAGE skills and workflow docs](#updating-stage-skills-and-workflow-docs)
- [Roadmap](#roadmap)
- [Citation](#citation)
- [License](#license)

## What STAGE provides

- **A consistent manuscript layout**: sections, figures with their sources, tables, bibliography, and venue styles each in one place under `manus/`.
- **A read-only evidence layer**: STAR artifacts (or hand-registered drops) are snapshotted into `mates/` with a fingerprint per file, recorded in `mates/MANIFEST.md`. Evidence flows one way — to fix a number, fix it upstream and re-import; `mates/` is never edited in place.
- **A claim ledger as the hub**: `notes/claims.md` links every claim's statements ⇄ evidence ⇄ status. Writing states claims, audits verify them, responses defend them.
- **One build entrypoint**: `execs/run.sh` compiles `manus/main.tex` with latexmk, out-of-tree into `wkdrs/builds/`, and prints the PDF path and page count.
- **Deterministic checks in scripts, judgment in skills**: `execs/scpts/lint.sh` catches undefined references, `\todo` markers, page-limit overruns, and anonymity leaks mechanically; the fifteen skills handle everything that needs judgment.
- **A complete writing lifecycle** through fifteen complementary skills, in the order they run: wire the repo, curate evidence, shape the story, outline the paper, draft each section, build tables from evidence, design figures, curate references, polish the prose, audit every number, audit every citation, simulate review, write the response, pack the submission, and report status.
- **Submission cycles as data**: each venue attempt lives in `cycls/<venue>_<year>/` with a user-confirmed `venue.yml` profile, received and simulated reviews, the response, and a frozen submission record.
- **Dual agent trees**: the same fifteen skills for Claude Code (`.claude/skills/`) and Codex (`.agents/skills/`), plus one shared `AGENTS.md`.
- **zh-CN mirrors for human readers**: `SKILL_zh.md` beside every `SKILL.md`, `*_zh.md` beside the peer-reviewer references, and `*.zh-CN.md` beside the conventions and the skills guide — kept in step, never loaded at runtime, and the English files stay authoritative.

See [Writing workflow](#writing-workflow) for what each skill does and how to invoke it. The [Writing Workflow Skills Guide](docs/mds/stage-workflow/writing-workflow-skills.md) adds a paragraph per skill and the pipeline diagram; the rules every skill shares are in the [Writing Workflow Conventions](docs/mds/stage-workflow/writing-workflow-conventions.md).

## Project structure

```text
STAGE/
├── manus/                  # The manuscript
│   ├── main.tex            # Entry point; compiles standalone out of the box
│   ├── secs/               # Section sources: <n>_<slug>.tex (0_abstract.tex, 1_intro.tex, …)
│   ├── figs/               # Rendered figures (PDF); figs/srcs/ holds every figure's source
│   ├── tabs/               # Tables, generated from evidence
│   ├── bibs/               # reference.bib
│   └── stys/               # arxiv.cls (the look) + stage.sty (\todo and authoring macros)
├── mates/                  # Imported evidence — read-only
│   ├── <source-slug>/      # Snapshots mirroring upstream STAR paths
│   ├── manual/             # Hand-registered evidence drops
│   └── MANIFEST.md         # The fingerprint ledger: one entry per evidence file
├── notes/                  # Writing metadata
│   ├── story.md            # Also: claims.md, outline.md, notation.md, adopt.md
│   └── refs/               # Reading notes per paper + refs_index.md
├── cycls/                  # Submission cycles
│   └── <venue>_<year>/     # venue.yml, reviews/, response/, SUBMISSION_<date>.md
├── tasks/                  # Revision scratch and promise lists
├── wkdrs/                  # Builds and ephemeral reports (gitignored, regenerable)
├── execs/
│   ├── run.sh              # Build entrypoint (latexmk, out-of-tree)
│   ├── update.sh           # Sync upstream STAGE skills and docs; --adopt installs the skeleton
│   └── scpts/              # import.sh (evidence import), lint.sh (deterministic checks)
├── docs/mds/stage-workflow/ # Conventions + skills guide (upstream-managed)
├── .claude/skills/         # Writing workflow skills for Claude Code
├── .agents/skills/         # Writing workflow skills for Codex
├── .env.example            # Local configuration example
├── AGENTS.md               # Shared instructions for AI writing agents
├── CLAUDE.md               # Symlink to AGENTS.md, so Claude Code loads the same rules
└── README.md
```

The abbreviated directory names follow STAR's convention:

| Directory | Stands for | Contents |
| --- | --- | --- |
| `manus/` | Manuscripts | The paper's LaTeX sources |
| `secs/` | Sections | One `.tex` file per section |
| `figs/` | Figures | Rendered PDFs; `srcs/` their editable sources |
| `tabs/` | Tables | Table `.tex` files, generated from evidence |
| `bibs/` | Bibliographies | `reference.bib` |
| `stys/` | Styles | `arxiv.cls`, `stage.sty`, and any venue class/style files |
| `mates/` | Materials | Imported evidence snapshots — read-only |
| `cycls/` | Cycles | One directory per submission attempt |
| `execs/` | Executions | Entrypoint scripts; `scpts/` the utilities |
| `wkdrs/` | Work directories | Builds and ephemeral reports, never committed |
| `mds/` | Markdowns | Markdown documentation, grouped by topic |

Three rules the tree alone does not carry: `mates/` is read-only (`import.sh` and `/stage-evid-curator` are the only writers, adding or replacing whole files with fingerprints); `wkdrs/` is never committed (durable audit outcomes live as status flips in `notes/claims.md` and entries in `tasks/`, not in reports); and the `execs/` root is closed (`run.sh` + `update.sh` and nothing else — utilities go in `execs/scpts/`).

## Manuscript template

`manus/` ships a compact, arXiv-style preprint template, split into two layers, because one of them has to survive a venue swap and the other is the thing being swapped:

| Layer | File | Owns | On a venue swap |
| --- | --- | --- | --- |
| The look | `manus/stys/arxiv.cls` | page geometry, fonts, the title panel, headings, captions, floats, bibliography style | **replaced** — drop the venue's class into `manus/stys/` and change one line: `\documentclass{stys/cvpr}` |
| The authoring layer | `manus/stys/stage.sty` | `\todo{...}` plus the macros the writing skills emit into `secs/` and `tabs/` | **kept** — the line `\usepackage{stys/stage}` stays whatever the class becomes |

Keep that split when you extend either file: anything a section or table file writes belongs in the package; anything only the page look needs belongs in the class. Project-specific macros (`\newcommand{\method}{...}`) go in `main.tex`, never in `stys/` — both template files get replaced or updated under you.

**Class options** — `\documentclass[twocolumn]{stys/arxiv}`: `onecolumn` | `twocolumn`, plus `anon` and anything `article` takes. Inside the preamble, `\paperstyle{fancy|simple}` picks a framed or flat title panel and `\papercolor{green|blue|black}` sets the theme.

**Title panel** — collected in the preamble, typeset once by `\maketitle`:

| Command | Notes |
| --- | --- |
| `\title{...}` | an over-long title drops one font size automatically rather than pushing the panel down the page |
| `\author[1,\ast]{Name}` | repeatable, in order; the optional argument keys the superscripts |
| `\affiliation[1]{...}`, `\contribution[\ast]{...}` | repeatable |
| `\abstract{...}` | a **command, not an environment** — so `secs/0_abstract.tex` is `\input` in the preamble, not in the body |
| `\keywords{...}` | printed under the abstract |
| `\code{}` `\project{}` `\dataset{}` `\demo{}` `\correspondence{}` `\paperdate{}` | the links row; `\metadata[label]{value}` adds an arbitrary one |

**Authoring macros** from `stage.sty`, available under any class: `\todo{...}` (the unsourced-value marker `lint.sh` counts), `\parahead{...}` and `\headbf{...}`, `\cmark` / `\xmark`, `\tablestyle{sep}{stretch}`, the fixed-width columns `x{}` `y{}` `z{}` `P{}` and the `tabularx` column `Y`, the `Light*` row-highlight colors, and `\figref` `\tabref` `\eqnref` `\algref` so one spelling per float type holds across the manuscript.

**Anonymity has two halves, and you want both.** The `anon` class option is the PDF half: the panel prints "Anonymous Authors" and drops affiliations, contribution notes, and the links row. `ANON=true` in `.env` is the source half: `lint.sh` then fails on identity anywhere under `manus/` — comments included, because comments ship with a source upload. The stock `main.tex` is anonymous by construction, placeholders included, so a fresh repo passes the source half on day one.

**Requirements** — a reasonably complete TeX Live (2022+): the class uses `tcolorbox`, `titlesec`, `cleveref`, `natbib`, `nicematrix`, and `siunitx`. `fontawesome5` is optional; without it the links row falls back to plain text labels.

## Quick start

### 1. Create the paper repo

Use this repository as a GitHub template, or clone/copy it — one paper, one repo:

```bash
git clone https://github.com/wanghao9610/STAGE
cd STAGE
rm -rf .git
cd ..
mv STAGE YOUR_PAPER_NAME
cd YOUR_PAPER_NAME
git init
git add .
git commit -m "First commit."
```

### 1b. Or adopt a paper repo that already exists

If a draft is already underway — a tex tree, months of commits, numbers already in the text — install the skeleton into it instead of moving it. Run at the root of that repository:

```bash
curl -fsSL https://raw.githubusercontent.com/wanghao9610/STAGE/main/execs/update.sh -o /tmp/stage-update.sh
bash /tmp/stage-update.sh --adopt
```

Nothing already there is overwritten: adoption copies only what is absent, then points you at `/stage-proj-adopt`, which interviews you about the paired STAR repo(s) and target venue, inventories the existing files, proposes how they map into the layout (confirming before touching anything), and records it all in `notes/adopt.md`. Numbers already sitting in the draft become `unsourced` claims — the audit backlog, not silent debt.

### 2. Configure `.env`

```bash
cp .env.example .env
```

```dotenv
# Paired STAR project repo (optional — leave empty when writing without one)
STAR_HOME=
# Build engine: pdflatex | xelatex | lualatex
LATEX_ENGINE=pdflatex
# Submission anonymity mode: when true, lint.sh hunts identity leaks
ANON=false
# Upstream STAGE repo used by execs/update.sh
STAGE_REPOSITORY=https://github.com/wanghao9610/STAGE.git
```

`STAR_HOME` decides which quick-start path you are on. The local `.env` is ignored by Git.

### 3. Path A: paired with a STAR repo

Point `STAR_HOME` at your STAR project and import:

```bash
bash execs/scpts/import.sh
```

The import snapshots the writing-relevant STAR artifacts — the method documents (`metds/overview.md`, `framework.md`, `dataset.md`, `training.md`, `evaluation.md`, plus `adopt.md` and `codearc.md`), idea statements, reference notes and `reference.bib`, results tables, and experiment digests — into `mates/<slug>/` under the same relative paths, and records each file in `mates/MANIFEST.md` with its source, source commit, and content fingerprint. When your manuscript has no bibliography yet, the STAR `reference.bib` is seeded into `manus/bibs/`. Re-run it after new experiments land; check for drift first with:

```bash
bash execs/scpts/import.sh --diff   # read-only staleness report; exit 1 when anything drifted
```

Several STAR repos can feed one paper: `import.sh --source PATH --slug NAME` imports any additional STAR-shaped checkout under its own slug.

### 4. Path B: standalone

Leave `STAR_HOME` empty. Drop evidence files — results exports, a collaborator's numbers, a wandb CSV — anywhere under `mates/manual/`, then run `/stage-evid-curator` to register each one in `mates/MANIFEST.md` as a `manual` entry whose source is stated in free text ("results emailed by X, 2026-08-01"). The curator also normalizes messy drops (a CSV becomes a results-shaped `.md` beside it, marked `normalized-from:`) and proposes claim⇄evidence mappings. Everything downstream — drafting, tables, audits — is identical: a registered manual drop is exactly as citable as an imported STAR file, and an unregistered file does not exist as far as the writing skills are concerned.

### 5. Build and lint

```bash
bash execs/run.sh          # latexmk, out-of-tree → wkdrs/builds/ + PDF path and page count
bash execs/scpts/lint.sh   # undefined refs, \todo count, page limit, anonymity leaks
```

A fresh checkout compiles out of the box with plain pdflatex, and the stock manuscript carries one deliberate `\todo{}` — so the first lint run visibly demonstrates the gate that will later hold your real missing numbers. `lint.sh` fails hard on undefined references, page-limit overruns, remaining `\todo` markers, and (when `ANON=true`) identity leaks; everything else is a warning.

### 6. Start the writing workflow

The skeleton stands on its own — the layout, `.env`, `run.sh`, and `import.sh` are useful with no skills installed. To pick up the workflow, start at whichever of these describes you:

| Where you are | Start with |
| --- | --- |
| Fresh repo, evidence just imported | `/stage-stry-coach` |
| A draft adopted in step 1b | `/stage-proj-adopt` |
| Story finalized, ready to skeleton | `/stage-outl-planner` |
| Returning to a paper under way | `/stage-flow-status` |

`/stage-flow-status` is the one to remember: it reads the outline, ledger, manifest, and cycle state on disk and names the single next action with its exact command, so you never have to recall where you left off.

## Writing workflow

STAGE includes fifteen complementary skills that turn imported evidence and a story into a submitted paper with an auditable claim trail.

**How to invoke them.** The prefix is tool-specific:

| Tool | Invocation | Example |
| --- | --- | --- |
| Claude Code | `/stage-<name>` | `/stage-sect-drafter 1_intro` |
| Codex | `$stage-<name>` | `$stage-sect-drafter 1_intro` |

Five skills (marked † below) are slash-only: they run only when you name them explicitly, and the agent never starts them on its own initiative. They are the dialogue-heavy decision points — adoption, story, outline, response, submission — where an unrequested run would make choices that are yours to make.

| Skill | Purpose | Main output |
| --- | --- | --- |
| `stage-proj-adopt` † | Wire a new or existing paper repo into STAGE: pair STAR repo(s) into `.env`, set the target venue, inventory and map an existing tex tree, and turn pre-existing draft numbers into `unsourced` claims for the audit backlog | `notes/adopt.md` |
| `stage-evid-curator` | Evidence intake and mapping: run `import.sh`, register hand-dropped files under `mates/manual/`, normalize messy exports, propose claim⇄evidence mappings, surface staleness — never edit evidence in place | `mates/` entries in `mates/MANIFEST.md` |
| `stage-stry-coach` † | Dialogue-first story shaping: pitch, problem, key idea, contributions with claim IDs, venue rationale; seeds the claim ledger and the user-confirmed venue profile | `notes/story.md`, seeded `notes/claims.md`, `cycls/<cycle>/venue.yml` |
| `stage-outl-planner` † | Story → skeleton: section table with page budgets that sum within the venue limit, figure and table plans, claim→section assignment, skeleton `.tex` files, notation seed | `notes/outline.md`, `manus/secs/*.tex` skeletons, `notes/notation.md` |
| `stage-sect-drafter` | Draft or revise one section per invocation from its brief, mapped evidence, claims, and the notation canon; numbers without a fingerprint become `\todo{}` | `manus/secs/<n>_<slug>.tex` |
| `stage-tabs-builder` | Generate tables from `mates/` evidence only — booktabs style, one `% src:` fingerprint comment per data row, `\todo` cells for missing data. Hand-typed numbers are the failure mode this skill exists to kill | `manus/tabs/<slug>.tex` |
| `stage-figs-designer` | Own the figure inventory and each figure end to end: purpose, editable source under `figs/srcs/`, rendered PDF; the teaser figure gets its own checklist | `manus/figs/<slug>.pdf` + sources |
| `stage-refs-curator` | Bibliography hygiene, reading-note intake for newly read papers, and related-work positioning; seeds from imported STAR refs when present | `manus/bibs/reference.bib`, `notes/refs/` |
| `stage-copy-editor` | Polish a section or the whole manuscript: clarity, flow, notation consistency, length trim — never changes technical meaning or any number | `wkdrs/reports/POLISH_<date>.md` |
| `stage-clms-auditor` | The mechanical heart: extract every number from the manuscript, trace each to a fingerprinted evidence entry, verdict matched / mismatched / unsourced, flip ledger statuses, check evidence staleness | `wkdrs/reports/CLAIMS_<date>.md` + `tasks/` items |
| `stage-cite-auditor` | Every `\cite` key resolves; every assertion about a cited work is checkable against a reading note — unverifiable assertions get flagged, never silently fixed | `wkdrs/reports/CITES_<date>.md` |
| `stage-peer-reviewer` | Simulated program committee: a five-perspective panel (novelty & related work, soundness, experimental rigor, clarity, devil's advocate) under a whitelist-or-verified citation contract, scored by anchored rubric bands with hard caps; `quick` runs a single-pass version; never edits the manuscript | `cycls/<cycle>/reviews/SIM_REVIEW_<date>.md` |
| `stage-resp-writer` † | Parse real and simulated reviews into a point ledger, map each attack to claims and evidence, draft the response within the venue's limit, record every promised change as a checkbox | `cycls/<cycle>/response/RESPONSE_<date>.md`, `tasks/<cycle>_promises.md` |
| `stage-subm-packer` † | Preflight and packaging: build + lint must pass, checklist walk, completeness sweep, camera/supp/arXiv package, submission record, freeze tag — camera-ready refuses to pack while promises sit unchecked | `cycls/<cycle>/SUBMISSION_<date>.md`, tag `freeze/<cycle>_<date>` |
| `stage-flow-status` | Read-only map of the whole flow: section/figure/table status, claim coverage by status, evidence freshness, cycle state, latest build — and the one next action with its exact command | Chat report; never writes |

## The ten-step path to a submission

The skills chain into one path from evidence to a frozen submission. Steps 5–7 loop per section; step 8 repeats cheaply as often as you like; `/stage-flow-status` reads across all of it at any point.

1. **Wire the repo** — `/stage-proj-adopt` (or just fill `.env` on a fresh clone): STAR pairing, target venue, inventory of anything already written → `notes/adopt.md`.
2. **Bring in evidence** — `bash execs/scpts/import.sh` for STAR sources, `/stage-evid-curator` for hand-dropped files: fingerprinted snapshots under `mates/`, one `MANIFEST.md` entry each.
3. **Shape the story** — `/stage-stry-coach`: the pitch, contributions, and venue rationale in `notes/story.md`; each contribution becomes a `proposed` claim in the ledger; the venue's page limits and deadlines land in `cycls/<cycle>/venue.yml` as user-confirmed facts.
4. **Skeleton the paper** — `/stage-outl-planner`: section table with page budgets, figure and table plans, claim→section assignment in `notes/outline.md`; skeleton `.tex` files appear under `manus/secs/` and their `\input` lines are uncommented in `main.tex`; `notes/notation.md` is seeded.
5. **Build the reference base** — `/stage-refs-curator`: reading notes with citable facts in `notes/refs/`, a clean `reference.bib`, related-work positioning.
6. **Draft** — `/stage-sect-drafter`, one section per run, from the brief, evidence, and claims; `/stage-tabs-builder` generates the tables from evidence; `/stage-figs-designer` takes each figure from source to rendered PDF. Ledger statuses flip to `drafted`.
7. **Polish** — `/stage-copy-editor`: clarity, flow, and notation consistency, with meaning and numbers untouchable.
8. **Audit** — `/stage-clms-auditor` traces every number to a fingerprint; `/stage-cite-auditor` checks every citation and assertion; each failure becomes a `tasks/` item and a ledger status, not a buried report line.
9. **Review and respond** — `/stage-peer-reviewer` convenes a five-perspective simulated panel (or a `quick` single pass) and writes its meta-review into `cycls/<cycle>/reviews/`; real reviews are dropped there as `received_<id>.md`; `/stage-resp-writer` turns them all into a point ledger, a response within the venue's limit, and promise checkboxes in `tasks/`.
10. **Pack and freeze** — `/stage-subm-packer`: build and lint must pass, checklist walked, package under `wkdrs/builds/`, `SUBMISSION_<date>.md` written, tag `freeze/<cycle>_<date>` created. Camera-ready mode refuses to pack while `tasks/<cycle>_promises.md` has unchecked boxes.

## Evidence, fingerprints, and the claim ledger

Three principles carry the whole design:

**A. Evidence flows one way.** STAR artifacts (or hand-registered drops) are snapshotted into read-only `mates/` and the manuscript only cites them. Numbers live upstream: to fix one, fix it in STAR and re-import — never edit `mates/`. Every evidence file has an entry in `mates/MANIFEST.md`:

```markdown
## xsam/wkdrs/results/results.md
- source-type: star
- source: $STAR_HOME/wkdrs/results/results.md
- source-commit: 3f2a91c
- source-stamp: updated: 2026-07-28
- imported: 2026-08-02
- covers: main COCO and LVIS results for Tables 1–2
```

The `source-stamp` is the fingerprint: the upstream file's own `generated:`/`updated:`/`finalized:` date. Staleness is detected by exact comparison against the current upstream value (`import.sh --diff`), never by file mtimes — so "the numbers changed under the paper" is a mechanical check, not a memory.

**B. The claim ledger is the hub.** `notes/claims.md` links every claim's statements ⇄ evidence ⇄ status:

```markdown
| ID | Claim | Type | Stated in | Evidence | Status |
|----|-------|------|-----------|----------|--------|
| C3 | +2.1 mask AP over X on LVIS | performance | `4_expts`, `tabs/main` | `mates/xsam/wkdrs/results/results.md#lvis` | verified |
```

Lifecycle: `proposed` (story) → `drafted` (stated in text) → `verified` (auditor matched evidence) / `unsourced` (stated with no fingerprint — must carry `\todo`) / `weakened` (conceded in a response) / `dropped`. The story seeds claims, the drafter states them, the auditor verifies them, the response defends them: the same rows, all the way to submission.

**C. Deterministic checks live in scripts, judgment lives in skills.** What a grep can catch — undefined references, `\todo` markers, page limits, anonymity leaks, stale stamps — is caught by `lint.sh` and `import.sh --diff` and can gate a submission. What needs judgment — is this claim actually supported, is this the right table to make the point — lives in the skills.

The fabrication boundary (conventions §9) closes the loop: every number in `manus/` either traces to a fingerprinted `mates/` entry or is written as `\todo{...}` — no third state; every assertion about a cited paper must be checkable against a reading note; venue rules are entered only as user-confirmed facts; and no skill may weaken these rules "to be helpful".

## Updating STAGE skills and workflow docs

After creating a paper from STAGE, sync later STAGE releases without touching the manuscript:

```bash
bash execs/update.sh
```

By default this updates `.claude/skills/`, `.agents/skills/`, and `docs/mds/stage-workflow/` from `STAGE_REPOSITORY`. The general form is `bash execs/update.sh [--diff] [ref] [--skill NAME] [--adopt]`:

- `--diff` previews without changing a file, and exits `1` when an update would change something — scriptable.
- A `ref` pins the update to a tag or branch.
- `--skill NAME` updates one skill across both trees.
- `--adopt` installs the skeleton into an existing repository, copying only what is absent (see [step 1b](#1b-or-adopt-a-paper-repo-that-already-exists)).

`docs/mds/stage-workflow/` is upstream-managed: do not edit it in an instance, `update.sh` overwrites it.

## Roadmap

Not in v1, planned next:

- **Remote git import sources** — `import.sh` fetching evidence straight from a git URL at a pinned ref, instead of requiring a local checkout.
- **`.cursor/`, `.codex/`, `.kimi-code/` trees** — STAR-parity skill mirrors for the remaining tools.
- **Per-skill assets** — venue rubrics, response templates, and question banks as `references/` beside the skills that use them.
- **Consistency CI** — a GitHub check keeping the `.claude`/`.agents` trees and the docs in step, as STAR does for its four mirrors.
- **Provenance hooks** — STAR-style model-id recording for every skill-written artifact.

## Citation

If you find STAGE useful in your research writing, please cite:

```bibtex
@misc{stage2026,
  title = {{STAGE}: Systematic Toolchain for Authoring, Guiding, and Editing},
  author = {Hao Wang},
  howpublished = {\url{https://github.com/wanghao9610/STAGE}},
  year = {2026}
}
```

## License

STAGE is released under the [MIT License](LICENSE).
