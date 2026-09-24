# Writing Workflow Skills Guide

**Language:** English | [简体中文](writing-workflow-skills.zh-CN.md)

STAGE provides sixteen connected writing workflow skills that turn imported evidence and a story into a submitted paper with an auditable claim trail: a repo wired to its research project, a read-only evidence base with a fingerprint per file, a story whose contributions are tracked claims, an outline with page budgets, sections drafted against evidence, tables generated from evidence rather than typed, figures with editable sources, a verified bibliography, prose polished without touching numbers, every number and citation audited, a simulated review in the venue's own format, a response with tracked promises, a frozen, packaged submission, and the poster that carries the accepted result into a hall.

This guide is one tight paragraph per skill. The rules every skill shares — git, the STOP line, `.env` and the build toolchain, dates, resolution, delegation, dialogue, the output table, the fabrication boundary, the layout, project memory, and the harness hooks — live in [writing-workflow-conventions.md](writing-workflow-conventions.md); skills cite its § numbers. The drafting, polish, and clarity-review passes share the evidence-preserving criteria of its [human-writing contract](writing-workflow-conventions.md#human-writing-contract). This directory is upstream-managed: edit it only in the STAGE template repo, never in a paper instance — `execs/update.sh` overwrites it.

## The pipeline

```text
an existing draft, or a fresh repo
  → stage-proj-adopt: wire it into STAGE — STAR pairing, venue, asset inventory,
    pre-existing numbers booked as unsourced claims

evidence (a paired STAR repo, or files dropped by hand)
  → stage-evid-curator: snapshot and register — fingerprints in mates/MANIFEST.md

story
  → stage-stry-coach: story.md + seeded claim ledger + user-confirmed venue.yml
  → stage-outl-planner: outline with page budgets, section skeletons, notation seed
  → stage-refs-curator: reading notes + a clean reference.bib

  ┌─ the drafting loop — re-entered per section, table, figure ──────────────────┐
  │  → stage-sect-drafter: draft one section; unfingerprinted numbers → \todo    │
  │  → stage-tabs-builder: tables from mates/ evidence only, % src: per row      │
  │  → stage-figs-designer: figure source → rendered PDF                         │
  │  → stage-copy-editor: natural prose — preserve meaning, evidence, numbers    │
  └──────────────────────────────────────────────────────────────────────────────┘

audits — cheap, repeat at will
  → stage-clms-auditor: every manuscript number ⇄ a fingerprinted evidence entry
  → stage-cite-auditor: every \cite key and every assertion ⇄ a reading note

the submission cycle — one venue attempt per cycls/<venue>_<year>/
  → stage-peer-reviewer: five-perspective simulated panel, real-review format
  → stage-resp-writer: reviews → point ledger → response + promise checkboxes
  → stage-subm-packer: build+lint gate, checklist, conversion into the venue's
    own template, package, SUBMISSION record, freeze/<cycle>_<date> tag
  → stage-pstr-builder: one takeaway, verified claims, reused figures →
    cycls/<cycle>/poster/ + a legibility gate measured at print scale

  ⌾ stage-flow-status: reads all of the above at any point —
    where things stand, and the one next action with its exact command
```

The list reads as one pass, but the workflow is not linear. `stage-proj-adopt` runs once, and only matters beyond `.env` when there is an existing draft to absorb. Evidence import repeats whenever upstream results move — that is what the fingerprints and `import.sh --diff` are for. The drafting loop is re-entered per section and again per review promise; the audits are designed to be re-run after every change that touches numbers or citations. The cycle skills repeat per venue attempt: a rejection starts a new `cycls/<venue>_<year>/` against the same ledger, where `weakened` and `unsourced` claims are the first things to fix. `stage-flow-status` is the way back in after any absence.

![STAGE writing workflow: fifteen skills in the order they run in plus one that reads across them, what each one writes, and how the drafting loop and the rejection loop close](../../srcs/stage-writing-workflow.png)

## Invoking the skills

| Tool | Skill root | Invocation | Example |
| --- | --- | --- | --- |
| Claude Code | `.claude/skills/` | `/stage-<name>` | `/stage-sect-drafter 1_intro` |
| Codex | `.agents/skills/` | `$stage-<name>` | `$stage-sect-drafter 1_intro` |
| Cursor | `.cursor/skills/` | `/stage-<name>` | `/stage-sect-drafter 1_intro` |
| DSH | `.dsh/skills/` | `/skill:stage-<name>` | `/skill:stage-sect-drafter 1_intro` |
| Kimi Code | `.kimi-code/skills/` | `/skill:stage-<name>` | `/skill:stage-sect-drafter 1_intro` |
| Pi | `.pi/skills/` | `/stage-<name>` | `/stage-sect-drafter 1_intro` |
| Qwen Code | `.qwen/skills/` | `/stage-<name>` | `/stage-sect-drafter 1_intro` |

The seven harnesses carry the same sixteen skills. Tool-neutral shared skill files live once under `.agents/skills/`; named harness trees link there when their bytes match and keep a real file only for native invocation or tool wording. The `/stage` command follows the same ownership rule: its complete roster and routing policy live in `.agents/commands/stage.md`, while Claude, Cursor, Pi, and Qwen keep only native argument adapters. Follow your harness's skill copy when one exists; otherwise the neutral copy is safe.

Six skills — `stage-proj-adopt`, `stage-stry-coach`, `stage-outl-planner`, `stage-resp-writer`, `stage-subm-packer`, `stage-pstr-builder` — are slash-only: they run only when named explicitly, never on the agent's own initiative, because each one sits on a decision that belongs to the author. Named harness manifests carry `disable-model-invocation: true`; Codex carries `allow_implicit_invocation: false` under `.codex/skills/`, linked into `.agents/skills/`. The other ten may also be selected by the agent when the task plainly matches. Every run ends with its report and the exact command for what comes next, and starts nothing further on its own: a request for status, an audit, or a review ends at that report, and continuing is `/stage-auto`'s job, below, or happens when you ask a run to keep going (conventions §11.4). Section arguments resolve by number, file slug, or title against `notes/outline.md` (conventions §5); the active cycle is the `cycle:` field in `notes/story.md`.

One command stands outside the roster: `stage-auto <goal> [involve=<level>]` pursues a stated goal, such as `stage-auto the method section drafted and its numbers audited`. It runs `stage-flow-status` first, then takes the next action each run names, starting the ten unmarked skills itself, one unit of work per start, because typing the command is your decision, made once for the pursuit; an action that does not advance the goal is listed rather than taken, and the skill that owns the goal's next step, or its first missing input, is started instead. At a † skill it stops and prints the exact command, and it stops the same way at a mode that exists to take your choice (`stage-refs-curator discover` or `position`, `stage-copy-editor style`, `stage-peer-reviewer extern=`), a STOP-line action, a question only you can answer, a venue value you have not confirmed, work only you can unblock (evidence to import, a promise box to tick), a repeat of the same start, a pass that changed nothing, or a failed action whose fix failed too. A goal that only asks for status, an audit, or a review starts only the skill that produces that report, and prints the command wherever another skill would come next. Confirmation points are still asked, each started skill keeps its own commit step, and nothing in a goal run imports evidence or enters a venue fact (conventions §11.5).

Every skill takes the same argument shape — `<skill> [TARGET] [DESCRIPTION] [involve=<level>]`. `involve=low|medium|high` is stripped first and sets how much this run asks (conventions §7.7) — it never revokes an approval you already gave or grants one you did not; every skill strips it, including ones whose `argument-hint` does not advertise it. The target resolves as above. Whatever is left is a description: free text saying in your own words what this run is for — `/stage-sect-drafter 4_experiments the ablation is the point, lead with it`. It carries your intent, your limits, and any explicit authorization: it can route a run down one of that skill's own paths and supply words the run then records, and a clear request to perform a specified operation — `and commit it` — answers that operation's question in advance, while background or a vague preference answers nothing. It never answers a mandatory confirmation point (conventions §7.7), never settles an ambiguous section name, never licenses a number that has no fingerprint, and never authorizes anything on the STOP line. A run a description routed says which path it took before it writes, so a misreading costs one line rather than one wrong edit. Where a skill's first argument is already free text — `stage-refs-curator` takes a paper title, `stage-tabs-builder` and `stage-figs-designer` take the purpose of a table or figure with no outline row yet — that argument is the description. Full rule: [conventions §7.13](writing-workflow-conventions.md).

Which model a run uses is set in `.env`, in three tiers: `STAGE_PLAN_MODEL` for the paper's judgment — the story, the outline, drafting, the simulated review, and the response — `STAGE_EXEC_MODEL` for production and checking — evidence, tables, figures, references, polish, the audits, the package, and the poster — and `STAGE_READ_MODEL` for read-only status, the check modes, and delegates that only gather. The roster in [conventions §11](writing-workflow-conventions.md) carries each skill's tier; a few modes take a different one, each named in that skill's section below. A skill you type runs in your session on the session's model: typing it does not switch models. When its tier names a different model, the run says so in one line at the start — the tier, that model, and the one way to get it: switch the session's model — and then runs where it is. That line is the paragraph led **Where this run executes.** at the head of every manifest's Workflow. Inside a run, a delegate takes the tier of its work — a collector READ, a delegate that writes files EXEC, an independent reading such as the peer-reviewer panel PLAN — and the files it writes record the model that wrote them. Each key holds one model name, or comma-separated `<harness>:<model>` entries tagged like `STAGE_HARNESSES`; only a harness whose dispatch tool takes a model per call reads them — Claude Code, and Codex where its subagent interface accepts one — and Cursor, DSH, Kimi Code, Pi, and Qwen Code ignore all three keys. The keys ship empty, and an empty key changes nothing and is not mentioned. Full rule: [conventions §11.6](writing-workflow-conventions.md).

## The skills

### stage-proj-adopt

Slash-only. Wires a new or existing paper repo into STAGE through an interview: paired STAR repo(s) into `.env` `STAR_HOME`, the target venue, and what already exists. For an adopted tex project it inventories the files, proposes how they map into the layout — confirming before touching anything — and then offers a first `import.sh` run. Numbers already sitting in the draft are booked as `unsourced` claims, which makes the existing text an explicit audit backlog instead of silent debt. Writes `notes/adopt.md`; may create the first `cycls/<cycle>/venue.yml`, from user-confirmed values only.

### stage-evid-curator

The evidence gate. Runs `execs/scpts/import.sh` for STAR sources; registers hand-dropped files under `mates/manual/` with `manual` entries in `mates/MANIFEST.md` whose source is stated in free text ("results emailed by X, 2026-08-01"); normalizes messy evidence — a CSV or wandb export gets a results-shaped `.md` beside it, marked `normalized-from:`, and the original stays untouched; proposes claim⇄evidence mappings ("results.md rows 3–7 → Table 1"); surfaces staleness via `import.sh --diff`. It never edits evidence content in place — an evidence problem is fixed at its source and re-imported, or it stays visible. Its `check` mode — the one a bare invocation runs — is on the READ tier, importing and registering on EXEC (conventions §11.6).

### stage-stry-coach

Slash-only. Dialogue-first story shaping: it reads imported idea docs and digests when a STAR pairing provides them, and interviews otherwise, until the pitch, problem, key idea, contributions, and venue rationale hold together in `notes/story.md`. Each contribution names its claim IDs, and the ledger `notes/claims.md` is seeded with those claims as `proposed`. It also creates `cycls/<cycle>/venue.yml` — page limits, deadlines, response format — from user-confirmed numbers only: a skill never invents venue rules (conventions §9c).

### stage-outl-planner

Slash-only. Turns the finalized story into the paper's skeleton: `notes/outline.md` with a section table whose page budgets sum within the venue limit, a figure plan, a table plan, and a claim→section assignment; skeleton files `manus/secs/<n>_<slug>.tex`, each opening with its section brief as a comment block, with their `\input` lines uncommented in `main.tex`; and a seeded `notes/notation.md`. After this run the paper builds with its real structure, and every later skill knows what belongs where and which claims each section must carry.

### stage-sect-drafter

Drafts or revises **one section per invocation**, resolved per conventions §5. It loads the section brief, the evidence mapped to the section's claims, the relevant ledger rows, `notes/notation.md`, and the optional author style profile, then writes the tex under the human-writing contract. Paragraphs lead with concrete claims and keep technical terms stable; a paragraph-level review removes clustered formulaic scaffolding without changing protected content. Any number lacking a `mates/` fingerprint is written as `\todo{...}` — no third state (conventions §9a). On the way out it updates the ledger (`Stated in`, status → `drafted`), appends new symbols to the notation file, and updates the section's outline row, so drafting a section moves the whole bookkeeping with it.

### stage-tabs-builder

Generates `manus/tabs/*.tex` **from `mates/` evidence only**: booktabs style, one `% src: mates/<...>#<anchor>` comment per data row, and a `\todo` cell for every missing value, each opening an `unsourced` claim. It updates the outline's Tables rows and the ledger. Hand-typing numbers into a table is the failure mode this skill exists to kill — a table it built can be re-audited row by row by `stage-clms-auditor` without a human remembering where anything came from.

### stage-figs-designer

Owns the figure inventory (the outline's Figures table) and each figure end to end: its purpose, its editable source under `manus/figs/srcs/` (tikz, python, drawio — or a MANIFEST entry for imported artwork), and its rendered PDF under `manus/figs/`. Every figure has a source file or a manifest entry; a PDF with no origin does not happen. The teaser figure gets a dedicated checklist — it must tell the story alone, with a self-contained caption — because it is the one figure every reviewer reads. The no-argument audit is on the READ tier, planning and building a figure on EXEC (conventions §11.6).

### stage-refs-curator

Bibliography hygiene and the reading-note base. It dedupes `manus/bibs/reference.bib`, keeps keys and venue fields consistent, takes in newly read papers as `notes/refs/<ABBREV>.md` notes (with a Citable facts section precise enough to audit against) plus an index row and a bib entry, and does related-work positioning: which cluster a work belongs to and what is claimable about it. When a STAR pairing imported `metds/refs/`, it seeds from those notes instead of starting cold. A converted note carries the upstream note's `depth:`, so a paper the upstream only skimmed stays visible as one rather than passing as read here. `position` is the one mode on the PLAN tier; every other mode is on EXEC (conventions §11.6).

With no pairing to seed from, `discover` is the cold-start path and the one mode that searches by topic: it builds a profile from `notes/story.md`, the claim ledger, and whatever sections are drafted, sweeps one query per kind that applies and keeps going while queries still surface something new, grows a thin result set through the citation graph without ever letting expansion feed on its own finds, and brings back ranked candidates with a record fetched for each. Then it stops and asks — what enters the reference base is the author's decision at every involve level, and nothing a search surfaced reaches the bib or a note unpicked. What the author picks goes through ordinary intake unchanged; what they pass over is logged in the index so the next run proposes something else, and every query is logged with its hit count, the empty ones included. Live search is otherwise reserved to `stage-peer-reviewer`, and both skills work under the same citation-integrity contract (conventions §9b), including its fallback to topic terms alone when the cycle is anonymized.

### stage-copy-editor

The polish pass, over one section or the whole manuscript: clarity, flow, natural scholarly prose, consistency against `notes/notation.md` (terminology canon, abbreviation first-use), and length trimmed toward the outline's budgets. Before editing it freezes facts, numbers, keys, source anchors, todos, attribution, claim strength, and evidence-required qualifiers. It diagnoses pattern clusters and their rhetorical function, then rewrites at paragraph scale rather than swapping words from a blacklist. The protected inventory is compared after editing, and anything that cannot be proved meaning-preserving is reported rather than applied. The build and lint run at the end; prose warnings remain advisory. Systematic issues it cannot fix in place go to `wkdrs/reports/POLISH_<date>.md` and, as checkboxes that outlive the report, to `tasks/polish_followups.md`, so they can be handled deliberately rather than smoothed over.

It is also where the paper's voice is written down. `style` mode records the author's prose preferences as `notes/style.md` (conventions §8.11) — nine dials covering sentence length and rhythm, voice, paragraph openers, transitions, hedging, enumeration, tense, and math density; a prefer/avoid list of constructions; the words this paper does not use; and the samples those were derived from — arrived at by interview, from paragraphs the author points at, or from a named preset. The file binds `manus/` prose alone and outranks nothing: §9 first, then the notation canon, then the venue's format, then the profile, so no dial ever licenses a number or changes what a sentence asserts, and a sample supplies dials rather than sentences. `stage-sect-drafter` reads it while drafting; a polish pass measures the manuscript against it and reports the numbers without ever making a dial a gate. There is no profile until someone asks for one, and its absence is the default rather than a gap.

### stage-clms-auditor

The numbers audit. It extracts every number from `manus/tabs/` and `manus/secs/`, traces each through `% src:` comments and ledger evidence links to a fingerprinted `mates/` entry, and issues a verdict per number: matched, mismatched, or unsourced. It flips ledger statuses accordingly (`verified` / `unsourced`), checks evidence staleness with `import.sh --diff`, writes `wkdrs/reports/CLAIMS_<date>.md`, and opens a `tasks/` item per failure. Run it whenever numbers moved — it is cheap, and it is the reason the final paper's numbers can be trusted.

### stage-cite-auditor

The citation counterpart: every `\cite` key must resolve in the bib; every assertion the manuscript makes about a cited work must be checkable against a reading note (`notes/refs/` or refs imported under `mates/`) — unverifiable assertions are flagged, never silently fixed; a missing-citation scan covers claims that obviously need support; bib fields get a hygiene pass. Writes `wkdrs/reports/CITES_<date>.md` and a `tasks/cites_followups.md` checkbox per failure. Together with `stage-clms-auditor` it closes the fabrication boundary from both ends: our numbers and our statements about everyone else's.

### stage-peer-reviewer

A simulated program committee. Panel mode dispatches five perspectives — novelty & related work, technical soundness, experimental rigor & reproducibility, clarity & presentation, and a devil's advocate who builds the strongest honest rejection case and rules whether it survives rebuttal — each with a question bank, a citation-integrity contract (references named only when whitelisted in the paper's own bib or verified by a logged live fetch; memory is never a source), and one file of its own to write in the run directory. A panelist runs its own searches under conventions §6.9 — the rate divided by how many are running, every payload cached under its own prefix — and writes what a hit would settle before it runs the query; its verdict on its own hit is advisory, and the chair opens the cached record and applies that criterion itself before any reference is named, because a panel is the one fan-out whose reading the main agent repeats rather than replaces (§6.6). The chair verifies every anchor, synthesizes one meta-review, and scores by matching anchored rubric bands — a 6-point conference scale or journal decision tiers per `venue.yml`'s `scale:` — with hard caps (verified undiscussed prior art doing the core contribution caps the score at 2) and an honest confidence; `quick` runs a single-pass version. The durable artifact is `cycls/<cycle>/reviews/SIM_REVIEW_<date>.md`, weaknesses naming the claim IDs they attack — which is what lets `stage-resp-writer` treat simulated and real reviews identically; per-perspective reviews and the citation audit live in the run's `wkdrs/reports/` directory. It never edits the manuscript: it attacks, and the drafting loop answers.

Its clarity perspective also applies the human-writing contract: promotional overclaiming, vague attribution, terminology cycling, repeated section templates, generic conclusions, and chatbot residue are anchored as presentation findings. They are never presented as proof of AI authorship.

`extern=<path>` points the same panel at a paper this repository did not write — the PDF somebody asked you to referee. The five perspectives, the citation-integrity contract, the anchored bands and the caps are unchanged; what drops away is everything that only makes sense about our own paper. There is no cycle to resolve and no ledger to attack, so the venue and its scale are asked once before the panel is briefed and `attacked_claims` stays empty. There is no build — the file is read as it was handed over. Search runs in confidential mode by default, because a paper sent to a referee is under review until its owner says otherwise, and a query carrying its title tells the search logs who is reviewing what. And the report is a `REFEREE_<date>.md` under `wkdrs/`, or wherever `out=` names: never in `cycls/<cycle>/reviews/`, which `stage-resp-writer` reads as reviews of *this* paper. Nothing is committed and nothing is registered, because a referee report on somebody else's submission is not one of this paper's stages — the run says so, and says that `wkdrs/` is regenerable, so keeping the report means copying it out.

### stage-resp-writer

Slash-only. Parses reviews — real `received_*.md` files dropped into `cycls/<cycle>/reviews/` and/or `SIM_*` files — into a point ledger mapping every reviewer point to the claims it attacks and the evidence that answers it; drafts the response within the venue's official `response_limit`; records every promised change as a `- [ ]` checkbox in `tasks/<cycle>_promises.md`; and downgrades conceded claims to `weakened` in the ledger. Writes `cycls/<cycle>/response/RESPONSE_<date>.md`. A promise made to a reviewer becomes a tracked task, not a hope.

### stage-subm-packer

Slash-only. Preflight and packaging: a `run.sh` build and `lint.sh` must pass, the venue checklist is walked, figures, tables, and bib are checked complete, and the package — camera PDF, supplementary, submission-ready source — lands under `wkdrs/builds/`. The completeness sweep also lists every claim still `unsourced` or `weakened`, and every `performance` or `factual` claim the latest claims audit did not verify — still `drafted`, or `verified` in a file revised since that audit — as soft findings the author may waive on the record, and the SUBMISSION record lists them with their waivers; they never block the pack. It writes `cycls/<cycle>/SUBMISSION_<date>.md` recording what was submitted where, and creates the git tag `freeze/<cycle>_<date>`, the one place freeze tags come from (conventions §1). It also refuses an adopted repository whose `notes/adopt.md` still has an empty `backfilled:` — that is the one state where `lint.sh` reads clean over numbers that trace to nothing, so the marker count proves less than it looks (conventions §9a). Camera-ready mode additionally refuses to pack while `tasks/<cycle>_promises.md` has unchecked boxes: promises to reviewers are honored before anything ships.

It is also where the paper takes the venue's own shape. `convert` mode reads the official template kit the user supplies — unpacked into `cycls/<cycle>/template/`, beside that cycle's `venue.yml`, whose `template:` names the class inside it — and generates a standalone copy under `wkdrs/` that compiles under the venue's class: the kit's own macros for title, authors, and abstract, a small `compat.sty` for what `stys/stage.cls` provided and the venue class does not, and `stys/stage.sty` carried over verbatim, since that layer was built to survive the swap. `manus/` is never edited and nothing is added to it — the kit stays out of a tree `lint.sh` scans for `\todo` markers and identity leaks — and the copy is regenerated from scratch every run, so there is no second source of truth and no drift. The template is never fetched or reconstructed from memory — the same boundary that governs numbers governs formats (conventions §9). `convert` skips every freeze gate on purpose: fitting a paper into a page limit takes many conversions, and all of them happen while `\todo` markers are still in the manuscript. The converted copy's page count, not the preprint build's, is what `page_limit_main` measures. What the conversion cannot do for you — a dropped `\keywords`, an appendix ordering that needs a decision — becomes a `- [ ]` line in `tasks/<cycle>_venue.md`, each naming the skill that owns the fix. That list is updated rather than regenerated, so a settled item never comes back, and unlike `tasks/<cycle>_promises.md` an open box there blocks nothing: these are findings, not promises to a reviewer.

### stage-pstr-builder

Slash-only. The poster is not the paper reflowed onto a bigger sheet — it is a selection, and making that selection is the whole skill. `plan` derives one takeaway sentence from `notes/story.md`'s pitch, walks `notes/claims.md` for the rows that reached `verified`, proposes the few that carry the contribution, and records the rest as visible exclusions so a later run does not re-litigate a settled cut; the user confirms it before anything is written. `render` turns that plan into `cycls/<cycle>/poster/poster.tex` — one block per planned zone, claim wording taken from the ledger row rather than argued afresh, figures included from `manus/figs/` unmodified — and compiles it into `wkdrs/builds/poster/`. New artwork is never drawn here: a figure that fails at poster size is a finding for `stage-figs-designer`.

Two boundaries make it a STAGE skill rather than a poster tool. Numbers carry `% src:` comments to fingerprinted `mates/` evidence exactly as table rows do, and the manuscript's third state does not exist — `check` fails hard on a `\todo`, because a marker is a draft nobody has printed and this sheet gets printed. And legibility is arithmetic rather than impression: the sheet size is a user-confirmed `venue.yml` fact, so effective point size is computed at print scale against the floors in the skill's `references/poster-layout.md`, with the smallest text on the sheet named with its measured size. The poster is also the one artifact that does not inherit `ANON` — it carries author names because you stand beside it, which is why it lives under `cycls/` and never under `manus/`, a tree `lint.sh` scans for identity leaks. Where the venue supplies an official poster kit it is copied byte-for-byte and never edited; where it supplies only a size, the house `tikzposter` template is used at that size, and a kit is never fetched or reconstructed from memory (conventions §9). `check` is on the READ tier, the rest of the skill on EXEC (conventions §11.6).

### stage-flow-status

The read-only map of the whole flow: per-section, per-figure, per-table status from the outline; claim coverage counts by status; evidence freshness; refs count; cycle state; the latest build and lint result; and **one** next action with its exact `/stage-*` command. It never writes — not even a report. Run it when returning to the paper, before deciding what to do next, or whenever the state in your head and the state on disk might have drifted. It is the one skill on the READ tier. Claude Code forks it on the model its own manifest names — pinned there by hand in the STAGE upstream until a configure step writes `STAGE_READ_MODEL` into it — so under Claude Code its one-line tier notice compares the READ key with that model and points at that upstream field rather than at the session's model; in a paper repository, `execs/update.sh` replaces a local edit to it (conventions §11.6).

## Where everything is defined

- Shared rules and § numbers: [writing-workflow-conventions.md](writing-workflow-conventions.md) — the output table is §8, the fabrication boundary §9, the layout §10.
- The skills themselves: authored once in tool-neutral form under `.agents/skills/` and ported mechanically into the six named harness trees; harness-only behavior lives in that tree's adapter rules or anchored overrides.
- The user-facing overview and quick start: the repository [README](../../../README.md).
