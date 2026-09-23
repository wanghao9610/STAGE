<div align="center">
  <img src="docs/srcs/stage-project-icon.png" alt="STAGE project icon" width="128">
  <h1>STAGE</h1>
  <p><strong>Systematic Toolchain for Authoring, Guiding, and Editing</strong></p>
  <p><em>The academic-writing companion to STAR — every STAR needs a STAGE.</em></p>
  <p><a href="https://wanghao9610.github.io/STAGE/"><strong>Documentation site</strong></a></p>
</div>

**Language:** English | [简体中文](README.zh-CN.md)

STAGE turns a research project into a submitted paper without losing the chain of custody along the way. It keeps the manuscript, imported experimental evidence, writing metadata, and submission cycles in predictable locations, gives researchers and AI writing agents one build entrypoint and one shared set of instructions, and runs a complete writing workflow — evidence import, story, outline, drafting, figures and tables, audits, simulated review, response, and submission packaging. Every number in the manuscript traces to a fingerprinted evidence file or is visibly marked as missing; every claim is tracked from proposal to verification in a single ledger.

STAGE is the writing-side companion to [STAR](https://github.com/wanghao9610/STAR) (*Systematic Toolchain for AI Research*, [documentation site](https://wanghao9610.github.io/STAR/)): STAR runs the research and produces the method documents, results, and digests; STAGE snapshots them as read-only evidence and writes the paper on top. The pairing is optional — STAGE also works standalone, with evidence registered by hand.

STAGE is double-layered: this repository is the **template**; one paper = one **instance**, created by cloning the template or by installing its skeleton into an existing paper repo with `execs/update.sh --adopt`. Instances later sync STAGE-managed skills and workflow docs from upstream via `update.sh`, without touching the manuscript.

## Contents

- [Contents](#contents)
- [STAR · STAGE · STORY](#star--stage--story)
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
- [Project memory](#project-memory)
- [Updating STAGE skills and workflow docs](#updating-stage-skills-and-workflow-docs)
- [Project conventions](#project-conventions)
- [Adapting STAGE to a new paper](#adapting-stage-to-a-new-paper)
- [Citation](#citation)
- [License](#license)

## STAR · STAGE · STORY

The three projects cover successive scales of a researcher's work. Use any one independently, or connect them through fingerprinted evidence.

| Project | Scope | Links |
| --- | --- | --- |
| **STAR** — Systematic Toolchain for AI Research | Runs one research project from idea through reproducible experiments and paper-ready evidence. | [Website](https://wanghao9610.github.io/STAR/) · [GitHub](https://github.com/wanghao9610/STAR) |
| **STAGE** — Systematic Toolchain for Authoring, Guiding, and Editing | Turns one research contribution into a traceable paper, review cycle, and submission package. | **Current project** · [Website](https://wanghao9610.github.io/STAGE/) · [GitHub](https://github.com/wanghao9610/STAGE) |
| **STORY** — Systematic Toolchain for Organizing Research over Years | Shapes graduate research into a defensible master's thesis or doctoral dissertation, defense, and deposit. | [Website](https://wanghao9610.github.io/STORY/) · [GitHub](https://github.com/wanghao9610/STORY) |

## What STAGE provides

- **A consistent manuscript layout**: sections, figures with their sources, tables, bibliography, and venue styles each in one place under `manus/`.
- **A read-only evidence layer**: STAR artifacts (or hand-registered drops) are snapshotted into `mates/` with a fingerprint per file, recorded in `mates/MANIFEST.md`. Evidence flows one way — to fix a number, fix it upstream and re-import; `mates/` is never edited in place.
- **A claim ledger as the hub**: `notes/claims.md` links every claim's statements ⇄ evidence ⇄ status. Writing states claims, audits verify them, responses defend them.
- **One build entrypoint**: `execs/run.sh` compiles `manus/main.tex` with latexmk, out-of-tree into `wkdrs/builds/`, and prints the PDF path and page count.
- **Deterministic checks in scripts, judgment in skills**: `execs/scpts/lint.sh` catches undefined references, `\todo` markers, page-limit overruns, and anonymity leaks mechanically. It also raises advisory warnings for high-confidence chatbot residue and clustered formulaic prose; those warnings request human review and never classify authorship or block a submission by themselves.
- **A complete writing lifecycle** through sixteen complementary skills, in the order they run: wire the repo, curate evidence, shape the story, outline the paper, draft each section, build tables from evidence, design figures, curate references, polish the prose, audit every number, audit every citation, simulate review, write the response, pack the submission, build the poster, and report status.
- **Submission cycles as data**: each venue attempt lives in `cycls/<venue>_<year>/` with a user-confirmed `venue.yml` profile, received and simulated reviews, the response, and a frozen submission record.
- **One workflow, seven harnesses**: the same sixteen skills for Claude Code, Codex, Cursor, DSH, Kimi Code, Pi, and Qwen Code. Tool-neutral skill files live once under `.agents/skills/`, and the full `/stage` request router lives once under `.agents/commands/`; native trees link or delegate there and retain only harness-specific wording and argument adapters.
- **A memory the paper owns**: what a session learns that no file in the repository holds — a TeX toolchain quirk, a standing preference of yours, a framing already tried and rejected — is recorded under `.stage/memory/` and put in front of the next session by a hook, in whichever tool you drive STAGE with.
- **zh-CN mirrors for human readers**: `SKILL_zh.md` beside every `SKILL.md`, `*_zh.md` beside the peer-reviewer references, `stage.zh-CN.md` beside the shared request router, and `*.zh-CN.md` beside the workflow docs — kept in step, never loaded at runtime, and the English files stay authoritative.

See [Writing workflow](#writing-workflow) for what each skill does and how to invoke it. The [Writing Workflow Skills Guide](docs/mds/stage-workflow/writing-workflow-skills.md) adds a paragraph per skill and the pipeline diagram; the rules every skill shares are in the [Writing Workflow Conventions](docs/mds/stage-workflow/writing-workflow-conventions.md), with the evidence-preserving prose pass in the [Human Writing Guide](docs/mds/stage-workflow/human-writing-guide.md).

## Project structure

```text
STAGE/
├── manus/                  # The manuscript
│   ├── main.tex            # Entry point; compiles standalone out of the box
│   ├── secs/               # Section sources: <n>_<slug>.tex (0_abstract.tex, 1_intro.tex, …)
│   ├── figs/               # Rendered figures (PDF); figs/srcs/ holds every figure's source
│   ├── tabs/               # Tables, generated from evidence
│   ├── bibs/               # reference.bib
│   └── stys/               # stage.cls (the look) + stage.sty (\todo and authoring macros)
├── mates/                  # Imported evidence — read-only
│   ├── <source-slug>/      # Snapshots mirroring upstream STAR paths
│   ├── manual/             # Hand-registered evidence drops
│   └── MANIFEST.md         # The fingerprint ledger: one entry per evidence file
├── notes/                  # Writing metadata
│   ├── story.md            # Also: claims.md, outline.md, notation.md, style.md, adopt.md
│   └── refs/               # Reading notes per paper + refs_index.md
├── cycls/                  # Submission cycles
│   └── <venue>_<year>/     # venue.yml, template/ (the venue kit), reviews/, response/, SUBMISSION_<date>.md
├── tasks/                  # Revision scratch and promise lists
├── wkdrs/                  # Builds and ephemeral reports (gitignored, regenerable)
├── execs/
│   ├── run.sh              # Build entrypoint (latexmk, out-of-tree)
│   ├── update.sh           # Sync upstream STAGE skills and docs; --adopt installs the skeleton
│   └── scpts/              # import.sh (evidence import), lint.sh (deterministic checks), fmt.sh (one sentence per line)
├── docs/                   # Project documentation
│   ├── index.html          # Documentation entrypoint for GitHub Pages (→ htmls/stage.html)
│   ├── htmls/              # The landing pages: stage.html + stage_zh.html
│   ├── mds/stage-workflow/ # Conventions + skills guide (upstream-managed)
│   └── srcs/               # Documentation images and other static assets
├── .stage/memory/          # Project memory: what earlier sessions learned (local/ is git-ignored)
├── .claude/
│   ├── skills/             # Writing workflow skills for Claude Code
│   ├── hooks/              # Hooks: project-memory index, session model id, involve gate, commit guard
│   └── settings.json       # Registers all four hooks
├── .agents/
│   ├── skills/             # Tool-neutral shared skill store; the only target of skill links
│   ├── commands/           # Shared /stage router and its zh-CN reading edition
│   └── plugins/            # Codex marketplace discovery: one file link into .codex/plugins/
├── .codex/                 # Codex hooks, per-skill manifests, and the $stage router plugin
├── .cursor/
│   ├── skills/             # Writing workflow skills for Cursor
│   ├── rules/              # Always-on rules: AGENTS.md body + skill-root ownership
│   ├── hooks/              # Hooks, registered in hooks.json
│   └── hooks.json
├── .dsh/                   # DSH-native skills, hooks, and the /stage command bundle
├── .kimi-code/
│   ├── skills/             # Writing workflow skills for Kimi Code
│   ├── plugins/            # User-installed /stage router plugin and marketplace
│   ├── hooks/              # Hooks + install.sh (Kimi registers globally)
│   └── hooks.example.toml  # The registration snippet install.sh writes for you
├── .pi/                    # Pi-native skills, prompts, agents, and capability extensions
├── .qwen/                  # Qwen-native skills, commands, hooks, and settings
├── .cursorignore           # Keeps builds and LaTeX junk out of Cursor's index
├── .env.example            # Local configuration example
├── AGENTS.md               # Shared instructions for AI writing agents (+ AGENTS.zh-CN.md)
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
| `stys/` | Styles | `stage.cls` and `stage.sty` — venue kits live in `cycls/<cycle>/template/`, not here |
| `mates/` | Materials | Imported evidence snapshots — read-only |
| `cycls/` | Cycles | One directory per submission attempt |
| `execs/` | Executions | Entrypoint scripts; `scpts/` the utilities |
| `wkdrs/` | Work directories | Builds and ephemeral reports, never committed |
| `mds/` | Markdowns | Markdown documentation, grouped by topic |
| `srcs/` | Static sources | Images and other static assets the docs embed |

Three rules the tree alone does not carry: `mates/` is read-only (`import.sh` and `/stage-evid-curator` are the only writers, adding or replacing whole files with fingerprints); `wkdrs/` is never committed (durable audit outcomes live as status flips in `notes/claims.md` and entries in `tasks/`, not in reports); and the `execs/` root is closed (`run.sh` + `update.sh` and nothing else — utilities go in `execs/scpts/`).

## Manuscript template

`manus/` ships a compact, arXiv-style preprint template, split into three files by what a venue swap does to each — two of them are the thing being swapped, and one has to survive it:

| Layer | File | Owns | In the venue's format |
| --- | --- | --- | --- |
| The look | `manus/stys/stage.cls` | page geometry, fonts, the title panel, headings, captions, floats, the citation package | **replaced** by the venue's own class |
| The reference list | `manus/stys/stage.bst` | how an entry is typeset: sorted by author, numbered `[3]`, and no DOI, URL, ISBN, or ISSN printed | **replaced** by the kit's own `.bst` |
| The authoring layer | `manus/stys/stage.sty` | `\todo{...}` plus the macros the writing skills emit into `secs/` and `tabs/` | **carried over verbatim** — the line `\usepackage{stys/stage}` stays whatever the class becomes |

`stage.bst` is `plainnat` with four fields silenced, which is the arrangement CVPR's own style makes: a DOI or URL stays in `reference.bib`, where it is the entry's provenance and what `/stage-refs-curator` re-fetches from, and is simply not typeset — so the reference list reads like a conference paper's rather than like a database export.

Keep that split when you extend the class or the package: anything a section or table file writes belongs in the package; anything only the page look needs belongs in the class. Project-specific macros (`\newcommand{\method}{...}`) go in `main.tex`, never in `stys/` — all three template files get replaced or updated under you.

**Getting into a conference template.** You do not swap the class in place. `manus/main.tex` always compiles as the preprint; the venue's format is a **generated copy**:

1. Download the venue's official author kit (CVPR, NeurIPS, ACL, an IEEE journal — whatever it ships as).
2. `/stage-subm-packer convert kit=<path-to-zip-or-dir>` — the kit unpacks whole and unedited into `cycls/<cycle>/template/`, beside that cycle's `venue.yml`. It stays out of `manus/` deliberately: that tree is scanned by `lint.sh`, and a kit's own example `.tex` would trip the `\todo` count and the identity-leak scan. `template:` in `venue.yml` names the class inside the kit.
3. The run reads the kit's own example `.tex` for the macros it wants, writes a standalone copy under `wkdrs/` — the venue's class, `stage.sty` verbatim, a small generated `compat.sty` for what `stage.cls` provided and the venue class does not, a `main.tex` re-emitting your title/authors/abstract through the venue's macros, and `secs/`, `tabs/`, `figs/`, `bibs/` unchanged — then builds it and reports the page count **in that format**, which is the number `page_limit_main` actually means.

`manus/` is never edited, the copy is regenerated from scratch every run, and the template is never fetched or written from memory: an official kit is the only source. Whatever the conversion cannot do for you lands as a `- [ ]` line in `tasks/<cycle>_venue.md`, naming the skill that fixes it — a tracked list rather than a note in a chat window. Re-run `convert` as often as you like while trimming to the page limit — it skips every freeze gate, so it works on a manuscript that still has `\todo` markers in it.

**Class options** — `\documentclass[twocolumn]{stys/stage}`: `onecolumn` | `twocolumn`, plus `anon` and anything `article` takes. Inside the preamble, `\paperstyle{fancy|simple}` picks a framed or flat title panel and `\papercolor{green|blue|black}` sets the theme.

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
# Harness trees kept current: comma-separated names | all | none
STAGE_HARNESSES=
# Optional. How much the skills ask before deciding: low | medium | high
INVOLVE=medium
# Optional. Reply and document language: en | zh; empty = follow the conversation
STAGE_LANG=
```

`STAR_HOME` decides which quick-start path you are on. The local `.env` is ignored by Git.

`INVOLVE` (optional, `low` | `medium` | `high`) sets how much the skills ask before they decide. At `low` a skill takes the recommended option on judgment calls and logs that it did, commits what its run wrote without asking and names each commit in its reply, and — in Claude Code, Codex, and Qwen Code — the permission prompt before each file edit is skipped; `medium` (the default) asks as documented; `high` confirms item by item. Hard gates are asked at every level: the STOP line, deletions and overwrites, and every `venue.yml` value entering as confirmed. To change the level for one run, add the same token when you call a skill: `/stage-sect-drafter 3_method involve=low`. Full rule: [conventions §7.7](docs/mds/stage-workflow/writing-workflow-conventions.md).

`STAGE_LANG` (optional, `en` | `zh`) sets the language of chat replies and of the Markdown the workflow writes — `notes/`, `tasks/`, simulated reviews, `wkdrs/` reports. Left empty, everything follows the conversation's own language. Two things stay English whatever it says, because people outside the repository read them: the manuscript under `manus/`, and the response to reviewers. So do structural literals in any document — frontmatter keys, ledger statuses, IDs, paths, bibkeys, venue and metric names — which is what keeps a Chinese note machine-readable. Full rule: [conventions §7.6](docs/mds/stage-workflow/writing-workflow-conventions.md).

### 3. Path A: paired with a STAR repo

Point `STAR_HOME` at your STAR project and import:

```bash
bash execs/scpts/import.sh
```

The import snapshots the writing-relevant STAR artifacts — the method documents (`metds/overview.md`, `framework.md`, `dataset.md`, `training.md`, `evaluation.md`, plus `adopt.md` and `codearc.md`), idea statements, reference notes and `reference.bib`, results tables, and experiment digests — into `mates/<slug>/` under the same relative paths, and records each file in `mates/MANIFEST.md` with its source, source commit, and content fingerprint. When your manuscript has no bibliography yet, the STAR `reference.bib` is seeded into `manus/bibs/`. Re-run it after new experiments land; check for drift first with:

```bash
bash execs/scpts/import.sh --diff   # read-only staleness report; exit 2 when anything drifted, 1 on a hard error
```

Several STAR repos can feed one paper: `import.sh --source PATH --slug NAME` imports any additional STAR-shaped checkout under its own slug.

### 4. Path B: standalone

Leave `STAR_HOME` empty. Drop evidence files — results exports, a collaborator's numbers, a wandb CSV — anywhere under `mates/manual/`, then run `/stage-evid-curator` to register each one in `mates/MANIFEST.md` as a `manual` entry whose source is stated in free text ("results emailed by X, 2026-08-01"). The curator also normalizes messy drops (a CSV becomes a results-shaped `.md` beside it, marked `normalized-from:`) and proposes claim⇄evidence mappings. Everything downstream — drafting, tables, audits — is identical: a registered manual drop is exactly as citable as an imported STAR file, and an unregistered file does not exist as far as the writing skills are concerned.

### 5. Build and lint

```bash
bash execs/run.sh          # latexmk, out-of-tree → wkdrs/builds/ + PDF path and page count
bash execs/scpts/lint.sh   # hard gates + advisory clustered-prose review
bash execs/scpts/fmt.sh    # one sentence per line; --check reports drift and writes nothing
```

A fresh checkout compiles out of the box with plain pdflatex, and the stock manuscript carries one deliberate `\todo{}` — so the first lint run visibly demonstrates the gate that will later hold your real missing numbers. `lint.sh` fails hard on undefined references, page-limit overruns, remaining `\todo` markers, and (when `ANON=true`) identity leaks; everything else is a warning. One of those warnings is `fmt.sh --check`: LaTeX reads a newline as a space, so the manuscript is kept at one sentence per line — a diff that shows the sentence you changed rather than the paragraph it sits in, and a `% src:` comment always one line above the sentence it sources.

### 6. Start the writing workflow

The skeleton stands on its own — the layout, `.env`, `run.sh`, and `import.sh` are useful with no skills installed. To pick up the workflow, start at whichever of these describes you:

| Where you are | Start with |
| --- | --- |
| Fresh repo, evidence just imported | `/stage-stry-coach` |
| A draft adopted in step 1b | `/stage-proj-adopt` |
| Story finalized, ready to skeleton | `/stage-outl-planner` |
| Returning to a paper under way | `/stage-flow-status` |

`/stage-flow-status` is the one to remember: it reads the outline, ledger, manifest, and cycle state on disk and names the single next action with its exact command, so you never have to recall where you left off.

**Two session hooks.** One supplies the [project memory](#project-memory) index; the other states the runtime's model id so artifacts record `model_id` and `model_trail` (workflow conventions §8). Claude, Codex, Cursor, Pi, and Qwen register them from the project. Kimi and DSH need their one-time installers (`.kimi-code/hooks/install.sh`, `.dsh/hooks/install.sh`) because those harnesses keep hook registration outside the repository. Codex project hooks still require approval through `/hooks`.

**Two more hooks decide rather than inject.** Claude, Codex, and Qwen carry the `INVOLVE=low` edit-permission gate. Every harness carries `stage_commit_guard.sh`, which declines the git commands [conventions §1](docs/mds/stage-workflow/writing-workflow-conventions.md) forbids. Pi registers it in its project extension; DSH and Kimi use their hook bridges.

## Writing workflow

STAGE includes sixteen complementary skills that turn imported evidence and a story into a submitted paper with an auditable claim trail.

**How to invoke them.** The prefix is tool-specific:

| Tool | Invocation | Example |
| --- | --- | --- |
| Claude Code | `/stage-<name>` | `/stage-sect-drafter 1_intro` |
| Codex | `$stage-<name>` | `$stage-sect-drafter 1_intro` |
| Cursor | `/stage-<name>` | `/stage-sect-drafter 1_intro` |
| DSH | `/skill:stage-<name>` | `/skill:stage-sect-drafter 1_intro` |
| Kimi Code | `/skill:stage-<name>` | `/skill:stage-sect-drafter 1_intro` |
| Pi | `/stage-<name>` | `/stage-sect-drafter 1_intro` |
| Qwen Code | `/stage-<name>` | `/stage-sect-drafter 1_intro` |

Claude Code, Cursor, Pi, and Qwen Code expose `/stage [what you want to do]` directly from project files. The command sends the request through `.agents/commands/stage.md`; an empty request selects `stage-flow-status`, and a match to one of the six explicit-only skills returns the exact `/stage-<name> <argument>` command and waits.

Codex packages the shared router as the repo-local `stage` plugin. Register and install it once from the repository root, then start a new session:

```bash
codex plugin marketplace add .
codex plugin add stage@stage
```

Use `$stage` with no argument for the current paper status, or pass a request such as `$stage audit every number in the experiments section`. The plugin reads the same `.agents/commands/stage.md` roster as the other harnesses' `/stage` wrappers; it adds no second copy of that routing table.

Kimi Code packages the same router as a user-installed plugin under `.kimi-code/plugins/stage/`. Start Kimi Code from the repository root and run these commands in its prompt; `/new` may replace `/reload`:

```text
/plugins install ./.kimi-code/plugins/stage
/reload
```

Use `/stage` with no argument for the current paper status, or pass a described task; `/skill:stage` is the explicit spelling of the same external skill. Kimi copies a local plugin into its user-level managed directory, so repeat the install command after STAGE updates this plugin.

DSH packages the same router under `.dsh/commands/stage/`; installation requires `pnpm` on `PATH`. From the repository root, install it once into every profile that will run STAGE, inspect the composed configuration, then restart that profile:

```bash
dsh plugin --profile YOUR_PROFILE add ./.dsh/commands/stage
dsh --profile YOUR_PROFILE --dump-config
```

Use `/stage` with no argument for the current paper status, or pass a request such as `/stage audit every number in the experiments section`. The command starts one follow-up turn against the shared `.agents/commands/stage.md` roster, so DSH and the other harnesses route from the same source.

Six skills (marked † below) are slash-only: adoption, story, outline, response, submission, and poster selection. Named harness manifests use `disable-model-invocation: true`; Codex uses `allow_implicit_invocation: false` in `.codex/skills/`, linked into the shared root. CI checks all seven against [conventions §11](docs/mds/stage-workflow/writing-workflow-conventions.md).

<div align="center">
  <img src="docs/srcs/stage-writing-workflow.png" alt="STAGE writing workflow: sixteen skills in five phase bands — set up, plan, write, polish and audit, submission cycle — what each one writes, and how the drafting loop and the rejection loop close" width="100%">
</div>

| Skill | Purpose | Main output |
| --- | --- | --- |
| `stage-proj-adopt` † | Wire a new or existing paper repo into STAGE: pair STAR repo(s) into `.env`, set the target venue, inventory and map an existing tex tree, and turn pre-existing draft numbers into `unsourced` claims for the audit backlog | `notes/adopt.md` |
| `stage-evid-curator` | Evidence intake and mapping: run `import.sh`, register hand-dropped files under `mates/manual/`, normalize messy exports, propose claim⇄evidence mappings, surface staleness — never edit evidence in place | `mates/<slug>/**`, `mates/manual/**`, entries in `mates/MANIFEST.md` |
| `stage-stry-coach` † | Dialogue-first story shaping: pitch, problem, key idea, contributions with claim IDs, venue rationale; seeds the claim ledger and the user-confirmed venue profile | `notes/story.md`, seeded `notes/claims.md`, `cycls/<cycle>/venue.yml` |
| `stage-outl-planner` † | Story → skeleton: section table with page budgets that sum within the venue limit, figure and table plans, claim→section assignment, skeleton `.tex` files, notation seed | `notes/outline.md`, `manus/secs/*.tex` skeletons, `notes/notation.md` |
| `stage-sect-drafter` | Draft or revise one section per invocation from its brief, mapped evidence, claims, and the notation canon; numbers without a fingerprint become `\todo{}` | `manus/secs/<n>_<slug>.tex` |
| `stage-tabs-builder` | Generate tables from `mates/` evidence only — booktabs style, one `% src:` fingerprint comment per data row, `\todo` cells for missing data. Hand-typed numbers are the failure mode this skill exists to kill | `manus/tabs/<slug>.tex` |
| `stage-figs-designer` | Own the figure inventory and each figure end to end: purpose, editable source under `figs/srcs/`, rendered PDF; the teaser figure gets its own checklist | `manus/figs/<slug>.pdf` + sources |
| `stage-refs-curator` | Bibliography hygiene, reading-note intake for newly read papers, and related-work positioning; seeds from imported STAR refs when present, and `discover` searches by topic and proposes candidates when there are none | `manus/bibs/reference.bib`, `notes/refs/<ABBREV>.md`, `notes/refs/refs_index.md` |
| `stage-copy-editor` | Polish a section or the whole manuscript: clarity, flow, natural scholarly prose, notation consistency, length trim — paragraph-level rewrites preserve technical meaning, numbers, citations, attribution, and claim strength; `style` mode instead records the author's prose dials | edited prose in `manus/`, `wkdrs/reports/POLISH_<date>.md`, `notes/style.md` |
| `stage-clms-auditor` | The mechanical heart: extract every number from the manuscript, trace each to a fingerprinted evidence entry, verdict matched / mismatched / unsourced, flip ledger statuses, check evidence staleness | `notes/claims.md` status flips, `wkdrs/reports/CLAIMS_<date>.md`, `tasks/` items |
| `stage-cite-auditor` | Every `\cite` key resolves; every assertion about a cited work is checkable against a reading note — unverifiable assertions get flagged, never silently fixed | `wkdrs/reports/CITES_<date>.md`, `tasks/` items |
| `stage-peer-reviewer` | Simulated program committee: a five-perspective panel (novelty & related work, soundness, experimental rigor, clarity, devil's advocate) under a whitelist-or-verified citation contract, scored by anchored rubric bands with hard caps; `quick` runs a single-pass version; never edits the manuscript | `cycls/<cycle>/reviews/SIM_REVIEW_<date>.md` |
| `stage-resp-writer` † | Parse real and simulated reviews into a point ledger, map each attack to claims and evidence, draft the response within the venue's limit, record every promised change as a checkbox | `cycls/<cycle>/response/RESPONSE_<date>.md`, `tasks/<cycle>_promises.md`, `weakened` downgrades in `notes/claims.md` |
| `stage-subm-packer` † | Preflight and packaging: build + lint must pass, checklist walk, completeness sweep, conversion into the venue's own template from an official kit, package, submission record, freeze tag — camera-ready refuses to pack while promises sit unchecked | `cycls/<cycle>/SUBMISSION_<date>.md`, tag `freeze/<cycle>_<date>`, the kit at `cycls/<cycle>/template/`, venue follow-ups in `tasks/<cycle>_venue.md` |
| `stage-pstr-builder` † | The accepted paper as one sheet: a takeaway sentence, the claims the ledger carries at `verified`, figures reused from `manus/figs/` unmodified — with a legibility gate computed at print scale and no `\todo` allowed onto a wall | `cycls/<cycle>/poster/POSTER_PLAN.md` + `poster.tex`, render under `wkdrs/builds/poster/` |
| `stage-flow-status` | Read-only map of the whole flow: section/figure/table status, claim coverage by status, evidence freshness, cycle state, latest build — and the one next action with its exact command | Chat report; never writes |

**Targeting more than one venue.** One venue is one cycle. `cycls/<venue>_<year>/` owns that attempt's `venue.yml`, its official kit under `template/`, its reviews, its response, its `SUBMISSION_<date>.md`, and its freeze tag; the manuscript, the evidence, and the claim ledger are shared across all attempts.

- **In sequence** — rejected, then resubmitted elsewhere — is the native path. `/stage-stry-coach` creates the next cycle with that venue's confirmed profile, and `/stage-subm-packer convert kit=<path>` registers the new kit into it. Nothing in the old cycle moves, so which format went where stays reproducible from its freeze tag, and the `weakened` and `unsourced` claims in the shared ledger are the first things the next attempt fixes.
- **In parallel** — a CVPR copy and a NeurIPS copy at once, or just comparing page counts — works the same way, one cycle per venue: point `cycle:` in `notes/story.md` at the one you want, then convert. Copies land in `wkdrs/builds/<cycle>_<template>_<date>/`, named by cycle and template, so they never overwrite each other.
- **Two kits in one cycle** is not supported, deliberately. `cycls/<cycle>/template/` is singular and `venue.yml`'s `template:` names one class inside it; replacing a kit under a live cycle shows you the diff and asks first, because it changes the page budget every earlier decision was made against.

Two things to know when venues run in parallel. `notes/outline.md` carries one set of page budgets, so it can only be planned against one venue's limit — for the other, the page count `convert` reports is the check, which is exactly why conversion skips every gate and can be re-run at will. And `.env`'s `ANON` is one global flag while `anonymized:` is per cycle, so flip it when you switch; forgetting does not produce a wrongly formatted package, the run stops and names the line to change.

## The ten-step path to a submission

The skills chain into one path from evidence to a frozen submission. Steps 5–7 loop per section; step 8 repeats cheaply as often as you like; `/stage-flow-status` reads across all of it at any point.

1. **Wire the repo** — `/stage-proj-adopt` (or just fill `.env` on a fresh clone): STAR pairing, target venue, inventory of anything already written → `notes/adopt.md`.
2. **Bring in evidence** — `bash execs/scpts/import.sh` for STAR sources, `/stage-evid-curator` for hand-dropped files: fingerprinted snapshots under `mates/`, one `MANIFEST.md` entry each.
3. **Shape the story** — `/stage-stry-coach`: the pitch, contributions, and venue rationale in `notes/story.md`; each contribution becomes a `proposed` claim in the ledger; the venue's page limits and deadlines land in `cycls/<cycle>/venue.yml` as user-confirmed facts.
4. **Skeleton the paper** — `/stage-outl-planner`: section table with page budgets, figure and table plans, claim→section assignment in `notes/outline.md`; skeleton `.tex` files appear under `manus/secs/` and their `\input` lines are uncommented in `main.tex`; `notes/notation.md` is seeded.
5. **Build the reference base** — `/stage-refs-curator`: reading notes with citable facts in `notes/refs/`, a clean `reference.bib`, related-work positioning.
6. **Draft** — `/stage-sect-drafter`, one section per run, from the brief, evidence, and claims; `/stage-tabs-builder` generates the tables from evidence; `/stage-figs-designer` takes each figure from source to rendered PDF. Ledger statuses flip to `drafted`.
7. **Polish** — `/stage-copy-editor`: clarity, flow, natural scholarly prose, and notation consistency, with meaning, evidence, numbers, citations, and attribution untouchable. It diagnoses pattern clusters and rewrites at paragraph scale instead of replacing forbidden words. `/stage-copy-editor style` records the paper's writing style as measurable dials in `notes/style.md` first, if you want one.
8. **Audit** — `/stage-clms-auditor` traces every number to a fingerprint; `/stage-cite-auditor` checks every citation and assertion; each failure becomes a `tasks/` item and a ledger status, not a buried report line.
9. **Review and respond** — `/stage-peer-reviewer` convenes a five-perspective simulated panel (or a `quick` single pass) and writes its meta-review into `cycls/<cycle>/reviews/`; real reviews are dropped there as `received_<id>.md`; `/stage-resp-writer` turns them all into a point ledger, a response within the venue's limit, and promise checkboxes in `tasks/`.
10. **Pack and freeze** — `/stage-subm-packer`: build and lint must pass, checklist walked, the paper converted into the venue's own template from the registered kit, package under `wkdrs/builds/`, `SUBMISSION_<date>.md` written, tag `freeze/<cycle>_<date>` created. Camera-ready mode refuses to pack while `tasks/<cycle>_promises.md` has unchecked boxes. Run `/stage-subm-packer convert kit=<path>` first, and as often as you need — conversion alone skips every freeze gate, so it works while the paper is still being trimmed to the page limit.
11. **Poster** — `/stage-pstr-builder`, after acceptance: `plan` picks the one takeaway and the `verified` claims that earn wall space and records what was cut; `render` emits `cycls/<cycle>/poster/poster.tex` and compiles it; the gate checks effective point size against the sheet's confirmed physical size and refuses a `\todo`. Figures come from `manus/figs/` unmodified — new artwork routes back to `/stage-figs-designer`.


## Evidence, fingerprints, and the claim ledger

Three principles carry the whole design:

**A. Evidence flows one way.** STAR artifacts (or hand-registered drops) are snapshotted into read-only `mates/` and the manuscript only cites them. Numbers live upstream: to fix one, fix it in STAR and re-import — never edit `mates/`. Every evidence file has an entry in `mates/MANIFEST.md`:

```markdown
## proj/wkdrs/results/results.md
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
| C3 | +2.1 mask AP over X on LVIS | performance | `4_expts`, `tabs/main` | `mates/proj/wkdrs/results/results.md#lvis` | verified |
```

Lifecycle: `proposed` (story) → `drafted` (stated in text) → `verified` (auditor matched evidence) / `unsourced` (stated with no fingerprint — must carry `\todo`) / `weakened` (conceded in a response) / `dropped`. The story seeds claims, the drafter states them, the auditor verifies them, the response defends them: the same rows, all the way to submission.

**C. Deterministic checks live in scripts, judgment lives in skills.** What a grep can catch — undefined references, `\todo` markers, page limits, anonymity leaks, stale stamps — is caught by `lint.sh` and `import.sh --diff` and can gate a submission. The prose-pattern scan is the explicit exception in force, not implementation: it deterministically locates high-confidence residue or clustered signals, but its warnings are advisory and require human judgment. What needs judgment — is this claim actually supported, is this the right table to make the point, does a paragraph sound formulaic in context — lives in the skills.

The fabrication boundary (conventions §9) closes the loop: every number in `manus/` either traces to a fingerprinted `mates/` entry or is written as `\todo{...}` — no third state; every assertion about a cited paper must be checkable against a reading note; venue rules are entered only as user-confirmed facts; and no skill may weaken these rules "to be helpful".

## Project memory

What a session learns that no file in the repository owns — a build that only works under one engine on this machine, a standing preference of yours, a framing the simulated panel already rejected — is recorded in the paper at `.stage/memory/`, not in whichever tool you happened to be driving. One file per fact, one line per fact in `.stage/memory/MEMORY.md`, and a session hook puts that index in front of the agent in every supported harness.

Four kinds: `env` (a machine or TeX-toolchain fact, usually learned by failing), `pref` (how you want the writing done), `insight` (a judgment that outlived the run that produced it), and `deadend` (tried, rejected, not worth retrying — the one a paper needs most between cycles). Two rules keep the store from becoming a second, drifting copy of the repository:

- **A fact is recorded there only when no file already owns it.** A number belongs to a fingerprinted `mates/` entry, a claim to `notes/claims.md`, a page limit to the cycle's `venue.yml`, what a paper says to `notes/refs/`, a promise to `tasks/`. Memory holds the residue.
- **A memory is never a source.** It can never back a number in `manus/`, a venue rule, or an assertion about a cited work — the fabrication boundary does not soften because a memory recalls the value. Where a memory disagrees with a file in the repository, the file wins.

Facts that hold only on this machine go to `.stage/memory/local/`, which git ignores the way it ignores `.env`; an `env` entry whose last confirmation is over 180 days old is flagged stale where the session sees it, since a machine changes under a fact recorded about it. Nothing is recorded without your say-so: the agent offers, you decide — and `INVOLVE=low` in `.env` turns that into record-and-tell. The file format, the index line the hooks parse, and how a memory is retired are in [Project Memory](docs/mds/stage-workflow/memory_spec.md).

## Updating STAGE skills and workflow docs

After creating a paper from STAGE, you can sync later STAGE skill and writing workflow doc releases without touching the manuscript, the evidence, the notes, or Git remotes:

```bash
bash execs/update.sh
```

By default, the command updates these paths from STAGE's `main` branch:

- `AGENTS.md` always, and `.cursor/rules/` when Cursor is selected — the shared agent instructions and Cursor's mirrored runtime copy; your own edits to selected paths are replaced, and a run that includes Cursor moves the runtime copies together
- `.agents/skills/` and `.agents/commands/` first, then `.claude/skills/`, `.cursor/skills/`, `.dsh/skills/`, `.kimi-code/skills/`, `.pi/skills/`, and `.qwen/skills/` — the shared store and router plus every native harness copy; links are dereferenced when installed into a paper instance
- `.codex/plugins/` — the Codex-only `$stage` router plugin and canonical marketplace; `.agents/plugins/marketplace.json` is only a file link to that marketplace, never a link over the directory
- `.dsh/commands/` and `.kimi-code/plugins/` — the DSH and Kimi `/stage` router packages, updated only when their respective harness is selected
- the corresponding hook, command, prompt, agent, and extension trees, plus `.codex/skills/` for Codex's per-skill UI manifests; the paper-owned memory store under `.stage/memory/` is never synced
- `docs/mds/stage-workflow/` — the workflow conventions, the skill guide, the memory spec, and the model-id spec, in both editions
- `execs/run.sh` — the build entrypoint; your own edits to it are replaced, and the skills call it by name and by flag, so a repository that syncs a skill while keeping an older `run.sh` gets a run that fails at its build step
- `execs/scpts/import.sh`, `execs/scpts/lint.sh`, `execs/scpts/fmt.sh` — the utilities, for the same reason: sixteen skills call `import.sh --diff` and five call `lint.sh --no-build`, and a caller reading an exit code means the one its own version documents. A ref older than a utility simply skips it with a printed line
- `execs/update.sh` — the updater itself, so that no repository strands on an update mechanism too old to fetch its successor. It is installed by rename: the run doing the update finishes on the old file, and the next invocation uses the new one

The repository it pulls from is `STAGE_REPOSITORY`, resolved in that order: the environment, then `.env`, then the default `https://github.com/wanghao9610/STAGE.git`. Set it in `.env` to track a fork permanently, or prefix a single command — `STAGE_REPOSITORY=… bash execs/update.sh` — to override it once. Nothing else in `.env` is ever synced, which is why every script under `execs/` is safe to replace: an instance's configuration does not live in them.

Which harness trees it touches is `STAGE_HARNESSES`, resolved from the environment, then `.env`, then `all`. Set `STAGE_HARNESSES=codex` to keep only Codex's `.codex/` tree current, or use any comma-separated set of `claude`, `codex`, `cursor`, `dsh`, `kimi`, `pi`, and `qwen`; `none` updates only the shared skeleton. A tree left out is not installed, updated, or deleted. The shared `.agents/skills/` and `.agents/commands/`, the agent instructions, workflow docs, and `execs/` scripts remain in every run.

Harness configuration — `.cursorignore`, `.claude/settings.json`, `.codex/hooks.json`, `.cursor/hooks.json`, `.pi/settings.json`, and `.qwen/settings.json` — is installed only when missing and otherwise kept unless `--force` is supplied. The command reports a kept file that differs from upstream and names any STAGE hook absent from a kept registration.

An updater that still names a path upstream has since dropped stops with `Upstream ref is missing <path>` before it can replace itself. Fetch the current one by hand and commit it, then run `bash execs/update.sh` again:

```bash
curl -fsSL https://raw.githubusercontent.com/wanghao9610/STAGE/main/execs/update.sh -o execs/update.sh
```

The general forms are `bash execs/update.sh [--diff] [ref] [--harnesses LIST] [--skill NAME] [--force]` and `bash execs/update.sh [ref] [--harnesses LIST] --adopt`:

```bash
bash execs/update.sh --diff
bash execs/update.sh TAG_OR_BRANCH
bash execs/update.sh --harnesses claude
bash execs/update.sh --skill stage-flow-status
```

- `--diff` previews an update without changing a file, and exits `2` when one is available, `0` when everything already matches, `1` on error — so a script can tell an available update from a failed check. Harness configuration that differs is listed as kept rather than counted, unless `--force` puts it back in scope.
- A `ref` pins the update to a tag or branch.
- When a pinned ref predates `.dsh/commands/` or `.kimi-code/plugins/`, both a normal update and `--adopt` report the absent optional package and continue; a missing required path still stops the run.
- `--harnesses LIST` overrides `STAGE_HARNESSES` for one run with comma-separated harness names, `all`, or `none`. Unselected trees are outside both the write set and the uncommitted-change check.
- `--skill NAME` updates that one skill across the shared root and the selected harness trees, and leaves the agent instructions, workflow docs, and entrypoints alone. An invalid name, or one absent from an upstream skill tree in scope, stops the command before it overwrites anything.
- `--force` updates the same paths with both refusals lifted: uncommitted changes under them are overwritten instead of stopping the command, and the harness configuration is overwritten instead of kept. It widens nothing — a file of your own that upstream does not have is still left alone, so the skills and documents you added under those directories stay.
- `--adopt` installs the skeleton into a paper repository that already exists, copying only what is absent (see [step 1b](#1b-or-adopt-a-paper-repo-that-already-exists)); `--harnesses` limits which native trees are installed. It cannot be combined with `--force`: never touching an existing file is the whole contract.

`bash execs/update.sh --help` carries the full usage summary, so it stays correct when the flags change.

Files at matching paths are overwritten and new upstream files are added. Project-specific files that exist only in the updated directories are preserved. A STAGE file upstream no longer ships — each `SKILL_zh.md` beside an upstream skill, and the retired files listed in `RETIRED_FILES` in `execs/update.sh` — is deleted (`--diff` lists it as `removes`); any other file that exists only locally, your own included, is kept. `AGENTS.zh-CN.md` and `CLAUDE.zh-CN.md` at the project root are outside the update: it neither refreshes nor deletes them, so keeping or deleting them is yours. The update does not modify other directories, the current branch, Git remotes, or the staging area — the manuscript, `mates/`, `notes/`, and `cycls/` are never in scope. Commit current work before updating, then review and commit the result with `git status` and `git diff`.

Working on STAGE itself rather than on a paper? Edit only the neutral authored source under `.agents/skills/`, then run `bash .github/scripts/port.sh --write` to regenerate all six harness trees. Harness-only behavior belongs in that tree's rules or anchored overrides. Run `bash .github/scripts/port.sh` to prove every generated harness and shared link still matches, then `bash .github/scripts/check_consistency.sh` for the seven-root semantic invariants. The two checks run in CI.

## Project conventions

1. The manuscript lives under `manus/`: `main.tex` is the entry point, sections are `secs/<n>_<slug>.tex`, figures go in `figs/` with editable sources in `figs/srcs/`, tables in `tabs/`, the bibliography is `bibs/reference.bib`, and the template layers are in `stys/`.
2. Evidence lives under `mates/` and is read-only — `execs/scpts/import.sh` and `/stage-evid-curator` are its only writers. A wrong number is fixed at its source and re-imported, never edited in place.
3. Writing metadata lives under `notes/`: the fixed files `story.md`, `claims.md`, `outline.md`, `notation.md`, `style.md`, `adopt.md`, and reading notes in `notes/refs/`.
4. Submission cycles live under `cycls/<venue>_<year>/`, with the venue's official kit unpacked whole into that cycle's `template/`; revision scratch, promise lists, and venue follow-ups go in `tasks/`.
5. Builds and ephemeral reports live under `wkdrs/` and are never committed; durable outcomes land as status flips in `notes/claims.md` and entries in `tasks/`, not as report files.
6. Use `execs/run.sh` as the single build entrypoint and keep utilities in `execs/scpts/`; read runtime paths from `.env` rather than hardcoding machine-specific ones.
7. Every number in `manus/` either traces to a fingerprinted `mates/` entry or is written as `\todo{...}` — no third state — and every date written into an artifact comes from the system clock.
8. What a session learns that no file above owns goes to `.stage/memory/`, offered before it is written, with machine-specific facts in `.stage/memory/local/`; a memory never sources a number, a venue rule, or a claim about a cited paper.

The full collaboration and writing conventions are in [`AGENTS.md`](AGENTS.md) ([简体中文](AGENTS.zh-CN.md)) and [`docs/mds/stage-workflow/writing-workflow-conventions.md`](docs/mds/stage-workflow/writing-workflow-conventions.md) ([简体中文](docs/mds/stage-workflow/writing-workflow-conventions.zh-CN.md)).

## Adapting STAGE to a new paper

When you start a paper from STAGE, these are the adjustments worth making:

- Replace the title, authors, and affiliations in `manus/main.tex` with the real ones. Keep the anonymous placeholders during a double-blind cycle — `ANON=true` in `.env` makes `lint.sh` hunt identity leaks anywhere under `manus/`, comments included.
- Copy `.env.example` to `.env` and set `STAR_HOME` (empty when you are not pairing with a STAR repository), `LATEX_ENGINE`, `ANON`, and the optional `INVOLVE` and `STAGE_LANG`.
- Create the first submission cycle and its `venue.yml` with `/stage-stry-coach`. Page limits, deadlines, and checklist requirements are entered only as facts you confirmed — never invented.
- Unpack the venue's official kit whole into `cycls/<cycle>/template/`, not into `manus/`: that tree is the namespace `lint.sh` scans, and a kit's example `.tex` would trip its `\todo` count and its identity scan.
- Update the year and copyright holder in `LICENSE`.
- Replace `docs/htmls/stage.html`, `docs/htmls/stage_zh.html`, and `docs/srcs/` — they are STAGE's own landing pages and images, not your paper's. `docs/index.html` and `docs/index_zh.html` are the symlinks that mount those pages at the site root. The language switch between them uses absolute links (`/STAGE/index_zh.html`), so change the `/STAGE` prefix to your own repository name or the switch breaks. Leave `docs/mds/stage-workflow/` alone — `execs/update.sh` keeps it current.
- In an installed paper instance every selected harness is self-contained. In this template checkout, named trees may link shared files into `.agents/skills/`; materialize a tree before deleting the shared root. Keep `.agents/` with Codex, and keep each harness's hook/config files with its skills.

The skeleton stands on its own: the directory layout, `.env`, `execs/run.sh`, and `execs/scpts/lint.sh` all work with no skills installed at all, so deleting every tool directory is a supported way to use it. One paper, one repository — a second paper is a second instance of the template, not a second tree here.

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
