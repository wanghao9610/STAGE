---
name: stage-proj-adopt
disable-model-invocation: true
description: >-
  Adopt an already-started LaTeX manuscript into STAGE without destroying anything. A read-only
  inventory maps the draft — main file, section inputs, figures, tables, bibliographies, styles,
  venue signals, git shape, and files that look like evidence rather than prose — then the mapping
  and the per-file move plan into manus/ are each confirmed before anything is touched; every
  \input, \graphicspath, and \bibliography edit is named in the plan before it is applied, and the
  adopted tree is verified with a build. An external draft is copied in, its source
  tree never modified. Every number already in the prose is recorded as an unsourced claim — the
  backlog /stage-clms-auditor works down — and candidate
  evidence files are routed to /stage-evid-curator, never copied into mates/ here. Use when the
  user runs /stage-proj-adopt, wants to bring an existing paper, thesis chapter, or Overleaf
  export into STAGE, or asks how to onboard a draft that did not start from the template.
  Bilingual (en/zh).
---

# Project Adopt — bring an in-progress manuscript into STAGE

**Reply language (conventions §7.6).** `.env` `STAGE_LANG=en|zh` sets chat replies and the Markdown this run writes; resolve it once at the start of the run — `grep -sE '^STAGE_LANG=' .env || true`, folded into the opening load call. Unset or empty → follow the user's dialogue language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request wins. English whatever it says: everything under `manus/`, the response to reviewers, and every structural literal — frontmatter keys, ledger statuses, IDs, paths, bibkeys, venue and metric names. The adoption record is always written in English — every downstream skill reads it — with paths, metric names, and claims quoted verbatim in whatever language the draft uses; when the dialogue is Chinese, the closing digest in chat carries the summary in Chinese. `SKILL_zh.md` is this file's Chinese edition, kept in step for human readers only and never loaded at runtime; this SKILL.md stays authoritative.

Invocation: `/stage-proj-adopt [SRC_PATH]` — no argument surveys this repository for a manuscript living outside `manus/` (the toolkit dropped onto an existing paper repo); a path adopts an external draft directory — an old project, an Overleaf export — by copying files in, and the source tree is never modified. Nothing to adopt either way is a valid answer: say so and stop rather than inventing work.

**Shared conventions.** `docs/mds/stage-workflow/writing-workflow-conventions.md` is the shared baseline every STAGE skill loads: read the whole file at the start of every run — there is no section-selective loading. It binds this skill hardest at §9 (the fabrication boundary — a number already in the prose is an unsourced claim, never a sourced one), §10 (project layout, which the move plan targets), §8 (the artifact registry, including §8.2's manifest schema and §8.9's `backfilled:` gate), and §7 (dialogue — nothing moves before its confirmation point). This file states what is specific to this skill and wins wherever it is stricter.

**Reusing an earlier load.** A second STAGE skill in the same conversation does not pay for the conventions twice: skip the re-read only when the same file's text is still verbatim visible in this conversation. A summary that survived a context compaction, or a memory of having read it, does not count — when in doubt, read it again.

## Role

Every other STAGE skill assumes the layout: prose under `manus/`, evidence under `mates/` behind its manifest, claims linked in `notes/claims.md`. You exist for the paper that predates all of that — months of tex in one flat directory, a bibliography grown by hand, results pasted straight into tables. You make that draft legible to the family without losing a line of it: files land where the skills expect them, references keep resolving, and every number the draft already asserts goes on the books as exactly what it is — a claim nobody has sourced yet.

You are the on-ramp, not the editor. You do not judge the writing, you do not source a single claim, and you do not write evidence — `/stage-copy-editor` and the drafting skills own the first, `/stage-clms-auditor` works the backlog you hand it, and `mates/` belongs to `/stage-evid-curator` with `execs/scpts/import.sh`.

## Core Principles

1. **Nothing moves without a confirmed plan.** The inventory is read-only; the mapping is confirmed first, the per-file move plan second. Between confirmation points you are autonomous; past them you do exactly what was approved, and a row the user did not approve stays where it is.
2. **Never destroy, never silently overwrite.** An external source tree is copied from, never modified. Inside the repo the only thing freely overwritten is an untouched template placeholder; anything with real content is a conflict, and a conflict is a question, never a resolution. Nothing is deleted, ever — build junk is listed and left where it lies; `.gitignore` already covers it.
3. **A pre-existing number is an unsourced claim.** The draft's numbers get no credit for already being typeset: until `/stage-clms-auditor` links one to registered evidence, it is unsourced, and the backlog records it as such — verbatim, located, honest. Adoption never launders a number into looking sourced.
4. **Evidence is routed, never smuggled.** `mates/` has exactly two writers — `/stage-evid-curator` and `execs/scpts/import.sh` — and this skill is neither. Files that look like evidence are inventoried and routed, never copied into `mates/` here, and the manifest entry that admits them is written by the curator, not by adoption.
5. **The tree must still build.** Adoption ends with `bash execs/run.sh` compiling the moved tree out-of-tree into `wkdrs/builds/`. A failure caused by a path this skill rewrote is fixed here; a failure the draft already had is reported with `file:line` and left to its owner — pre-existing breakage is a finding, not your repair.
6. **Adoption does not invent judgment.** No rewriting, no scoring, no story, no venue strategy — the record is descriptive. What the draft argues is `/stage-stry-coach`'s to elicit; whether its claims hold is `/stage-clms-auditor`'s; how it reads is `/stage-copy-editor`'s.

## Workflow

### Step 0: Resolve the source

Parse the argument per the Invocation line. A `SRC_PATH` outside the repository → external mode: files are copied in, the source tree is read and never written. No argument → overlay mode: search this repository outside `manus/`, `mates/`, `notes/`, `cycls/`, `wkdrs/`, `execs/`, `docs/` for tex sources. Nothing found means there is no draft to absorb — it does **not** mean there is nothing to do: fall through to Step 4.1 and wire the repository, which is the whole of adoption for a paper that starts here. `.env` from `.env.example`, `STAR_HOME` from the Step 2 pairing question, `LATEX_ENGINE` from the sources, and a `notes/adopt.md` that records the pairing and the venue target with an empty inventory and an empty backlog. Skip only when `notes/adopt.md` already exists and `.env` already carries the pairing: then say the layout stands and stop. A re-run on an adopted repository re-probes and updates the record rather than starting over, and never re-proposes an executed move.

### Step 1: Inventory (read-only)

In the main agent, writing nothing — a manuscript tree is small, and no fan-out is worth its coordination: the main file (`\documentclass`; several candidates are all listed, marked); the input closure (`\input` / `\include`); figures plus `\graphicspath`, rendered assets split from editable sources; table files; `.bib` files plus `\bibliography` / `\addbibresource`; local `.sty` / `.cls` / `.bst`; venue signals (class and style names); the engine the sources imply (`fontspec` / `ctex` → xelatex, else pdflatex); build junk; files that look like evidence rather than prose — results dumps, CSVs, run logs; and the git shape when the tree is a repo (first commit, last touch, active paths). Present one compact mapping block, every low-confidence line marked, unknowns as unknowns.

### Step 2: Confirmation point 1 — the mapping

Ask via AskQuestion, one question at a time, only about what the probe could not settle: which candidate is the main file, which directories are prose vs evidence vs junk, whether a paired STAR repo exists (that fills `STAR_HOME`), the target venue when nothing names one. Options come from the probe with the recommendation marked. Nothing is written until this point clears.

### Step 3: Confirmation point 2 — the move plan

Propose the plan as one table, one row per file — current path → target → the tex edits the move forces — then get it approved:

1. Targets: the main file → `manus/main.tex`; sections → `manus/secs/`; rendered figures → `manus/figs/`; editable figure sources (`.svg`, `.drawio`, plot scripts) → `manus/figs/srcs/`; tables → `manus/tabs/`; bibliographies → `manus/bibs/`; local styles → `manus/stys/`.
2. Edits: every `\input` / `\include` path, `\graphicspath`, `\bibliography` / `\addbibresource` the moves break, named in the row that breaks it — the plan shows each edit before any is applied. One edit is forced by the destination rather than by a broken path and is easy to miss: a draft's own main file arriving at `manus/main.tex` must keep `\usepackage{stys/stage}` from the placeholder it replaces. That package carries the `\todo` macro every downstream skill writes and `lint.sh` counts, plus graphicx/booktabs/xcolor/hyperref and `\graphicspath{{figs/}}`. Drop it and the tree still builds — the loss surfaces only when a drafter first needs a marker — so the row for the main file always names this edit, and a `\graphicspath` the move orphaned is replaced by it rather than kept.
3. Exclusions: build junk gets no row (listed, left in place); evidence-looking files get no row (they are Step 6's list); a target that already holds real content is shown and asked about per file — only an untouched template placeholder is overwritten freely.
4. Approval: one AskQuestion — approve all, approve by group (sections / figures / tables / bibs / styles), or abort. Unapproved rows do not move.

### Step 4: Execute the approved plan

1. `.env` from `.env.example` when absent — `LATEX_ENGINE` from the Step 1 detection, `STAR_HOME` from Step 2 — and an existing value is never rewritten without a per-key yes.
2. The approved rows, exactly: `git mv` inside a git tree so history follows the file, plain moves otherwise, copies from an external `SRC_PATH` with the source untouched.
3. The named tex edits — and not one other character of prose.

### Step 5: Verify the build

`bash execs/run.sh` → latexmk, out-of-tree, into `wkdrs/builds/`. A failure traced to a path this skill rewrote is fixed and re-run; a failure the draft already had is reported with `file:line` and the first error, never silently patched (Principle 5). No latexmk on the machine → say the build went unverified and how to run it later.

### Step 6: The unsourced-claims backlog

Scan the adopted prose and tables: every number presented as a result — a metric value, a percentage, an "improves by", a speedup, a table cell — becomes one backlog row: the claim verbatim, its post-move `file:line`, and the suspected evidence source (a STAR run, a cited paper, a co-author's file) when the text hints at one, `unknown` otherwise. Setup numbers stay out — hyperparameters, equation constants, citation years — and when in doubt, in: an extra row costs one check, a missed one costs the paper's credibility. The backlog is recorded in the adoption record, not the ledger: `notes/claims.md` has one writer, `/stage-clms-auditor`, which ingests each row as an unsourced claim and works it down.

Say plainly, in the record and in chat, what the backlog means until then: those numbers are the third state §9a forbids — neither traced nor marked — and `lint.sh`, which counts markers, will read the manuscript as **clean** while not one of them traces. The backlog is the only thing that knows. That is why `backfilled:` in the frontmatter is a gate and not a note: it stays empty here, only `/stage-clms-auditor` sets it, and `/stage-subm-packer` refuses to pack while it is empty (conventions §8.9, §9a).

Alongside the backlog, list the candidate evidence files from Step 1 — the results dumps, CSVs, and run logs whose numbers back these claims. Each enters `mates/` only through `/stage-evid-curator` — `import` when the paired STAR repo produced it, `register` when it is hand-dropped — which writes the manifest entry, one `##` entry per file in `mates/MANIFEST.md`:

```
## <slug>/<path as upstream has it>      # manual/<path> for hand-dropped files
- source-type: star | manual
- source: <star: $STAR_HOME/<rel> · manual: free text — path, URL, or person>
- source-commit: <the SHA import.sh pinned | n/a>
- source-stamp: <first generated:/updated:/finalized: value in source | n/a>
- sha256: <checksum of the file as it landed>
- imported: <YYYY-MM-DD, real date>
- covers: <one line — what this file evidences>
```

This is conventions §8.2 copied, not a variant of it: the heading is the path **relative to `mates/`** with no `mates/` prefix (`xseg/wkdrs/results/main.md`, `manual/results.csv`), every field is a `- ` list item, and the field names are the ones `execs/scpts/import.sh` actually writes — `source-commit`, `source-stamp`, `covers`. `source-type: star` entries live under `mates/<slug>/**`, one slug per upstream source, and belong to that script, which rewrites them wholesale on re-import; `source-type: manual` entries live under `mates/manual/**` and belong to `/stage-evid-curator`, and the script never touches them. `source-stamp` answers "has upstream moved?" and needs a reachable source; `sha256` answers "did these bytes change here?" and needs only the file. Evidence is read-only — a wrong number is fixed at its source (the STAR repo, the original document) and re-imported, never edited under `mates/` — and a file with no entry does not exist to the writing skills.

### Step 7: Record, route, digest

Write `notes/adopt.md`: the confirmed mapping, every move executed (old → new), every tex edit applied, the build verdict, the unsourced-claims backlog, the candidate-evidence list, and what adoption did not do. Then route in order — `/stage-evid-curator` to get evidence registered before anyone argues from it; `/stage-clms-auditor` to ingest the backlog into `notes/claims.md` and start sourcing; `/stage-stry-coach` for the story the draft argues, now that the family can read it — and close in chat, ≤300 words: what moved, what built, how many claims went on the books unsourced, and the first route.

## State & File Rules

- Writes are confined to: the approved moves and copies plus their named tex edits under `manus/`, `.env` (created from `.env.example`; an existing value changed only per-key with a yes), and `notes/adopt.md` — the adoption record. Nothing else.
- Never written here: `mates/**` (two writers only: `/stage-evid-curator` and `execs/scpts/import.sh`), `notes/claims.md` (`/stage-clms-auditor`'s ledger), `notes/refs/**`, `cycls/**`, and any external `SRC_PATH` tree. The build lands under `wkdrs/builds/` through `execs/run.sh`, which owns it.
- Nothing is ever deleted: not build junk, not superseded copies, not the directories an overlay adoption empties — they are listed for the user, whose call it is.
- Real dates only: the adoption date and every date in the record come from the system clock.
- Git: history is read (dating the draft, finding the main file); confirmed moves inside a git tree run as `git mv` so the rename stays tracked; nothing is staged beyond what `git mv` itself stages, and this skill never commits — the commit is the user's.
- Provenance (conventions §8): every artifact this run writes under `notes/`, `tasks/`, `cycls/`, or `wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended `model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.

## Dialogue Discipline

- Both confirmation points go through AskQuestion, one question per call. If it is unavailable (headless / scripted), fall back to plain text — still one at a time, still requiring an explicit answer before any write.
- Lead with what the probe found and what it could not settle. An unknown reported as unknown is the point; a confidently wrong main-file guess costs every downstream skill.
- Say plainly what adoption did not do: it sourced no claim, judged no writing, imported no evidence — `/stage-clms-auditor`, the drafting skills, and `/stage-evid-curator` own those, in that order of urgency.
- Reply in the user's language; the record stays English; paths, metric names, and quoted claims keep their original form inside Chinese dialogue.
