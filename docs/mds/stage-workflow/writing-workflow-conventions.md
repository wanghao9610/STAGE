# Writing Workflow Skill Conventions

**Language:** English | [简体中文](writing-workflow-conventions.zh-CN.md). The zh-CN edition is kept in step for human readers only and is never loaded at runtime — this file stays authoritative.

The rules every STAGE writing workflow skill follows. The fifteen skills — `stage-proj-adopt`, `stage-evid-curator`, `stage-stry-coach`, `stage-outl-planner`, `stage-sect-drafter`, `stage-tabs-builder`, `stage-figs-designer`, `stage-refs-curator`, `stage-copy-editor`, `stage-clms-auditor`, `stage-cite-auditor`, `stage-peer-reviewer`, `stage-resp-writer`, `stage-subm-packer`, `stage-flow-status` — each carry their own workflow, their own limit on what they may write, and their own rubric. What they share lives here, once. there is no section-selective loading: **every skill reads this whole file at the start of every run.**

**Precedence.** This file is the **baseline**. A skill's `SKILL.md` may be **stricter** — a narrower write surface, a lower threshold, an extra confirmation point, a rule that it never commits at all — and the stricter rule wins. A skill never loosens what this file sets. Where a `SKILL.md` carries a one-line summary of a rule below, that line is the binding reminder and this file is the full rule. Skills cite these sections as "conventions §n"; the numbers are frozen and never renumbered.

This file is a contract for the skills and a description for the reader: it is what the workflow will and will not do to your manuscript.

## 0. Vocabulary

Terms this file and every `SKILL.md` use without re-explaining. Each is defined in full where the "Defined in" column points.

| Term | In one clause | Defined in |
|---|---|---|
| manuscript | the one paper this repository produces: `manus/main.tex` plus everything it `\input`s | §5, §10 |
| section | one source file `manus/secs/<n>_<slug>.tex`, one row in the outline's Sections table | §5 |
| evidence | a read-only file under `mates/`, snapshotted from a STAR repository or hand-registered, that numbers and claims cite | §8, §9, §10 |
| fingerprint | the `mates/MANIFEST.md` entry pinning an evidence file: source, commit, source-stamp, import date | §8 |
| claim | one ledger row: one sentence the paper asserts, with where it is stated, its evidence, and its status | §8, §9 |
| ledger | `notes/claims.md`, the hub linking every claim's statements ⇄ evidence ⇄ status | §8 |
| cycle | one submission attempt at one venue: `cycls/<venue>_<year>/` and everything in it | §5, §8 |
| active cycle | the cycle skills act on: `cycle:` in `notes/story.md` frontmatter | §5 |
| venue profile | `cycls/<cycle>/venue.yml`: the venue's rules, entered only as user-confirmed facts | §8, §9 |
| freeze | the git tag `freeze/<cycle>_<date>` marking exactly what was submitted; only `stage-subm-packer` creates one | §1 |
| promise | a change committed to in a response, a `- [ ]` box in `tasks/<cycle>_promises.md` until kept | §8 |
| `\todo{...}` | the red, bold, greppable macro from `manus/stys/stage.sty` marking every value the manuscript does not yet source | §9 |
| staleness | an imported file whose upstream stamp no longer matches its recorded fingerprint; detected by exact comparison, never mtime | §8 |

## 1. Git

**The discipline is one commit per skill working session** — offered, never silent, staging only that session's work, with the subject prefix naming the skill: `stage-sect-drafter: 3_method — first full draft`, `stage-evid-curator: import xseg results`. One skill, one namespace in the log.

**Skills that never commit** — two, for different reasons. `stage-flow-status` writes nothing at all, so its git usage is read-only (`status` / `diff` / `log`). `stage-proj-adopt` writes plenty — file moves, the tex edits those moves force, the adoption record — and still never commits: adoption rearranges a manuscript somebody else built, and reviewing that rearrangement is not a skill's to skip. `git mv` stages the renames it performs and nothing else is added; the commit is the user's.

**Skills that may commit**, and what each may stage:

| Skill | Commits | Stages |
| --- | --- | --- |
| `stage-evid-curator` | offered once when the session ends | the `mates/` files this run imported or registered, plus `mates/MANIFEST.md` |
| `stage-stry-coach` | offered once when the session ends | `notes/story.md`, the seeded `notes/claims.md`, the cycle's `venue.yml` when created |
| `stage-outl-planner` | offered once when the session ends | `notes/outline.md`, `notes/notation.md`, new `manus/secs/` skeletons, the `\input` edits in `manus/main.tex` |
| `stage-sect-drafter` | offered once per drafted section | that section's `.tex`, plus its ledger, notation, and outline updates |
| `stage-tabs-builder` | offered once when the session ends | the tables written, plus their outline and ledger updates |
| `stage-figs-designer` | offered once when the session ends | `manus/figs/` renders, `manus/figs/srcs/` sources, outline updates |
| `stage-refs-curator` | offered once when the session ends | `manus/bibs/reference.bib`, `notes/refs/` notes and index |
| `stage-copy-editor` | offered once after the pass | only the `.tex` files the pass edited — the polish report stays in `wkdrs/` |
| `stage-clms-auditor` | offered once after the audit | `notes/claims.md` status flips and the new `tasks/` items — the audit report stays in `wkdrs/` |
| `stage-cite-auditor` | offered only when the run fixed bib fields | `manus/bibs/reference.bib` — findings stay in the `wkdrs/` report |
| `stage-peer-reviewer` | offered once per review | the one `SIM_REVIEW_*` file it wrote |
| `stage-resp-writer` | offered once when the session ends | the `RESPONSE_*` file, `tasks/<cycle>_promises.md`, ledger downgrades |
| `stage-subm-packer` | one at pack time; one more when a `convert` run registers a venue template kit | `cycls/<cycle>/SUBMISSION_<date>.md`; the `freeze/<cycle>_<date>` tag then lands on that commit — the package itself stays in `wkdrs/builds/`. The `convert` commit is separate and stages only what that run wrote outside `wkdrs/` — the kit under `cycls/<cycle>/template/` and `tasks/<cycle>_venue.md` — so the freeze commit stays the one file it claims to be |

**Universal rules:**

1. **Stage only what this run created or edited.** Never `git add -A`, never `git add .`. A blanket add sweeps in build litter, half-registered evidence, and the user's own uncommitted edits.
2. **`wkdrs/` is never committed** (§10). Builds are regenerable and reports are snapshots of a moment; the durable outcome of an audit is the ledger flip and the `tasks/` entry it produced, and those are tracked. A report that feels worth committing is a sign the ledger or `tasks/` entry it should have produced is missing. `.env` is machine-specific and ignored. Everything else the registry (§8) names is tracked — the manuscript, the evidence, the notes, the cycles, `tasks/`.
3. **No pushes, no history rewrites** (`rebase`, `amend`, `reset --hard`), **no branch switches.** The user owns the branch and the remote.
4. **Tag creation is closed.** Exactly one skill creates tags: `stage-subm-packer` creates `freeze/<cycle>_<date>` at pack time. No other skill creates one, and no skill ever deletes or moves one — a freeze tag is the immutable record of what was submitted.
5. **A path that already carried uncommitted changes when the run started is never staged.** Name those paths when asking, so the user can commit or stash them first — a skill's commit must never bundle work it did not do.
6. **Never commit silently.** Every commit is offered as its own question (§7.2). Declining is always a valid answer.

**Why it matters.** `stage-resp-writer` tells reviewers which version they read, and `SUBMISSION_<date>.md` claims "this tag is what went to the portal". Both are only true because commits come from named sessions and tags from exactly one skill.

## 2. The STOP line

Skills may edit text, run builds, and run **light validation**. Anything **heavy, costly, external, or irreversible** crosses the STOP line: prepare the exact command or action, hand it to the user, and stop. Never do it autonomously — no matter how confident the skill is, and no matter that a confirmation point approved the surrounding work.

**Light — a skill may run it:**

- `execs/run.sh` builds and `execs/scpts/lint.sh` checks — a full latexmk compile is this workflow's unit test.
- `execs/scpts/import.sh --diff` staleness reports; `bash -n`; grep scans over `manus/` and `notes/`; `texcount`, `pdfinfo`, bib parsing.
- Rendering a single figure from its `manus/figs/srcs/` source when it finishes in minutes and writes only its own outputs.
- Anything that finishes in **minutes on a laptop** and writes only where the skill is allowed to write.

**Crosses the STOP line — hand it to the user:**

- **Submitting anything anywhere.** Venue portals, arXiv uploads, emails to editors or chairs. The workflow packages under `wkdrs/builds/`; the user uploads. No involve level (§7.7) changes this.
- **Launching experiments.** A missing number is never a reason to run training or evaluation from here — that work belongs to the paired STAR repository and its own STOP line. The writing workflow's whole posture is: a missing number becomes a `\todo{}` and an upstream task (§9a), never a compute job.
- **Deleting or overwriting evidence** under `mates/`, deleting a freeze tag, any git history surgery (§1 bars these outright; confirmation does not unlock them).
- **`sudo` or a system package manager** (apt, brew, tlmgr installs) — a missing tool is a degraded check to report (§3.5), not something to install.
- **Bulk remote fetching** beyond a skill's stated polite rate, and anything billed per call at volume.
- Anything whose cost, runtime, or blast radius **cannot be bounded**. When unsure, it is STOP.

**How to hand off.** Give the user the exact command, invoked through the `.env` environment and `execs/run.sh` where one applies; say what it produces and where; say what to bring back so the result can be verified. Writing the command into a runnable script is light; running it is not.

## 3. `.env` and the build toolchain

The five variables, as `.env.example` ships them:

```bash
# Paired STAR project repo (optional — leave empty when writing without one)
STAR_HOME=
# Build engine: pdflatex | xelatex | lualatex
LATEX_ENGINE=pdflatex
# Submission anonymity mode: when true, lint.sh hunts identity leaks
ANON=false
# Upstream STAGE repo used by execs/update.sh
STAGE_REPOSITORY=https://github.com/wanghao9610/STAGE.git
# Optional. Reply and document language: en | zh; empty = follow the conversation
STAGE_LANG=
```

Four of them are read by the entrypoint scripts. `STAGE_LANG` is the exception: no script reads it, the skills do (§7.6).

1. **`.env` at the repository root is where these values live**, and the precedence is **environment, then `.env`, then the documented default**. Every entrypoint reads the keys it needs out of the file rather than sourcing it, so `STAR_HOME=… bash execs/scpts/import.sh` and `LATEX_ENGINE=xelatex bash execs/run.sh` mean what they say instead of being silently overridden by the file — the order `execs/update.sh` already used for `STAGE_REPOSITORY`, now the same in all four entrypoints. A one-off override is a command-line variable; a lasting one is an edit to `.env`. Never guess a local path, never hardcode one, never read them from memory of another project. `.env` itself is git-ignored and machine-specific.
2. **Every variable has a working default**, so a missing `.env` never blocks a build: `LATEX_ENGINE` falls back to pdflatex, `ANON` to false, `STAGE_LANG` to the conversation's own language. Empty `STAR_HOME` is a supported state — writing without a paired repository — in which `import.sh` requires `--source` and evidence arrives as manual drops. A skill that needs `STAR_HOME` and finds none asks (§7); it never invents a path.
3. **Every build goes through `execs/run.sh`**, which runs latexmk **out-of-tree**: `latexmk -<engine> -interaction=nonstopmode -halt-on-error -outdir=wkdrs/builds manus/main.tex`, engine from `LATEX_ENGINE`. Never run latexmk bare into the source tree: `manus/` stays free of `.aux`/`.log` litter, and every build product is disposable together with `wkdrs/`. On success `run.sh` prints the PDF path and page count; `lint.sh` builds on it for the deterministic checks.
4. **`ANON=true` means the repository is in submission-anonymity mode.** `lint.sh` additionally hunts identity leaks — `\author` contents, acknowledgments, `github.com/<user>`, `\thanks` — and a leak is a hard failure. The venue profile's `anonymized:` records what the venue demands; `ANON` is the operational switch and the user flips it. A skill that finds the two disagreeing says so and asks (§7) rather than silently editing either.
5. **No skill installs anything.** A tool that is absent — latexmk, pdfinfo, texcount, a bib parser — is a **degraded check**: run what can run, name the gap in the report, and give the user the install command (§2 bars running it).
6. **The shell is stateless.** `run.sh` locates the repository root from its own path and works from anywhere; skills resolve paths absolutely and never depend on a prior `cd`.

## 4. Real dates

1. **Every date a skill writes comes from the system clock at run time** (`date +%Y-%m-%d`). Never recall a date, never infer one from context, never copy the one in a template or a schema example (§8's `YYYY-MM-DD` placeholders are placeholders).
2. A typed date names its event: `imported:` is the day the import ran; a review or report date is the day it was written; the `SUBMISSION_<date>` stamp is the day the pack was made.
3. **The one exception is the venue's own calendar.** `abstract_deadline:` and `full_deadline:` are facts about the world, not about this run: they enter `venue.yml` only as user-confirmed values (§9c), and are never derived from the clock, from memory of past years, or from "usually mid-November".
4. A dated file re-generated **the same day** overwrites that day's file; **on a later day** it writes its own. This is what makes a cycle directory readable as a timeline.

## 5. Manuscript, section, and cycle resolution

1. **One manuscript per repository.** `manus/main.tex` is the entry point; there is never a "which paper" question. A second paper is a second instance of the template, not a second tree here.
2. **A section argument resolves against `notes/outline.md`'s Sections table**: by number (`3` matches the `#` column and the `<n>_` filename prefix), by file slug (`method`, `3_method`, or a `manus/secs/…` path), or by title match (case-insensitive substring of the Title column). Before the outline exists, only an explicit filename resolves.
3. **Absent or ambiguous → list the nearest candidates** (number + file + status, one line each) and ask one direct question (§7.2). Never guess which section was meant. `involve=low` does not downgrade this: ambiguity about what the user meant is asked at every level (§7.7).
4. **The active cycle is `cycle:` in `notes/story.md` frontmatter**, naming `cycls/<cycle>/`. An explicit cycle argument overrides it for that run. Neither present → ask, or route to `/stage-stry-coach`, which creates cycles; no skill invents a cycle directory as a side effect.
5. **Never renumber sections in passing.** The `<n>_` prefix is load-bearing: outline rows, the ledger's `Stated in` column, and the `\input` order in `main.tex` are built on it. Renumbering is a deliberate `stage-outl-planner` operation that updates files, outline, `main.tex`, and ledger together — never a drafting side effect.
6. **Files and outline must agree.** A `manus/secs/` file with no outline row, or a row whose file is missing, is drift to report (`stage-flow-status` names it), not something to repair silently mid-task.

## 6. Delegation

1. **Execute locally by default.** Delegate only work that is bounded, independent, and materially helped by delegation. Never create one delegate per trivial sequential step. **Materially helped** has a test: the input is large, the return is small, and what the main agent re-reads afterwards is a spot check rather than the same read again. Where this file or a `SKILL.md` already obliges the main agent to re-open the same evidence — every audited number re-checked at its cited line (§6.5), every reviewer point re-read before it enters the point ledger — a delegate moves that read, it does not remove it, and the work belongs at home. **Where the host offers no delegation at all, this item is the whole of §6**: a step that says *dispatch* still owes its contract, and the main agent fills it locally, in the same order and against the same return format. **A step that may fan out writes its own threshold, as a number, in that step** — the size below which the main agent simply reads it itself. "Many sections" is not something anyone can check; "more than 6 files" is.
2. **A delegate is given** its exact file list, the return contract enumerating its fields and ending with "and nothing else", and its scope stated verbatim ("ONLY these items"). Concurrent delegates hold **disjoint file ownership**, and **at most three run at once** — more pieces go in batches of three. The cap is on how many run at the same time, not on how finely a step may split.
3. **The main agent owns integration and judgment.** It re-runs every check itself and never trusts a self-reported pass. A delegate never grades the overall verdict. A return that reports its own coverage — sections read, reviews parsed, entries checked — is a claim like any other: a count below what that delegate was given is the remainder to re-dispatch, not a smaller result.
4. **Every delegate is read-only.** No STAGE skill carries a dispatch contract for an implementing delegate, so **no delegate changes repository files, full stop** — a subagent reads what it was given (sections, reviews, evidence files, papers) and returns the form it was handed, filled in. One carve-out, and only this one: a subagent that fetches remote payloads (paper pages, bib records) writes them under the `wkdrs/` cache prefix the skill names — one file per item, nothing else — because a fetched record is only re-checkable if the payload is on disk. Cache prefixes of concurrent subagents do not overlap.
5. **A delegate's claim is confirmed before it crosses a confirmation point or causes a write.** A delegate reporting a mismatched number at `mates/<slug>/…#anchor`, an unbacked assertion at a line, or a stale fingerprint has run no check at all: before that claim reaches a question the user answers, a ledger flip, or any file the run changes, the main agent opens the cited location and confirms it holds. What does not hold up is dropped, or demoted to something that changes nothing.
6. **An independent-perspective delegate** — one sent to re-read prose or an audit the main agent produced itself — earns its place only when both hold: the blindness is structural (it cannot see a sentence it never wrote), and the artifact holds up work downstream. Otherwise the main agent checks its own work. This is the one delegate whose reading the main agent still does itself afterwards: the second opinion is the point, not a reading saved. The workflow's institutional form of this is `stage-peer-reviewer` — a skill, not an ad-hoc delegate.
7. **"No subagents" in a `SKILL.md` means it.** That line flattens this whole section to item 1's local path for that skill; no volume of reading makes delegation available there.
8. **The involve level reaches delegation too** (§7.7). At `high`, a fan-out is announced with its partition before dispatch; at `low` it runs unannounced. At every level the decisions record (§7.8) names that the run fanned out and how it partitioned — a partition is a judgment call like any other.
9. **A request budget belongs to the host, not to the agent.** The polite rate a fetching skill states in its `SKILL.md` is spent by the whole session against that host, so N concurrent fetchers make the real rate N times higher. A step that fans out fetching either splits the budget by the number of delegates and writes each share as a number in the brief, or fetches one request at a time and says so.

## 7. Dialogue

The tool-neutral half. **How** to ask — AskUserQuestion, a structured user-input tool, or plain text — is platform-specific and stays in each `SKILL.md`.

1. **Keep each chat reply under about 500 words.** Files written to disk do not count. Detail belongs in the artifact; the reply is the digest.
2. **Ask one question at a time and wait for an explicit answer** before acting on it. Never bundle-approve, never assume a yes. This holds in headless and scripted runs: a skill that reaches a confirmation point stops and waits rather than proceeding.
3. **Every question carries 2–4 concrete options with the recommendation marked**, and the user may always answer freely outside them. **Each option states its consequence, not its label again**: what choosing it produces or changes, what it rules out, and — where the answer is not plainly undoable — whether it can be reverted and at what cost. "Two-column teaser" is a label; "the teaser spans one column, freeing ~0.4 page for §4, and swapping back later means re-flowing the intro" is a consequence. Genuinely open questions (what is the paper's pitch?) may be asked without options.
4. **Report honestly.** Never round a shortfall up. Never present a check as run when it was skipped or degraded — a lint that never ran, a build not attempted, a bib parsed without its parser. Never call a claim `verified` when its status says `drafted`, and never imply a number was traced when it was assumed (§9a).
5. **Lead with the outcome**, then the evidence, then the routing to the next skill.
6. **`STAGE_LANG` sets the language of replies and of what a run writes.** `.env` `STAGE_LANG=en|zh` (§3) fixes both: chat replies, and the Markdown a run newly writes — `notes/`, `tasks/`, simulated reviews, `wkdrs/` reports. Unset, empty, or any other value → follow the user's dialogue language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request beats both and stands for the rest of the run. A skill **resolves it once at the start of the run**, a one-line lookup (`grep -sE '^STAGE_LANG=' .env || true`) folded into the opening load call, never a call of its own. It governs what a run **writes**, never a retranslation of what is already on disk: an existing document keeps the language it was written in, and changing one is an explicit user request, not a side effect of flipping the variable.

   **What stays English whatever `STAGE_LANG` says.** Two things leave this repository to be read by people who did not write them, and both are always English: **everything under `manus/`** — prose, captions, `% src:` comments, the text inside `\todo{}` — and **the response to reviewers** (`cycls/<cycle>/response/`), which a program committee reads. The manuscript's language belongs to the venue and the user; no dialogue language and no `STAGE_LANG` value ever rewrites it. Alongside those, **every structural literal stays English inside a document written in any language**: frontmatter keys and their values, ledger statuses (`proposed` / `drafted` / `verified` / `unsourced` / `weakened` / `dropped`), claim and review-point IDs, file paths, bibkeys and everything from `reference.bib`, venue names, dataset and metric names, and every string a script greps. A Chinese note with English structure stays machine-readable; a translated status value breaks `lint.sh` and every skill that reads the row.
7. **The `involve` level: the user chooses how much is asked.** Every question a workflow poses is one of three kinds. **Mandatory confirmation points** are asked at every level: anything on the STOP line (§2 — submissions above all), every commit offer (§1.6), every confirmation before a deletion or an overwrite, every `venue.yml` value entering as confirmed (§9c), and every ambiguity about what the user meant (§5.3 is the section-name case). **Judgment calls** — questions item 3 equips with a marked recommendation, where every offered option is safe — are what the level moves. **Derivable details** — anything with a conventional default — are decided silently at every level; they were never questions.

   The user sets the level; the skill **resolves it once at the start of the run**, before the first question, from three sources in precedence order: an `INVOLVE=` line the user has added to `.env` (`low` / `medium` / `high`; absent, unset, or invalid → `medium` — the line is optional and `.env.example` does not ship it), then an `involve=<level>` token in the invocation, then plain language mid-run ("ask me less", "ask me everything") — the last instruction wins for the rest of the run. Reading it is a one-line lookup (`grep -sE '^INVOLVE=' .env || true`), resolved once, riding in the skill's opening load call rather than costing a call of its own.

   **The token is not an argument.** `involve=<level>` is stripped from the invocation before anything else is resolved — the section (§5.2), the cycle, the mode. This holds in **every** skill, including ones whose `SKILL.md` never mentions the level: a skill matching its first argument against outline titles must not see `involve=low` and treat it as a section name. A skill that accepts no arguments at all still strips it.

   - `medium` — the default: this file and every `SKILL.md` exactly as written. The level adds nothing.
   - `low` — a judgment call is not asked: take the option you would have marked recommended, and log it (item 8). A genuinely open question has no recommendation to take, so it is asked at every level — and when unsure which kind a question is, treat it as the more interactive kind.
   - `high` — judgment calls the skill's text batches into one confirmation point, or takes autonomously between confirmation points, are asked one at a time (item 2).

   For every question that is asked, item 2 holds unchanged: the level decides which judgment calls are asked at all, never whether an asked question may be assumed answered.
8. **Decide-then-disclose.** Every run keeps a decisions record — inside its durable report where the skill writes one, otherwise a "Decisions taken" list in the final reply — one line per settled question, as `question → choice → what it set`. At `low` it captures every judgment call taken unasked, and the final reply states that count whenever it is nonzero: `low` moves review after the fact, it never removes it. At `medium` and `high` it captures what the user answered, so a long session's decisions outlive the scrollback. Lines are appended as questions settle — a running record, never a growing recap replayed before each question.
9. **The level tightens per skill; it never loosens.** A `SKILL.md` may declare a judgment call it always asks, or flatten levels that make no sense for it (a story-coaching dialogue has no meaningful `low`). No skill treats a mandatory confirmation point as adjustable.
10. **Carry the thread.** A user answering a long series of questions loses the thread. Three cheap habits, deliberately not a recap replayed before every question: **anchor the question** — one clause naming the earlier answer it rests on ("teaser spans one column → §4 gains 0.4 page; now: spend it on the ablation or the qualitative figure?"); **recap at boundaries** — at each section, table, or cycle-stage end, 2–3 sentences on what was decided, what it produced, what it opens next; **name the way back** — when a boundary closes something still changeable, say which skill and argument reopens it and what reopening costs ("budgets can be revisited with `/stage-outl-planner`; after drafting, re-trimming is the cost").
11. **Write the action, not its name.** The reader should never have to decode a term to know what happened, so a name that must appear brings its meaning with it, in the same sentence. This governs the prose a run writes into files as much as chat, and stops at structure: headings, table columns, field names, and every literal a skill matches byte-exactly stay verbatim, with explanation beside them, never in place of them. **A literal that is nothing but a pointer makes that explanation mandatory in chat**: `C4`, `W2`, `§9`, a cycle name — each stays verbatim and takes 3–8 words of what it points at, in parentheses, the first time each reply uses it: `C4 (the zero-shot transfer claim)`, `W2 (reviewer doubts the ablation coverage)`. First use in **each** reply, not once per conversation; later uses inside the same reply stand alone.

## 8. The artifact registry

Every skill's durable output, in one table. `stage-flow-status` reads this as the contract for its coverage checks: a stage is covered when the artifact below exists and its state field is current. Keep the table honest — a skill that changes what it writes updates this row in the same commit, or the status skill silently stops checking that stage.

| Stage | Producer | Path | State field |
|---|---|---|---|
| Adoption | `stage-proj-adopt` | `notes/adopt.md` | `adopted:`, `backfilled:` |
| Evidence | `execs/scpts/import.sh` + `stage-evid-curator` | `mates/<slug>/**`, `mates/manual/**`, ledger `mates/MANIFEST.md` | per entry: `source-type:`, `source-stamp:`, `imported:` |
| Story | `stage-stry-coach` | `notes/story.md` | `finalized:`, `venue:`, `cycle:` |
| Venue profile | `stage-stry-coach` (or `stage-proj-adopt`) | `cycls/<cycle>/venue.yml` | `confirmed:` |
| Claim ledger | `stage-stry-coach` creates; `stage-sect-drafter`, `stage-tabs-builder`, `stage-clms-auditor`, `stage-resp-writer` update | `notes/claims.md` | per-claim `Status` column |
| Outline | `stage-outl-planner` creates; drafter / figs / tabs skills update their rows | `notes/outline.md` + `manus/secs/*.tex` skeletons | `finalized:`; per-row `Status` |
| Notation | `stage-outl-planner` creates; `stage-sect-drafter` appends; `stage-copy-editor` enforces | `notes/notation.md` | `updated:` |
| Section drafts | `stage-sect-drafter` | `manus/secs/<n>_<slug>.tex` | Sections row status in outline |
| Tables | `stage-tabs-builder` | `manus/tabs/<slug>.tex` | per-data-row `% src:` comment; Tables row in outline |
| Figures | `stage-figs-designer` | `manus/figs/<slug>.pdf`, `manus/figs/srcs/<slug>.*` | Figures row in outline |
| References | `stage-refs-curator` | `manus/bibs/reference.bib`, `notes/refs/refs_index.md`, `notes/refs/<ABBREV>.md` | index presence |
| Audit reports | `stage-clms-auditor`, `stage-cite-auditor`, `stage-copy-editor` | `wkdrs/reports/CLAIMS_<date>.md`, `CITES_<date>.md`, `POLISH_<date>.md` (ephemeral) | date in filename |
| Simulated review | `stage-peer-reviewer` | `cycls/<cycle>/reviews/SIM_REVIEW_<date>.md` — the panel meta-review; per-perspective working files in `wkdrs/reports/peer_<cycle>_<date>/` | date in filename |
| Response | `stage-resp-writer` | `cycls/<cycle>/response/RESPONSE_<date>.md`, promises in `tasks/<cycle>_promises.md` | promise checkboxes |
| Submission | `stage-subm-packer` | `cycls/<cycle>/SUBMISSION_<date>.md`, git tag `freeze/<cycle>_<date>`, package under `wkdrs/builds/`, the registered venue template kit at `cycls/<cycle>/template/`, venue follow-ups in `tasks/<cycle>_venue.md` | `frozen:`; venue follow-up checkboxes |
| Status | `stage-flow-status` | — (read-only; reports in chat) | — |

Real reviews from a venue are dropped by the user into `cycls/<cycle>/reviews/` as
`received_<id>.md` (free form); `stage-resp-writer` reads everything in `reviews/`.

**Staleness is exact comparison, never mtime.** A compiled or imported artifact records its source's stamp *as it was when read* — for evidence, the `source-stamp:` in its MANIFEST entry, taken from the first `generated:`/`updated:`/`finalized:` line of the upstream file. Staleness is detected by comparing the current upstream value against the recorded one, byte-exact; file mtimes move for unrelated reasons and are never consulted. `import.sh --diff` implements this for evidence, and `stage-clms-auditor` runs it before trusting any fingerprint.

The file schemas the table points at. A skill that writes one of these files writes exactly this shape; a skill that reads one may rely on it.

### 8.1 `notes/claims.md`

```markdown
---
updated: YYYY-MM-DD
---
# Claim ledger

| ID | Claim | Type | Stated in | Evidence | Status |
|----|-------|------|-----------|----------|--------|
| C1 | <one sentence> | contribution \| performance \| factual | `1_intro`, `abstract`, `tabs/main` | `mates/<slug>/...#<anchor>`; `—` if none | proposed \| drafted \| verified \| unsourced \| weakened \| dropped |
```

Lifecycle: `proposed` (story) → `drafted` (stated in text) → `verified` (clms-auditor matched evidence) / `unsourced` (stated, no fingerprint — must carry `\todo`) / `weakened` (conceded in response) / `dropped`.

### 8.2 `mates/MANIFEST.md` — one `##` entry per file under `mates/`

```markdown
## <slug>/metds/overview.md
- source-type: star            # star | manual
- source: $STAR_HOME/metds/overview.md        # or free text for manual ("results emailed by X, 2026-08-01")
- source-commit: <sha | n/a>
- source-stamp: <first `generated:`/`updated:`/`finalized:` value in source | n/a>
- sha256: <checksum of the file as it landed>
- imported: YYYY-MM-DD
- covers: <one line: what this evidences>
```

`star` entries are managed by `import.sh`; `manual` entries are written by `stage-evid-curator`. Both write all six fields.

The two verification fields answer different questions and neither substitutes for the other. `source-stamp:` is about **upstream**: has the file this was taken from moved on? It is compared against the current upstream value, and `import.sh --diff` needs a reachable source to ask. `sha256:` is about **here**: do the bytes under `mates/` still match what was registered? It needs nothing but the file, so it catches the in-place edit §9d forbids even in a repository with no `STAR_HOME` set, on a machine that has never seen the upstream. A checksum is never quietly recomputed to match a file that changed — that would launder the edit into provenance; it moves only on a re-import or a re-registration.

### 8.3 `cycls/<cycle>/venue.yml` — flat `key: value`, grep-parseable

```yaml
venue: CVPR
year: 2027
cycle: cvpr_2027
template: cvpr                # the class inside the kit at cycls/<cycle>/template/,
                              # so the generated copy says \documentclass{stys/cvpr};
                              # empty or arxiv = ship the preprint form, no conversion
page_limit_main: 8            # content pages
references_in_limit: false
page_limit_supp: 0            # 0 = unlimited
anonymized: true
abstract_deadline: 2026-11-06
full_deadline: 2026-11-13
response_type: rebuttal       # rebuttal | response-letter | none
response_limit: one page      # the venue's official wording
checklist: none               # none | neurips | acl-arr | custom
scale: conference             # review rubric track: conference | journal (missing = conference)
confirmed:                    # date the USER confirmed these numbers; never filled by a skill on its own
```

### 8.4 `notes/story.md`

Frontmatter: `venue:`, `cycle:`, `finalized:`, `updated:`. Sections: `## Pitch` (one sentence), `## Problem`, `## Key idea`, `## Contributions` (each bullet names its claim IDs), `## Venue rationale`.

### 8.5 `notes/outline.md`

Frontmatter: `finalized:`, `updated:`. Three tables:
`## Sections`: `| # | File | Title | Budget (pages) | Claims | Status |`
(status: planned | skeleton | drafted | polished | frozen);
`## Figures`: `| ID | File | Purpose | Section | Source | Status |`
(status: planned | sketch | draft | final);
`## Tables`: `| ID | File | Purpose | Section | Evidence | Status |` (same status scale as figures).

### 8.6 `notes/notation.md`

Frontmatter: `updated:`. `## Symbols`: `| Symbol | Meaning | First defined |`;
`## Terminology canon`: `| Use | Never | Notes |`; `## Abbreviations`: `| Abbrev | Expansion | First use |`.

### 8.7 `notes/refs/<ABBREV>.md` and `refs_index.md`

Note frontmatter: `title:`, `venue:`, `year:`, `bibkey:`, `added:`. Sections: `## What it does`, `## Relation to ours`, `## Citable facts` (facts precise enough for cite-auditor to check assertions against). Index: `| Abbrev | Title | Venue | Year | Bibkey | Note |`.

### 8.8 Reviews and response

`SIM_REVIEW_<date>.md` is the peer-review panel's meta-review, venue-shaped. Frontmatter: `type: peer_review`, `target:`, `cycle:`, `scale:` (conference-6 | journal), `mode:` (panel | quick), `generated:`, `recommendation:`. Sections: `## Summary`, `## Strengths`, `## Major Weaknesses` (numbered; each anchored, naming the claim IDs it attacks and the perspectives that raised it), `## Minor Weaknesses`, `## Questions to the Authors`, `## Limitations & Ethics`, `## Concern Matrix`, `## Recommendation` (anchored band or journal tier, confidence, every triggered cap named), `## Synthesis Notes`. The full templates, the five perspective briefs, and the rubrics live in `stage-peer-reviewer`'s `references/`; per-perspective reviews and the citation audit stay in the run's `wkdrs/reports/peer_<cycle>_<date>/` directory.
`RESPONSE_<date>.md` frontmatter: `cycle:`, `date:`, `sources:` (review files read). Sections: `## Point ledger` `| Point | Reviewer | Attacked claims | Evidence | Response summary | Promise? |`, `## Draft response` (within `response_limit`), and promises mirrored to `tasks/<cycle>_promises.md` as `- [ ]` checkboxes.

### 8.9 `notes/adopt.md`

Frontmatter: `adopted:`, `backfilled:`. Sections: paired sources (STAR repos + slugs), venue target, existing-asset inventory (for adopted projects), the unsourced-claims backlog, backfill actions taken.

`backfilled:` is a gate, not a note (§9a). It stays empty while any backlog row is unresolved, and it is set — to the real date — only by `stage-clms-auditor`, when every row has either become a `verified` claim or an `unsourced` one carrying its `\todo`. `stage-subm-packer` refuses to pack a repository that has a `notes/adopt.md` with an empty `backfilled:`, because that is exactly the state in which `lint.sh` reads clean over numbers that trace to nothing.

### 8.10 `cycls/<cycle>/SUBMISSION_<date>.md`

Frontmatter: `cycle:`, `date:`, `frozen:` (tag name), `package:` (path under `wkdrs/builds/`), `template:` (the venue template the package was formatted in, or `arxiv`). Body: lint summary, checklist outcome, page counts — the converted copy's, with the preprint build's beside it when they differ — what the conversion dropped or left for a human, and what was submitted where.

The same producer's other durable artifact is `tasks/<cycle>_venue.md`, the venue follow-up list a `convert` run maintains. Frontmatter: `cycle:`, `template:`, `updated:`. Body: one `- [ ]` line per finding, each carrying a stable `V<n>` id and the skill that owns the fix. It is updated, never regenerated — a checked item stays checked and is never re-raised, new findings append with the next free id, and an item that no longer applies is checked with its reason rather than deleted. These are findings, not promises: an open box never blocks a pack, which is what separates this list from `tasks/<cycle>_promises.md`.

## 9. The fabrication boundary

A paper is a chain of checkable statements, and a writing agent's cheapest failure is to complete the chain with plausible material. The one property this workflow guarantees is: **nothing in `manus/` is made up.** Not numbers, not what cited papers say, not what the venue demands. Five rules carry that property; the auditors exist to enforce them mechanically, and deadline pressure — the night before, the missing cell, the number everyone "remembers" — is exactly what they are calibrated for.

**(a) Every number in `manus/` either traces to a fingerprinted `mates/` entry or is written as `\todo{...}`. There is no third state.**

- **What counts as a number:** any digit-bearing value whose truth lives outside the manuscript — metrics, deltas, dataset sizes, parameter counts, runtimes, epochs, costs, "3× faster". Not the document's own machinery: section and equation numbers, figure references, citation years, subscript indices. The test is a reviewer asking "source?" — if the honest answer is a measurement or an external fact, the rule applies.
- **Trace means the full chain.** In a table: the cell → its row's `% src: mates/<...>#<anchor>` comment → a fingerprinted MANIFEST entry → the value present in that evidence file. In prose: the sentence → the ledger row stating it (`Stated in` names this section) → the row's `Evidence` link → the fingerprint. `stage-clms-auditor` walks both chains for every number and verdicts each **matched / mismatched / unsourced**.
- **A `% src:` comment covers exactly one sentence.** In `manus/tabs/` the unit is already unambiguous — one comment per data row, never shared, never blanket. In prose the unit is the **sentence the comment heads**: it starts at the first word after the comment and ends at that sentence's terminator, however many source lines the sentence wraps across. Two numbers in one sentence share its comment; a number in the next sentence needs its own. This is not pedantry — scope by line and scope by sentence give different verdicts on the same manuscript, and an audit is mechanical only where the unit is fixed.
- **The todo discipline, concretely:**

  ```tex
  % In manus/tabs/main_results.tex — every data row names its source;
  % a missing cell is a \todo, and the comment says what unblocks it:
  OVSeg  & 24.8 & 53.3 \\  % src: mates/xseg/wkdrs/results/results.md#tab-main
  Ours   & \todo{A-847 — import STAR results first} & 54.6 \\  % src: mates/xseg/wkdrs/results/results.md#tab-main

  % In manus/secs/4_expts.tex — prose numbers trace through the ledger,
  % so a not-yet-imported delta is a \todo, never a recalled value:
  improves mIoU by \todo{delta vs. OVSeg — awaiting results import} on ADE20K.
  ```

- **A remembered number is an unsourced number.** Typing `54.6` from memory of a wandb screen, a meeting, or the STAR repo you did not import is fabrication *even when the number is right* — the property being protected is checkability, not luck. The honest forms are the `\todo{}` above, or registering the origin as manual evidence (see e) so the number traces.
- **Camouflage is worse than fabrication.** `XX.X`, `TBD`, `99.9`, `\textbf{54.6}` as a "temporary" placeholder — anything that marks a hole without the `\todo{` macro is invisible to `lint.sh`'s count and will survive to a submitted PDF. One macro, greppable, red in every draft build: that is the whole point of `stage.sty` shipping it, and the fresh-clone `main.tex` compiles with one `\todo{}` precisely so the machinery is demonstrated on day one.
- **Derived numbers inherit the rule.** A delta or an average traces when every operand traces and the derivation is named in the same `% src:` comment (`% src: delta of rows 2,5 — mates/xseg/.../results.md#tab-main`). One untraceable operand makes the derived number unsourced. Rounding is presentation — a sourced 54.62 may appear as 54.6; changing any digit is not rounding.
- **A `\todo` leaves the manuscript in exactly two ways:** replaced by a value that traces (the import happened, the fingerprint exists), or the sentence is rewritten to not need the value. Deleting the macro and keeping its content is fabrication with extra steps.
- **The marker is for a missing value, not for a thin section.** A paragraph that is merely underwritten, a method whose hyperparameters nobody has written down, an experiment section waiting on prose — none of these is a `\todo`. They are an outline status and a `tasks/` item. The distinction is load-bearing because `lint.sh` cannot see it: a content note parked in a marker blocks the pack exactly as hard as an invented metric would, and the author learns to read a red gate as noise. Marker for values; `tasks/` for everything else.
- **An adopted draft starts outside this rule, and the gap is named rather than hidden.** `stage-proj-adopt` books every number a pre-existing manuscript already states as a row in `notes/adopt.md`'s unsourced backlog. It does not wrap them in `\todo{}` — it has no idea which are right, and rewriting somebody's results as markers is not adoption. So until `stage-clms-auditor` has worked that backlog down, those numbers *are* the third state this rule forbids, and `lint.sh` — which counts markers — reads the manuscript as clean while none of its numbers traces. That is the one moment the mechanical gate and the property diverge, so the backlog is a gate in its own right: `notes/adopt.md`'s `backfilled:` stays empty until every row is resolved, and `stage-subm-packer` refuses to pack an adopted repository while it is (§8.9).
- **Enforcement:** `lint.sh` counts `\todo{` occurrences that LaTeX would actually typeset — each candidate line has its comment stripped from the first unescaped `%` before the test, so a commented-out marker, or a comment naming the macro, is not a failure — and nonzero is a hard failure that `stage-subm-packer` refuses to pack over; `stage-clms-auditor` traces every number and opens a `tasks/` item per failure; every known-but-unfingerprinted value carries an `unsourced` ledger row so the debt has a name.

**(b) Every assertion about a cited paper must be checkable against a reading note** (`notes/refs/<ABBREV>.md` or imported refs under `mates/`).

- **Checkable** means the note's `## Citable facts` holds a fact precise enough to decide the sentence. "ODISE reaches 23.4 PQ on ADE20K" needs that number in ODISE's note; "unlike [X], we require no box supervision" needs X's note to state that X requires box supervision. A bib entry alone backs nothing: it proves the paper exists, not what it says.
- Grouped citations assert too: "[A,B,C] rely on frozen backbones" asserts it of each of A, B, and C, and each needs the fact in its note.
- **The fix for an unbacked assertion is never to soften it into vagueness** — a vague mispositioning of related work is still false. The honest paths: read the paper and write the note (`/stage-refs-curator`), mark it `\todo{verify: does X require box supervision?}`, or drop the assertion. `stage-cite-auditor` flags unverifiable assertions in its report; it never silently "fixes" prose, because a silent fix is an unreviewed claim change.
- **Review artifacts extend this rule beyond the manuscript.** A simulated review (`stage-peer-reviewer`) may name a work the manuscript does not cite only under its citation-integrity contract: the reference is **whitelist** (already in `manus/bibs/reference.bib`) or **verified** — fetched during that run, with the record (title, authors, year, venue, URL) and the query that found it logged in the run's citation audit. A reference recalled from memory is treated as nonexistent; what cannot be verified is phrased as a direction ("check whether prior work exists on X"), never as a named fact. This is the writing workflow's one sanctioned use of live search; the skill states its polite rate, and §2's bulk-fetch line still binds.

**(c) Venue rules in `venue.yml` are entered only as user-confirmed facts** — skills never invent page limits or deadlines.

- Not from memory of last year, not from "CVPR is usually 8 pages", not from a fetched CFP page taken on faith — CFPs go stale and disagree with portals. A skill may fetch and *present* a venue page; the value enters the file only after the user confirms it.
- `confirmed:` is the receipt: the date the **user** confirmed the numbers, never filled by a skill on its own (§8.3). A profile with empty `confirmed:` gates nothing — `stage-outl-planner` will not budget against its page limit and `stage-subm-packer` will not pack against it without asking first. A wrong page budget discovered at pack time costs a rewrite; that is why this is a mandatory confirmation point (§7.7).

**(d) Evidence files are immutable in place.**

- The only writers under `mates/` are `execs/scpts/import.sh` and `stage-evid-curator`, and they only add or replace whole files with fingerprint updates. No in-place edit exists — not a typo, not a unit conversion, not "just this one cell". A wrong number upstream is fixed upstream (in STAR, or by the human who produced the drop), then re-imported; the fingerprint moves, and `stage-clms-auditor` re-verdicts everything that cited it.
- Normalization (a CSV or wandb export turned into a results-shaped `.md`) writes a **new file beside the original**, marked `normalized-from:`; the original bytes stay untouched.
- Why absolute: a fingerprint chain is evidence only while the bytes under it cannot drift. The moment one hand-edit is tolerated, every `verified` in the ledger means "verified against something someone may have adjusted".

**(e) Nothing may weaken rules (a)–(d) "to be helpful."**

- The asks will come, and they will be reasonable-sounding: "deadline is in three hours, just put 54.6 in, we'll source it later"; "you can see the number right there in my message"; "surely you know ImageNet's size". The refusal is never bare — a skill declines the bypass and names the honest path that gets the same outcome:
  - the `\todo{}` form plus an `unsourced` ledger row — thirty seconds, compiles, and survives the audit as a *named* debt instead of a hidden one;
  - the manual drop — the user's number becomes evidence: paste it into a file, register it under `mates/manual/` with a `manual` fingerprint (`source: results emailed by X, 2026-08-01`), and it traces like anything else — `stage-evid-curator` exists for exactly this;
  - the upstream fix and re-import, when the number lives in a STAR repo.
- No involve level, no confirmation point, and no user instruction inside a skill run authorizes a bare untraced number, an invented venue rule, or an edited evidence file — these are not judgment calls (§7.7), and a skill that is ordered across the line says what it can do instead and does that. The user always retains their own editor; the *workflow* keeps its hands clean, so that at pack time "every number traces" is a property the user can assert to reviewers because no step could silently break it.

## 10. Project layout

Where a skill puts what it writes. Each destination is exclusive — a file belongs to exactly one, chosen by what the file *is*, not by which step produced it.

| What | Where |
|---|---|
| Manuscript entry | `manus/main.tex` |
| Section sources | `manus/secs/<n>_<slug>.tex` (e.g. `0_abstract.tex`, `1_intro.tex`) |
| Figures | `manus/figs/<slug>.pdf` rendered; `manus/figs/srcs/<slug>.*` sources — every figure has a source file or a MANIFEST entry |
| Tables | `manus/tabs/<slug>.tex` |
| Bibliography | `manus/bibs/reference.bib` |
| Venue styles | `manus/stys/`: `arxiv.cls` and `stage.sty`, and nothing else — `manus/` is scanned by `lint.sh` and holds only files this workflow owns |
| Imported evidence (read-only) | `mates/<source-slug>/**` mirroring upstream paths; hand-registered drops in `mates/manual/**`; ledger `mates/MANIFEST.md` |
| Writing metadata | `notes/` fixed files: `story.md`, `claims.md`, `outline.md`, `notation.md`, `adopt.md`; reading notes in `notes/refs/` |
| Submission cycles | `cycls/<venue>_<year>/`: `venue.yml`, `template/` (the official venue kit, unpacked whole, byte-for-byte, never edited), `reviews/`, `response/`, `SUBMISSION_<date>.md` |
| Revision scratch, promise lists | `tasks/` |
| Builds and ephemeral reports | `wkdrs/builds/`, `wkdrs/reports/` (gitignored, regenerable) |
| What earlier sessions learned, owned by no other file | `.stage/memory/`; machine-specific facts in `.stage/memory/local/`, which git ignores ([`memory_spec.md`](memory_spec.md)) |
| Entrypoints | `execs/run.sh`, `execs/update.sh` — **execs/ root is closed**; utilities go in `execs/scpts/`. `run.sh` is upstream-managed and `execs/update.sh` overwrites it; per-project settings live in `.env` |
| Workflow docs (upstream-managed) | `docs/mds/stage-workflow/` |

Rules the table alone does not carry:
1. **`mates/` is read-only.** `import.sh` and `/stage-evid-curator` are the only writers, and they
   only add/replace whole files with fingerprints. Content fixes happen upstream, then re-import.
2. **`wkdrs/` is never committed.** Durable audit outcomes live as status flips in `notes/claims.md`
   and entries in `tasks/`, not in reports.
3. **`execs/` root is closed** (STAR's rule): `run.sh` + `update.sh` and nothing else.
4. **The manuscript always compiles as the preprint; a venue's format is a generated copy.**
   `manus/stys/` holds two layers and the split is load-bearing: `arxiv.cls` owns the look and is
   what a venue class replaces; `stage.sty` owns `\todo` plus the macros skills write into `secs/`
   and `tabs/` (`\parahead`, `\cmark`, `\tablestyle`, `\figref` …) and survives every swap.
   Project-specific macros go in `main.tex`, never in `stys/`. An official venue kit unpacks whole
   and unedited into `cycls/<cycle>/template/`, beside that cycle's `venue.yml` — never under
   `manus/`, a scanned namespace where a kit's example `.tex` would trip `lint.sh`'s `\todo` count
   and its identity-leak scan. `template:` in `venue.yml` names the class inside the kit;
   `stage-subm-packer convert` reads it and regenerates a standalone copy under `wkdrs/` that
   compiles under that class. `manus/main.tex` keeps its `\documentclass{stys/arxiv}`: there is no
   in-place swap and no second source of truth.
5. **The four harness trees are copies, not alternatives.** The same fifteen skills ship once per
   harness — `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.kimi-code/skills/` —
   differing only in invocation prefix and tool names (`Bash` / `Shell`, `AskUserQuestion` /
   `AskQuestion` / `request_user_input`, `Read` / `ReadFile`). Load the copy under your own root and
   follow it; a listing that surfaces another root's copy is telling you where a file is, not which
   one binds you.

## 11. The skill roster

Fifteen skills, invoked as `/stage-<name>` in Claude Code and Cursor, `$stage-<name>` in Codex, `/skill:stage-<name>` in Kimi Code. What each one does in full is [writing-workflow-skills.md](writing-workflow-skills.md); what each one writes is §8.

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
| `stage-subm-packer` † | preflight, venue conversion, package, freeze |
| `stage-flow-status` | read-only status and the one next action |

1. **The five marked † are slash-only.** Run them only when the user names them: they are the decision points — adoption, story, outline, response, submission — and a decision point reached on an agent's own initiative is a decision nobody made. This table is the source of truth; the guards enforcing it are `disable-model-invocation: true` in the Claude, Cursor, and Kimi manifests and `allow_implicit_invocation: false` in `.agents/skills/<name>/agents/openai.yaml` for Codex, and CI checks all four against these markers, so marking a skill here without guarding it everywhere fails the build.
2. **Two skills never touch the manuscript.** `stage-peer-reviewer` writes only its review under `cycls/<cycle>/reviews/`; `stage-flow-status` writes nothing at all. Run the status skill first whenever you do not know where things stand — it reads the outline, the ledger, the manifest, and the cycle state, and names the single next action with its exact command.
3. **One skill per invocation, and one unit of work inside it.** A section, a table, a figure, a response — a run that quietly widens its scope is the failure this rule exists for; the next unit is the next invocation.
