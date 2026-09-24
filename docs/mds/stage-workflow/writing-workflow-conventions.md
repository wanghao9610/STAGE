# Writing Workflow Skill Conventions

The rules every STAGE writing workflow skill follows. The sixteen skills — `stage-proj-adopt`, `stage-evid-curator`, `stage-stry-coach`, `stage-outl-planner`, `stage-sect-drafter`, `stage-tabs-builder`, `stage-figs-designer`, `stage-refs-curator`, `stage-copy-editor`, `stage-clms-auditor`, `stage-cite-auditor`, `stage-peer-reviewer`, `stage-resp-writer`, `stage-subm-packer`, `stage-pstr-builder`, `stage-flow-status` — each carry their own workflow, their own limit on what they may write, and their own rubric. What they share lives here, once. There is no section-selective loading: **every skill reads this whole file at the start of every run.**

**Precedence.** This file is the **baseline**. A skill's `SKILL.md` may be **stricter** — a narrower set of files it may write, a lower threshold, an extra confirmation point, a rule that it never commits at all — and the stricter rule wins. A skill never loosens what this file sets. Stricter wording alone is not a fresh approval requirement: an explicit approval the user already gave stays valid within its scope, and a confirmation point needs a new answer only when its decision or authority is still missing (§7.2) — except a mandatory confirmation point (§7.7), which only its own answer settles, and the fabrication boundary (§9e), which no approval moves. Where a `SKILL.md` carries a one-line summary of a rule below, that line is the binding reminder and this file is the full rule. Skills cite these sections as "conventions §n"; the numbers are frozen and never renumbered.

This file is a set of conventions for the skills and a description for the reader: it is what the workflow will and will not do to your manuscript.

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
| what it may write | the paths a skill, or a subagent it dispatches, may create or edit — and nothing outside them | §6, §8 |
| fallback | the route taken when the first choice returns nothing | §6, §13 |
| fan-out | several subagents, run concurrently or in turn as the main agent judges, reading and writing files that do not overlap | §6 |
| style profile | `notes/style.md`: the author's prose preferences as dials a run applies and a report measures; binds `manus/` prose only | §8 |
| cycle | one submission attempt at one venue: `cycls/<venue>_<year>/` and everything in it | §5, §8 |
| active cycle | the cycle skills act on: `cycle:` in `notes/story.md` frontmatter | §5 |
| venue profile | `cycls/<cycle>/venue.yml`: the venue's rules, entered only as user-confirmed facts | §8, §9 |
| freeze | the git tag `freeze/<cycle>_<date>` marking exactly what was submitted; only `stage-subm-packer` creates one | §1 |
| promise | a change committed to in a response, a `- [ ]` box in `tasks/<cycle>_promises.md` until kept | §8 |
| `\todo{...}` | the red, bold, greppable macro from `manus/stys/stage.sty` marking every value the manuscript does not yet source | §9 |
| staleness | an imported file whose upstream stamp no longer matches its recorded fingerprint; detected by exact comparison, never mtime | §8 |

## 1. Git

**The discipline is one commit per skill working session** — never unannounced, staging only that session's work, with the subject prefix naming the skill: `stage-sect-drafter: 3_method — first full draft`, `stage-evid-curator: import xseg results`. One skill, one prefix, so the log separates by skill.

**Skills that never commit** — three, for different reasons. `stage-flow-status` writes nothing at all, so its git usage is read-only (`status` / `diff` / `log`). `stage-evid-curator` writes plenty under `mates/` — imports, registrations, the manifest — and still never commits: evidence is what every number in the manuscript is measured against, so what enters that store sits in `git status` for the user to review and commit themselves. `stage-proj-adopt` writes plenty — file moves, the tex edits those moves force, the adoption record — and still never commits: adoption rearranges a manuscript somebody else built, and reviewing that rearrangement is not a skill's to skip. `git mv` stages the renames it performs and nothing else is added; the commit is the user's.

**Skills that may commit**, and what each may stage:

| Skill | Commits | Stages |
| --- | --- | --- |
| `stage-stry-coach` | offered once when the session ends | `notes/story.md`, the seeded `notes/claims.md`, the cycle's `venue.yml` when created |
| `stage-outl-planner` | offered once when the session ends | `notes/outline.md`, `notes/notation.md`, new `manus/secs/` skeletons, the `\input` edits in `manus/main.tex` |
| `stage-sect-drafter` | offered once per drafted section | that section's `.tex`, plus its ledger, notation, and outline updates |
| `stage-tabs-builder` | offered once when the session ends | the tables written, plus their outline and ledger updates |
| `stage-figs-designer` | offered once when the session ends | `manus/figs/` renders, `manus/figs/srcs/` sources, outline updates |
| `stage-refs-curator` | offered once when the session ends | `manus/bibs/reference.bib`, `notes/refs/` notes and index |
| `stage-copy-editor` | offered once after the pass | only the `.tex` files the pass edited and `tasks/polish_followups.md`, or `notes/style.md` alone after a `style` run — the polish report stays in `wkdrs/` |
| `stage-clms-auditor` | offered once after the audit | `notes/claims.md` status flips, the new `tasks/` items, and `notes/adopt.md` when the run set its `backfilled:` — the audit report stays in `wkdrs/` |
| `stage-cite-auditor` | offered once after the audit, when it filed follow-ups | `tasks/cites_followups.md` — findings stay in the `wkdrs/` report, and the bib is read-only here: a bib repair routes to `stage-refs-curator` |
| `stage-peer-reviewer` | offered once per review, and never on an `extern=` run | the one `SIM_REVIEW_*` file it wrote. A referee report on an external paper is not a repository artifact and is not staged |
| `stage-resp-writer` | offered once when the session ends | the `RESPONSE_*` file, `tasks/<cycle>_promises.md`, ledger downgrades |
| `stage-subm-packer` | one at pack time; one more when a `convert` run registers a venue template kit | `cycls/<cycle>/SUBMISSION_<date>.md`; the `freeze/<cycle>_<date>` tag then lands on that commit — the package itself stays in `wkdrs/builds/`. The `convert` commit is separate and stages only what that run wrote outside `wkdrs/` — the kit under `cycls/<cycle>/template/` and `tasks/<cycle>_venue.md` — so the freeze commit stays the one file it claims to be |
| `stage-pstr-builder` | offered once when the session ends | `cycls/<cycle>/poster/POSTER_PLAN.md`, `poster.tex`, and, when a kit was supplied, the registered kit under `cycls/<cycle>/poster/template/` with the `poster_template:` line it recorded in `cycls/<cycle>/venue.yml` — the render stays in `wkdrs/builds/poster/` |

**Universal rules:**

1. **Stage only what this run created or edited.** Never `git add -A`, never `git add .`. A blanket add sweeps in build litter, half-registered evidence, and the user's own uncommitted edits.
2. **`wkdrs/` is never committed** (§10). Builds are regenerable and reports are snapshots of a moment; the durable outcome of an audit is the ledger flip and the `tasks/` entry it produced, and those are tracked. A report that feels worth committing is a sign the ledger or `tasks/` entry it should have produced is missing. `.env` is machine-specific and ignored. Everything else the output table (§8) names is tracked — the manuscript, the evidence, the notes, the cycles, `tasks/`.
3. **No pushes, no history rewrites** (`rebase`, `amend`, `reset --hard`), **no branch switches.** The user owns the branch and the remote.
4. **Tag creation is closed.** Exactly one skill creates tags: `stage-subm-packer` creates `freeze/<cycle>_<date>` at pack time. No other skill creates one, and no skill ever deletes or moves one — a freeze tag is the immutable record of what was submitted.
5. **A path that already carried uncommitted changes when the run started is never staged.** Name those paths when asking — or, at `low`, in the final reply — so the user can commit or stash them first; a skill's commit must never bundle work it did not do.
6. **Never commit unannounced.** A commit offer is a judgment call (§7.7), and the answer it recommends is to commit: a local commit publishes nothing, and one made at the wrong moment costs a `git reset --soft`. `medium` and `high` ask it as its own question (§7.2) while commit authority for this run's files is still missing, and declining is always valid; an explicit instruction to commit them — "and commit it" in the invocation — already answered it, and the same approved commit scope is never asked again. `low` takes it unasked. Either way the final reply names every commit made, with its message and file count — the levels that ask keep their veto, the level that does not keeps its review. With nobody reading the file list at `low`, rule 5 carries the weight alone: snapshot `git status` at the start of the run, and never stage a path already dirty in it.

**The guard.** Every tool tree ships a `stage_commit_guard.sh` hook that declines the commands breaking these rules where the break is expensive to undo: blanket or forced staging (`add -A`, `add .`, `add -u`, `add -f`, `commit -a`), the history rewrites rule 3 names (`commit --amend`, `rebase`, `reset --hard`, `filter-branch`, `filter-repo`), the forced branch operations that discard work in one keystroke (`branch -D`/`-f`, `switch -C`/`-f`, `checkout -B`/`-f`), any deletion or move of a tag (rule 4 — a freeze tag is what `SUBMISSION_<date>.md` points at), and any commit whose staged files exceed 10 MB, since clearing a build PDF or a figure blob back out of history needs exactly those rewrites. `push` is deliberately absent: nothing here makes a skill likelier to push, and a user who asks for one directly should get it. The guard is a last check behind the prose, never a replacement for it — it reads one shell line at a time and cannot resolve quoting, and silence is its answer to anything it cannot read confidently. What it declines is the user's to run.

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

The ten variables, as `.env.example` ships them:

```bash
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
# Optional. Model for each tier: PLAN | EXEC | READ; empty = nothing changes
STAGE_PLAN_MODEL=
STAGE_EXEC_MODEL=
STAGE_READ_MODEL=
```

Five of them are read by the entrypoint scripts. The other five no entrypoint reads; the skills do — `STAGE_LANG` and `INVOLVE` (§7.6, §7.7) and the three tier keys (§11.6) — and `INVOLVE` is read once more by the harness hooks that answer a permission prompt at `low` (§7.7).

1. **`.env` at the repository root is where these values live**, and the precedence is **environment, then `.env`, then the documented default**. Every entrypoint reads the keys it needs out of the file rather than sourcing it, so `STAR_HOME=… bash execs/scpts/import.sh` and `LATEX_ENGINE=xelatex bash execs/run.sh` mean what they say instead of being silently overridden by the file — the order `execs/update.sh` uses for `STAGE_REPOSITORY` and `STAGE_HARNESSES`, now the same in all four entrypoints. A one-off override is a command-line variable or `--harnesses`; a lasting one is an edit to `.env`. Never guess a local path, never hardcode one, never read them from memory of another project. `.env` itself is git-ignored and machine-specific.
2. **Every variable has a working default**, so a missing `.env` never blocks a build: `LATEX_ENGINE` falls back to pdflatex, `ANON` to false, `STAGE_LANG` to the conversation's own language, and an empty tier key to the model the run already has (§11.6). Empty `STAR_HOME` is a supported state — writing without a paired repository — in which `import.sh` requires `--source` and evidence arrives as manual drops. A skill that needs `STAR_HOME` and finds none asks (§7); it never invents a path.
3. **Every build goes through `execs/run.sh`**, which runs latexmk **out-of-tree**: `latexmk -<engine> -interaction=nonstopmode -halt-on-error -outdir=wkdrs/builds manus/main.tex`, engine from `LATEX_ENGINE`. Never run latexmk bare into the source tree: `manus/` stays free of `.aux`/`.log` litter, and every build product is disposable together with `wkdrs/`. On success `run.sh` prints the PDF path and page count; `lint.sh` builds on it for the deterministic checks.
4. **`ANON=true` means the repository is in submission-anonymity mode.** `lint.sh` also hunts identity leaks — `\author` contents, acknowledgments, `github.com/<user>`, `\thanks` — and a leak is a hard failure. The venue profile's `anonymized:` records what the venue demands; `ANON` is the operational switch and the user flips it. A skill that finds the two disagreeing says so and asks (§7) rather than silently editing either.
5. **No skill installs anything.** A tool that is absent — latexmk, pdfinfo, texcount, a bib parser — is a **degraded check**: run what can run, name the gap in the report, and give the user the install command (§2 bars running it).
6. **The shell is stateless.** `run.sh` locates the repository root from its own path and works from anywhere; skills resolve paths absolutely and never depend on a prior `cd`.
7. **The manuscript reads one sentence per line.** LaTeX collapses a newline to a space, so where a sentence breaks costs the PDF nothing and buys a per-sentence diff, a per-sentence blame, and — the reason this workflow cares — a fixed two-line shape for a `% src:` comment and the sentence it heads (§9a). A skill writing under `manus/` starts each sentence on its own line and never wraps at a column. `bash execs/scpts/fmt.sh` makes an existing file match and `--check` reports drift; `lint.sh` carries that as a **warning, never a hard failure** — where a line breaks cannot move a page, a reference, or a todo count, so it must not block a submission. The rule itself lives in `.latexindent.yaml` at the repository root, which the script and the editor both read, and two trees are exempt because their bytes are somebody else's: `manus/stys/` and any kit under `cycls/*/template/` (§10.4). **A rewrite that would change the typeset text is refused and the file left alone.** The tool's sentence detector is not perfect — a lowercase abbreviation before a capital (`std.`, `et al.`) can be read as a sentence end — so every rewrite is compared against the original with each whitespace run collapsed to one space, which is exactly what TeX does; a file that fails that comparison is reported, never written. The fix is in the prose (`et al.\ `, `Fig.~\ref{...}`), never a loosened rule. What the prose says, as opposed to where its lines break, is §7's human-writing contract.

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

1. **Fan out wherever the work splits.** Delegation is the default shape of a run whose pieces are independent — they read different files, or write different files, and none needs another's result before it can start. One delegate per piece; which go out together, and in what order, is the main agent's call (item 2), and the ones it runs at once go out in a single message, because where each dispatch waits for its delegate to return, dispatches sent one per turn run one after another. **The main agent decides, and it decides alone**: no file in this repository asks the user for permission first, because fanning out is a way of doing the work rather than a change to what the work is, and a run that stops to ask whether it may go faster has spent the time it was trying to save. What stays in one context is what a split would break: steps that feed each other, and a judgment that needs the whole picture in front of it at once. **Where the host offers no delegation at all, this item is the whole of §6** — a step that says *dispatch* still owes its return, and the main agent fills it locally, in the same order and against the same return format, with the digest saying the run went local. Same answer where the host carries a dispatch tool but refuses the call: fall back, finish the work, and say in the digest which fan-out did not fire. **A step that fans out writes its own threshold, in a form a reader can check, in that step** — the size below which the main agent simply does it itself. A number does it ("more than 6 files"); so does a condition on the material ("one delegate per section file", "until a sweep returns nothing new"). "Many sections" does neither, and is what this rules out.
2. **A delegate is given** its exact file list, the return contract enumerating its fields and ending with "and nothing else", and its scope stated verbatim ("ONLY these items"). **Concurrent delegates hold disjoint file ownership.** That one does not relax and it is not an audit rule: two agents editing one file lose each other's edits, and nothing downstream recovers a write that was overwritten — so a delegate that writes owns its files alone for the length of the fan-out, and a partition that hands one file to two delegates is a defect, not a tighter schedule. **Order and concurrency are the main agent's call**: pieces go out concurrently or in turn as it judges, as many at once as the work warrants rather than a fixed ceiling, in no order beyond their dependencies. The most it will run at once is fixed before the first dispatch and written down, because item 9 multiplies each fetcher's wait by it.
3. **The main agent owns integration.** It assembles the returns, resolves what two of them disagree about, and runs the deterministic gates itself — `execs/run.sh` and `execs/scpts/lint.sh` — because those are mechanical, cheap, and catch what no self-report can: an unresolved reference, a `\todo` count, a page over budget. **It does not re-read what a delegate read.** That is what buys the fan-out, and the cost is stated here rather than discovered later: a delegate's own account of its coverage — sections read, entries checked — is what the run has, so a count below what that delegate was given is the remainder to re-dispatch rather than a smaller result, and a return that contradicts a gate loses to the gate.
4. **A delegate may write, inside its scope, under every rule that binds whoever writes.** Delegation moves work; it never lowers the bar for what the work may produce, and each rule follows the writer rather than staying with the main agent. §9's fabrication boundary binds the delegate that writes the sentence: a number reaching `manus/` carries the `% src:` anchor of the `mates/` entry that delegate opened this run, or it is a `\todo{}` — there is no third state for a delegate either. §8's formats bind every row it writes, and `mates/` is read-only for everyone (§10). Two things stay with the main agent for reasons that have nothing to do with trust: **git**, because concurrent `git add` and `git commit` race on one index, so the run's single commit (§1) is the main agent's; and **the conversation**, item 5.
5. **Confirmation points belong to the main agent, because the user is talking to it.** Everything on the STOP line (§2), the commit offer where the level asks it (§1.6), every confirmation before a deletion or an overwrite, every `venue.yml` value entering as confirmed (§9c), the provenance question before a file is registered as evidence (§9e), each confirmation point where a slash-only skill settles its decision (§11.1), and every ambiguity about what the user meant (§5.3) — a delegate neither poses these nor answers them, and a piece of work whose next step is one of them comes back before that step is taken.
6. **An independent-perspective delegate** — one sent to re-read prose or an audit the main agent produced itself — is worth dispatching whenever the artifact holds up work downstream: the blindness is structural, and a second reading is the one thing the author of a sentence cannot supply about it. This is the delegate whose reading the main agent repeats rather than replaces, because the second opinion is the point and not a reading saved. The workflow's institutional form of it is `stage-peer-reviewer` — a skill, not an ad-hoc delegate.
7. **No skill withholds delegation.** No `SKILL.md` bans the dispatch tool, and none may: a skill with nothing to fan out says so by naming no fan-out point, never by refusing one. Where a skill's own text holds a step at home — an interview the user is sitting in, a gate that is one script call, a read that finishes before a delegate would return — that is item 1's threshold stated in the direction that happens to be "not here", and it names why.
8. **The involve level reaches delegation too** (§7.7). At `high`, a fan-out is announced with its partition before dispatch; at `medium` and `low` it runs unannounced. At every level the decisions record (§7.8) names that the run fanned out and how it partitioned — a partition is a judgment call like any other.
9. **Fetching divides the rate.** A polite rate is a promise to someone else's server, and the whole session spends it against that host — so N concurrent fetchers would break the promise N times over, and splitting a request quota does not repair it, because a quota bounds a total and politeness is a rate. The repair is arithmetic and it lives in the brief: **every delegate that fetches is told, as a number of seconds, how long to wait between its own requests to a host — the host's own interval multiplied by the most delegates this fan-out runs at once** (item 2's number, fixed before the first dispatch). Three readers at once against a host asking one request every 3 seconds each wait 9, and the aggregate is what a single fetcher would have produced. The seconds are written in; "be polite" is not a rate. Every payload is cached under that delegate's own prefix in the run directory before it is read — a payload nobody can re-open has evidenced nothing, and passing whole documents back through the return format would undo the reason for fanning out — one prefix per delegate, so no two of them write to the same place (item 2). What it costs is stated where it is granted: politeness now rests on a wait nobody observes.
10. **Which model a delegate runs on is §11.6's rule, not this section's.** The three `.env` tier keys decide it — a pure collector on READ, a delegate that writes files (item 4) on EXEC, an independent-perspective delegate (item 6) on PLAN. An empty key leaves delegation exactly as items 1–9 describe.

## 7. Dialogue

The tool-neutral half. **How** to ask — AskUserQuestion, a structured user-input tool, or plain text — is platform-specific and stays in each `SKILL.md`.

### Human-writing contract

Manuscript prose — what `stage-sect-drafter` drafts, `stage-copy-editor` polishes, and `stage-peer-reviewer`'s clarity perspective reviews — reads as clear scholarship in the author's voice, without formulaic language that inflates a claim, hides a source, or simulates significance. The aim is clear prose, not authorship detection or detector evasion: a formulaic-prose finding is an advisory review signal that neither establishes that AI produced the text nor authorizes changing what the paper claims so the wording appears human. §9 and the ledger outrank this contract, and a skill's stricter rule wins.

**Preserve content and provenance.** Read the controlling records first — `notes/story.md`, `notes/outline.md`, `notes/claims.md`, the mapped `mates/` evidence, `notes/refs/`, `notes/notation.md`, `notes/style.md`, and the active venue and anonymity rules — and report a conflict among them instead of resolving it in prose. A style edit may reorder, merge, split, or shorten, and never changes a fact, number, math, citation or key, label, LaTeX, `% src:` comment, `\todo{}`, canonical term, claim strength or scope, attribution, comparison set, condition, technical distinction, uncertainty boundary, or required qualifier. Missing support stays visible as a `\todo{...}` or a routed task, never a plausible value, source, or fact, and nothing gains personality or concrete detail without authorial and evidential support. A revision that adds, removes, moves, weakens, or strengthens a claim is not style-only: it goes through the owning workflow and updates `notes/claims.md` in the same change.

**Match the writer.** Follow an author-confirmed sample where one exists (§8.11) — its vocabulary, sentence movement, punctuation, transitions, qualification, first-person practice, and deliberate repetition — without borrowing sentences or adding facts, opinions, humor, or disorder. Without one, write restrained, direct scholarly prose: lead with the substantive point, prefer canonical terms and simple verbs, name the actor where agency affects interpretation, build each paragraph on its claim–support–inference sequence and the job `notes/outline.md` gives it, state results under their exact conditions, keep observation apart from inference and limitations as visible as positive findings, let sentence length follow the reasoning, and end on a supported result, limitation, or useful transition rather than generic optimism. The prose stays English, keeps anonymity, uses only the space the argument needs, and never manufactures a persona.

**Review pattern clusters, not words.** Rewrite at paragraph scale when several signals accumulate, one template recurs, or a pattern introduces an unsupported claim — inflated significance, sales language, name-dropping, and stock optimism; vague attribution, knowledge-limit disclaimers, and plausible guesses; shallow analytical tails, abstract action chains, hidden actors, and stacked qualifiers; repeated "not X but Y", forced triads, fake objections, staged candor, and slogans; stock signposting, filler, previews, and generic endings; synonym cycling, uniform cadence, dramatic fragments, excessive dashes, decorative emphasis, label-heavy lists, and emojis — toward the exact result and only its supported consequence, a named verified source or an explicit gap, a direct fact–inference link with a clear actor, and only the structure the reader needs. No word, transition, passive, first person, long sentence, list, or dash is banned in isolation: a form that carries a real relation, preserves technical meaning, or matches the author stays, and quotations, titles, notation, data, and literal fields are never rewritten for matching a pattern. `bash execs/scpts/lint.sh` labels configured instances — `chatbot-residue`, `inflated-significance`, `vague-attribution`, `formulaic-contrast`, `stock-signposting`, `shallow-analysis`, `generic-outlook`, `manufactured-depth`, `stock-diction` — as advisory warnings that locate passages for review and never block submission by themselves; a clean scan means only that no configured pattern fired, and no run assigns a numerical "human score".

**Rewrite and verify.** Resolve the section through `notes/outline.md` and state its job in terms of mapped claims; mark every protected literal and semantic item; map the claim–support–inference sequence and diagnose by paragraph; rewrite each unit around its substantive point rather than patching watched words; then compare the revision with the ledger, evidence, reading notes, notation, style profile, and original prose, restoring every dropped qualifier, trace, or attribution and removing every added or strengthened claim. Where smoother prose would need unimported evidence, a different claim, an unsupported statement about prior work, a new canonical term, or the loss of a necessary qualifier, leave the passage unchanged and report it. A revision is ready only when every number and cited assertion still traces, claim strength and attribution are intact, and the paragraph does its assigned job.

1. **Keep each chat reply under about 500 words.** Files written to disk do not count. Detail belongs in the artifact; the reply is the digest.
2. **Ask only for a decision or authority that is still missing, one question at a time, and wait for an explicit answer** before acting on it. An explicit approval the user already gave — an earlier answer, or a clear request to perform the operation (item 13) — stays valid within its scope and is not asked again; a mandatory confirmation point is settled only by its own answer (item 7). Never bundle-approve, never assume a yes. This holds in headless and scripted runs: an unanswered question is not approval, and a skill that reaches a confirmation point finishes only the independent work already authorized, then waits for the answer before the action that depends on it.
3. **Every question carries 2–4 concrete options with the recommendation marked**, and the user may always answer freely outside them. **Each option states its consequence, not its label again**: what choosing it produces or changes, what it rules out, and — where the answer is not plainly undoable — whether it can be reverted and at what cost. "Two-column teaser" is a label; "the teaser spans one column, freeing ~0.4 page for §4, and swapping back later means re-flowing the intro" is a consequence. Genuinely open questions (what is the paper's pitch?) may be asked without options.
4. **Report honestly.** Never round a shortfall up. Never present a check as run when it was skipped or degraded — a lint that never ran, a build not attempted, a bib parsed without its parser. Never call a claim `verified` when its status says `drafted`, and never imply a number was traced when it was assumed (§9a).
5. **Lead with the outcome**, then the evidence, then the routing to the next step — which, for the ten skills the agent may start, is the run itself rather than a command printed for someone to type (§11.4). Where the next step is printed rather than taken — a slash-only skill, an unsettled target, anything on the STOP line, a command handed to the user (§2) — the reply's closing line carries it as the **exact command**, verbatim in this harness's own invocation syntax, never a paraphrase; and a run with nothing left to route says so in that line rather than dropping it. A printed command recommended to run at an `involve` level other than the one `INVOLVE` in `.env` resolves to (item 7) carries the token spelled out — `stage-sect-drafter 3_method involve=low` — so the line works pasted as printed; at the level `.env` already gives, the bare command is the whole recommendation. The recommended level is the one this run resolved, unless the user asked for another. The reader should never have to ask "what do I run now?".
6. **`STAGE_LANG` sets the language of replies and of what a run writes.** `.env` `STAGE_LANG=en|zh` (§3) fixes both: chat replies, and the Markdown a run newly writes — `notes/`, `tasks/`, simulated reviews, `wkdrs/` reports. Unset, empty, or any other value → follow the user's dialogue language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request beats both and stands for the rest of the run. A skill **resolves it once at the start of the run**, reading the needed `.env` controls (`STAGE_LANG`, `INVOLVE`, and the tier keys of §11.6) together and reusing them within the run until they change. It governs what a run **writes**, never a retranslation of what is already on disk: an existing document keeps the language it was written in, and changing one is an explicit user request, not a side effect of flipping the variable.

   **What stays English whatever `STAGE_LANG` says.** Two things leave this repository to be read by people who did not write them, and both are always English: **everything under `manus/`** — prose, captions, `% src:` comments, the text inside `\todo{}` — and **the response to reviewers** (`cycls/<cycle>/response/`), which a program committee reads. The manuscript's language belongs to the venue and the user; no dialogue language and no `STAGE_LANG` value ever rewrites it. Alongside those, **every structural literal stays English inside a document written in any language**: frontmatter keys and their values, ledger statuses (`proposed` / `drafted` / `verified` / `unsourced` / `weakened` / `dropped`), claim and review-point IDs, file paths, bibkeys and everything from `reference.bib`, venue names, dataset and metric names, and every string a script greps. A Chinese note with English structure stays machine-readable; a translated status value breaks `lint.sh` and every skill that reads the row.

7. **The `involve` level: the user chooses how much is asked.** It moves the questions still open, never the user's authority: it revokes no approval the user already gave and grants none the user did not (item 2). Every question a workflow poses is one of three kinds. **Mandatory confirmation points** are asked at every level, and only their own answer settles one — not the level, not a description (item 13), not an approval of the surrounding work: anything on the STOP line (§2 — submissions above all), every confirmation before a deletion or an overwrite, every `venue.yml` value entering as confirmed (§9c), the provenance question before a file is registered as evidence (§9e), each confirmation point where one of the six slash-only skills settles the decision it exists for (§11.1), and every ambiguity about what the user meant (§5.3 is the section-name case). **Judgment calls** — questions item 3 equips with a marked recommendation, where every offered option is safe — are what the level moves, and an explicit approval of the same operation and scope answers one in advance (item 2). **Derivable details** — anything with a conventional default — are decided silently at every level; they were never questions.

   The user sets the level; the skill **resolves it once at the start of the run**, before the first question, from three sources, each later one overriding the earlier: `INVOLVE` in `.env` (`low` / `medium` / `high`; absent, unset, or invalid → `medium`, which is what `.env.example` ships), then an `involve=<level>` token in the invocation, then plain language mid-run ("ask me less", "ask me everything") — the last instruction wins for the rest of the run. Reading it is part of item 6's single `.env` read.

   **The token is not an argument.** `involve=<level>` is stripped from the invocation before anything else is resolved — the section (§5.2), the cycle, the mode. This holds in **every** skill, whatever its `SKILL.md` says about the level: a skill matching its first argument against outline titles must not see `involve=low` and treat it as a section name. A skill that accepts no arguments at all still strips it.

   - `medium` — the default: this file and every `SKILL.md` exactly as written. The level adds nothing.
   - `low` — a judgment call is not asked: take the option you would have marked recommended, and log it (item 8). The commit offer is one of them (§1.6), and what it recommends is to commit; the reply still names what was committed. Taking a recommendation is never permission to widen the run's scope (§11.3). In Claude Code, Codex, and Qwen Code the level also reaches the harness: at `low`, `stage_involve_gate.sh` answers the permission prompt before a file edit inside the project, while `mates/` and the dot-directories at its root keep theirs. In Claude Code, `stage_bash_gate.sh` answers the one before a shell command too, except a command that deletes, overwrites a tracked file, writes under `mates/` other than through `execs/scpts/import.sh`, does more than read a venue kit or `.env`, installs, pushes or otherwise sends outward, launches a job, pulls, rewrites or prunes history, switches a branch, or creates, moves, or deletes a tag — those keep their prompt at every level. Codex and Qwen Code take that level from `.env` alone; Claude Code's gates also read the `involve=` token of the session's most recent STAGE command, which holds until the next one, past the end of the run, and plain language mid-run reaches no hook. A genuinely open question has no recommendation to take, so it is asked at every level — and when unsure which kind a question is, treat it as the more interactive kind.
   - `high` — judgment calls the skill's text batches into one confirmation point, or takes autonomously between confirmation points, are asked one at a time (item 2).

   For every question that is asked, item 2 holds unchanged: the level decides which judgment calls are asked at all, never whether an asked question may be assumed answered.
8. **Decide-then-disclose.** Every run keeps a decisions record — inside its durable report where the skill writes one, otherwise a "Decisions taken" list in the final reply — one line per settled question, as `question → choice → what it set`. At `low` it captures every judgment call taken unasked, and the final reply states that count whenever it is nonzero: `low` moves review after the fact, it never removes it. At `medium` and `high` it captures what the user answered, so a long session's decisions outlive the scrollback. Lines are appended as questions settle — a running record, never a growing recap replayed before each question.
9. **The level tightens per skill; it never loosens.** A `SKILL.md` may declare a judgment call it always asks, or flatten levels that make no sense for it (a story-coaching dialogue has no meaningful `low`). No skill treats a mandatory confirmation point as adjustable. Tightening decides what is asked, never whether an approval the user already gave still counts: a question the user answered in advance, within its scope, is not asked again (item 2).
10. **Carry the thread.** A user answering a long series of questions loses the thread. Three cheap habits, deliberately not a recap replayed before every question: **anchor the question** — one clause naming the earlier answer it rests on ("teaser spans one column → §4 gains 0.4 page; now: spend it on the ablation or the qualitative figure?"); **recap at boundaries** — at each section, table, or cycle-stage end, 2–3 sentences on what was decided, what it produced, what it opens next; **name the way back** — when a boundary closes something still changeable, say which skill and argument reopens it and what reopening costs ("budgets can be revisited with `/stage-outl-planner`; after drafting, re-trimming is the cost").
11. **Write the action, not its name.** The reader should never have to decode a term to know what happened, so a name that must appear brings its meaning with it, in the same sentence. This governs the prose a run writes into files as much as chat, and stops at structure: headings, table columns, field names, and every literal a skill matches byte-exactly stay verbatim, with explanation beside them, never in place of them. **A literal that is nothing but a pointer makes that explanation mandatory in chat**: `C4`, `W2`, `§9`, a cycle name — each stays verbatim and takes 3–8 words of what it points at, in parentheses, the first time each reply uses it: `C4 (the zero-shot transfer claim)`, `W2 (reviewer doubts the ablation coverage)`. First use in **each** reply, not once per conversation; later uses inside the same reply stand alone.
12. **Show the material before you ask about it.** A question asking the user to approve, choose between, or edit something the run has drafted carries that draft in the reply that poses it — quoted as it would be written, immediately before the question. An option is not where the content lives: options state consequences (item 3) and are read as choices, not as text under review. Neither is a file the run already wrote: a diff scrolls past, and a path is something the user would have to go open. The quoted draft is exempt from item 1's word budget — it is the artifact under review, not commentary on it, and length is never the reason to omit it; only material running past a screen or two narrows to the part the question turns on, with the rest named by path. "These four contributions — write them as they stand?" with the four bullets nowhere in the reply is the failure this rule exists for: the user can agree, but cannot review.
13. **Free text is a description, and every skill takes one.** `<skill> [TARGET] [DESCRIPTION] [involve=<level>]` is the shape the whole roster shares: `involve=` is stripped first (item 7), the target resolves as §5 says, and whatever is left is the user saying, in their own words, what this run is for. It carries the user's intent, limits, and any explicit authorization. It may seed which path a skill takes, and it may supply text the run then records — "the reviewer called the ablation thin, widen it" both picks the path and gives the reason that gets written into the point ledger. **A clear request to perform a specified operation answers that operation's question in advance** (item 2) — "and commit it" is the commit offer answered (§1.6) — while background, a preference, or a vague wish authorizes nothing, and a limit it states — read-only, this section only — binds the run. It never widens the target or the mode silently, never answers a mandatory confirmation point (item 7), never settles a target §5.3 would have asked about, never licenses a number §9a would have made a `\todo`, and never authorizes anything on the STOP line (§2). A run whose path a description set says which path it took before it writes anything, so a misreading costs one question rather than one wrong edit. **Prose that resolves to no target is description alone, not a missing target**: run as if no argument was given, and say so first. **A lone token that looks like a target and matches none is not a description**: it stays the ambiguity §5.3 asks about. Where a skill's first argument is already free text — a paper title, the purpose of a table that has no outline row yet — that argument is the description, and nothing changes.

## 8. The output table

Every skill's durable output, in one table. `stage-flow-status` reads this as the basis for its coverage checks: a stage is covered when the artifact below exists and its state field is current. Keep the table honest — a skill that changes what it writes updates this row in the same commit, or the status skill silently stops checking that stage.

| Stage | Producer | Path | State field |
|---|---|---|---|
| Adoption | `stage-proj-adopt` | `notes/adopt.md` | `adopted:`, `backfilled:` |
| Evidence | `execs/scpts/import.sh` + `stage-evid-curator` | `mates/<slug>/**`, `mates/manual/**`, ledger `mates/MANIFEST.md` | per entry: `source-type:`, `source-stamp:`, `imported:` |
| Story | `stage-stry-coach` | `notes/story.md` | `finalized:`, `venue:`, `cycle:` |
| Venue profile | `stage-stry-coach` (or `stage-proj-adopt`) | `cycls/<cycle>/venue.yml` | `confirmed:` |
| Claim ledger | `stage-stry-coach` creates; `stage-sect-drafter`, `stage-tabs-builder`, `stage-clms-auditor`, `stage-resp-writer` update | `notes/claims.md` | per-claim `Status` column |
| Outline | `stage-outl-planner` creates; drafter / figs / tabs skills update their rows | `notes/outline.md` + `manus/secs/*.tex` skeletons | `finalized:`; per-row `Status` |
| Notation | `stage-outl-planner` creates; `stage-sect-drafter` appends; `stage-copy-editor` enforces | `notes/notation.md` | `updated:` |
| Style profile | `stage-copy-editor` creates and revises; `stage-sect-drafter` reads | `notes/style.md` | `updated:`, `source:` |
| Section drafts | `stage-sect-drafter` | `manus/secs/<n>_<slug>.tex` | Sections row status in outline |
| Tables | `stage-tabs-builder` | `manus/tabs/<slug>.tex` | per-data-row `% src:` comment; Tables row in outline |
| Figures | `stage-figs-designer` | `manus/figs/<slug>.pdf`, `manus/figs/srcs/<slug>.*` | Figures row in outline |
| References | `stage-refs-curator` | `manus/bibs/reference.bib`, `notes/refs/refs_index.md`, `notes/refs/<ABBREV>.md` | index presence |
| Audit reports | `stage-clms-auditor`, `stage-cite-auditor`, `stage-copy-editor` | `wkdrs/reports/CLAIMS_<date>.md`, `CITES_<date>.md`, `POLISH_<date>.md` (ephemeral); follow-ups in `tasks/claims_followups.md`, `tasks/cites_followups.md`, `tasks/polish_followups.md` (tracked) | date in filename; open follow-up checkboxes |
| Simulated review | `stage-peer-reviewer` | `cycls/<cycle>/reviews/SIM_REVIEW_<date>.md` — the panel meta-review; per-perspective working files in `wkdrs/reports/peer_<cycle>_<date>/`. An `extern=` run registers nothing: its `REFEREE_<date>.md` reviews somebody else's paper and is not one of this paper's stages | date in filename |
| Response | `stage-resp-writer` | `cycls/<cycle>/response/RESPONSE_<date>.md`, promises in `tasks/<cycle>_promises.md` | promise checkboxes |
| Submission | `stage-subm-packer` | `cycls/<cycle>/SUBMISSION_<date>.md`, git tag `freeze/<cycle>_<date>`, package under `wkdrs/builds/`, the registered venue template kit at `cycls/<cycle>/template/`, venue follow-ups in `tasks/<cycle>_venue.md` | `frozen:`; venue follow-up checkboxes |
| Poster | `stage-pstr-builder` | `cycls/<cycle>/poster/POSTER_PLAN.md`, `poster.tex`, the official poster kit at `cycls/<cycle>/poster/template/`, render under `wkdrs/builds/poster/` | `state:`; per-zone Status |
| Status | `stage-flow-status` | — (read-only; reports in chat) | — |

Real reviews from a venue are dropped by the user into `cycls/<cycle>/reviews/` as
`received_<id>.md` (free form); `stage-resp-writer` reads everything in `reviews/`.

**Staleness is exact comparison, never mtime.** A compiled or imported artifact records its source's stamp *as it was when read* — for evidence, the `source-stamp:` in its MANIFEST entry, taken from the first `generated:`/`updated:`/`finalized:` line of the upstream file. Staleness is detected by comparing the current upstream value against the recorded one, byte-exact; file mtimes move for unrelated reasons and are never consulted. `import.sh --diff` implements this for evidence, and `stage-clms-auditor` runs it before trusting any fingerprint.

**Every workflow artifact records the model that wrote it.** Each producer writes `model_id` into the frontmatter of what it creates under `notes/`, `tasks/`, `cycls/`, and `wkdrs/reports/`; a file that has no frontmatter block yet — `notes/refs/refs_index.md` — gains one for it. The value is the model id the runtime reports for the writing session, copied verbatim, and the runtime does report it: STAGE's `stage_model_id.sh` hook states it in the session context, and Claude Code names it in the system prompt besides. Where that line is missing, or carries a recovery command in place of an id, §13 (harness hooks and model provenance) holds the per-runtime fallback — run it before writing `unrecorded`, which is the value for a session that names no model anywhere. Never infer it from behavior, never reason about which model this is "probably", and never copy one artifact's value into another.

**And `model_trail` records the flow across writers.** `model_id` names one write; most of these files are written across many sessions — a ledger five skills edit for the life of the paper, an outline replanned each cycle, a reference base grown paper by paper — and there a single field describes only the last one. So every artifact carrying `model_id` carries an append-only `model_trail` beside it: one entry per write session, `{ date, model, skill, scope }`, where `scope` names what that session wrote in the file's own vocabulary — claim IDs, section numbers, review points, table rows. Append, never rewrite a past entry, and keep `model_id` mirroring the last entry so a plain grep still works. A write-once artifact — every dated report, simulated review, response, and submission record — has exactly one entry; a regenerated one starts a fresh trail rather than extending the trail of the generation it replaced. The shape is the one in §8.1, and the pair joins the frontmatter of every schema in §8.4–§8.11 without being repeated in each.

**Three places deliberately carry neither.** Nothing under `manus/`: the manuscript is what the venue and arXiv receive, and whether a paper discloses AI assistance is the authors' decision under their venue's policy, not a comment a skill leaves in a `.tex` file. Nothing under `mates/`: evidence is immutable (§9d) and already carries its own provenance — `source-type:`, `source:`, `source-commit:`, `source-stamp:`, `sha256:`, `imported:` — and much of it is written by `import.sh`, a shell script with no model to report. And not `cycls/<cycle>/venue.yml`, whose values are the user's confirmed facts and whose `confirmed:` is their provenance (§9c). Who drafted a section stays traceable without them: the claim rows it moved to `drafted`, the outline row it flipped, the trail of the audit report that read it.

**Resolution before the write is paired with a check after it.** Where the session context supplies a post-write provenance check, every producer skill, including every report writer, runs it once for each file it wrote that this section requires to carry `model_id`, after the last write and before it reports completion or offers or makes a commit. Which runtimes supply one, and the concrete command and arguments, are in §13. The expected value is the resolver's output, otherwise the exact model id reported at session start, otherwise `unrecorded`; the actual value is the file's `model_id`. A nonzero exit is a blocker: correct the provenance and run the check again, and neither report completion nor commit while it fails. The three places above are never checked, nor is `poster.tex`, which has no frontmatter, nor any file of a venue or poster kit: none of them carries `model_id`, and a failed check on one is never fixed by adding it. This does not permit recovering a value from a model-family description; descriptions are not ids.

Two limits matter, because these fields will be used to compare work across models:

1. **They are self-reported, not verified.** They record what the runtime claimed at write time. A model switched mid-session may still be described by the pre-switch string, so a value can lag reality. Treat it as evidence about provenance, not proof of it.
2. **A trail counts write events, and a write event is not a contribution.** A longer trail is not better work: it says who touched the file and when, and nothing about whether the touch helped.

`stage-flow-status` is the only reader that puts them together — per artifact, the model that last wrote it and how long its trail is, plus every output-table artifact whose trail is missing, which is what a file written before these fields existed looks like. Nothing is generated from them, so there is no ledger file to keep in step.

The file schemas the table points at. A skill that writes one of these files writes exactly this shape; a skill that reads one may rely on it.

### 8.1 `notes/claims.md`

```markdown
---
updated: YYYY-MM-DD
model_id: <this session's model id, verbatim | unrecorded>
model_trail:                    # append-only: one entry per write session, never rewritten
  - { date: YYYY-MM-DD, model: <id | unrecorded>, skill: stage-…, scope: <what this session wrote> }
---
# Claim ledger

| ID | Claim | Type | Stated in | Evidence | Status |
|----|-------|------|-----------|----------|--------|
| C1 | <one sentence> | contribution \| performance \| factual | `1_intro`, `abstract`, `tabs/main` | `mates/<slug>/...#<anchor>`; `—` if none | proposed \| drafted \| verified \| unsourced \| weakened \| dropped |
```

Lifecycle: `proposed` (story) → `drafted` (stated in text) → `verified` (clms-auditor matched evidence) / `unsourced` (stated, no fingerprint — must carry `\todo`) / `weakened` (conceded in response) / `dropped`. Repairs are owned like the states are: `stage-clms-auditor` flips `unsourced → verified` when a later audit finds the `\todo` gone and every number tracing to fresh, matching evidence; `stage-sect-drafter` and `stage-tabs-builder` flip `unsourced → drafted` when a revision replaces the `\todo` with a value that traces, and `weakened → drafted` when a revision restates a conceded claim per its kept promise in `tasks/<cycle>_promises.md` — after which verification is the ordinary path. `dropped` is terminal; a claim worth reviving re-enters through `stage-stry-coach` as a new row.

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

Note frontmatter: `title:`, `venue:`, `year:`, `bibkey:`, `added:`, and `depth:` on a seeded note only. Sections: `## What it does`, `## Relation to ours`, `## Citable facts` (facts precise enough for cite-auditor to check assertions against). The note's filename is the paper's `ABBREV` handle (`CLIP.md`); `bibkey:` carries the bib's citekey, `<Year>_<Method>_<FirstAuthorSurname>` (`2021_CLIP_Radford`) — the two are different strings on purpose, and a citekey already cited in `manus/`, or seeded from `mates/`, is never rewritten to fit the scheme.

A note written here carries no `depth:`, because the read is a floor rather than a scale: `stage-refs-curator` writes a note only after reading the abstract, introduction, method, and main results table, and a paper whose text it could not fetch gets a bib entry and no note at all. A note converted from an imported STAR note is the exception — the upstream read may have stopped earlier — so it carries that note's `depth:` verbatim (`full`, `method-and-results`, or `abstract-and-intro`), and `abstract-and-intro` names a note shallower than a native run is allowed to write. The field records how far the facts under it were read; it never licenses a thinner read here, and `stage-cite-auditor` reports it beside every verdict it backs.

`refs_index.md` is the bib's audit trail, in eight sections: scope, papers with notes, categories, provenance (one row per bib entry, 100% coverage, coined handles marked †, preprint-only entries ‡), impact scores with their sub-signals and fetch dates, needs-manual-check detail, self-audit, next actions. An entry with no provenance row is not allowed to exist. `stage-refs-curator`'s `references/` holds the exact shapes: `refs-index-template.md` for this file, `source-policy.md` for the citekey, the `% src:` line, the `%% Needs manual check` block, the closed list of normalizations, and the score arithmetic.

### 8.8 Reviews and response

`SIM_REVIEW_<date>.md` is the peer-review panel's meta-review, venue-shaped. Frontmatter: `type: peer_review`, `target:`, `cycle:`, `scale:` (conference-6 | journal), `mode:` (panel | quick), `generated:`, `recommendation:`. The same skill's `extern=` run writes the same sections to a `REFEREE_<date>.md` under `wkdrs/`, with `type: referee_report`, a `venue:` the user confirmed, and no `cycle:` — it is deliberately outside this table, because nothing downstream reads it. Sections: `## Summary`, `## Strengths`, `## Major Weaknesses` (numbered; each anchored, naming the claim IDs it attacks and the perspectives that raised it), `## Minor Weaknesses`, `## Questions to the Authors`, `## Limitations & Ethics`, `## Concern Matrix`, `## Recommendation` (anchored band or journal tier, confidence, every triggered cap named), `## Synthesis Notes`. The full templates, the five perspective briefs, and the rubrics live in `stage-peer-reviewer`'s `references/`; per-perspective reviews and the citation audit stay in the run's `wkdrs/reports/peer_<cycle>_<date>/` directory.
`RESPONSE_<date>.md` frontmatter: `cycle:`, `date:`, `sources:` (review files read). Sections: `## Point ledger` `| Point | Reviewer | Attacked claims | Evidence | Response summary | Promise? |`, `## Draft response` (within `response_limit`), and promises mirrored to `tasks/<cycle>_promises.md` as `- [ ]` checkboxes.

### 8.9 `notes/adopt.md`

Frontmatter: `adopted:`, `backfilled:`. Sections: paired sources (STAR repos + slugs), venue target, existing-asset inventory (for adopted projects), the unsourced-claims backlog, backfill actions taken.

`backfilled:` is a gate, not a note (§9a). It stays empty while any backlog row is unresolved, and it is set — to the real date — only by `stage-clms-auditor`, when every row has either become a `verified` claim or an `unsourced` one carrying its `\todo`. `stage-subm-packer` refuses to pack a repository that has a `notes/adopt.md` with an empty `backfilled:`, because that is exactly the state in which `lint.sh` reads clean over numbers that trace to nothing.

### 8.10 `cycls/<cycle>/SUBMISSION_<date>.md`

Frontmatter: `cycle:`, `date:`, `frozen:` (tag name), `package:` (path under `wkdrs/builds/`), `template:` (the venue template the package was formatted in, or `arxiv`). Body: lint summary, checklist outcome, page counts — the converted copy's, with the preprint build's beside it when they differ — what the conversion dropped or left for a human, and what was submitted where.

The same producer's other durable artifact is `tasks/<cycle>_venue.md`, the venue follow-up list a `convert` run maintains. Frontmatter: `cycle:`, `template:`, `updated:`. Body: one `- [ ]` line per finding, each carrying a stable `V<n>` id and the skill that owns the fix. It is updated, never regenerated — a checked item stays checked and is never re-raised, new findings append with the next free id, and an item that no longer applies is checked with its reason rather than deleted. These are findings, not promises: an open box never blocks a pack, which is what separates this list from `tasks/<cycle>_promises.md`.

### 8.11 `notes/style.md`

The author's prose preferences, written down once so every run that touches a sentence reads the same ones instead of inventing a voice per session. `stage-copy-editor` is its only writer (its `style` mode); `stage-sect-drafter` reads it while drafting and the polish pass reads it while editing. Caption prose written by `stage-tabs-builder` and `stage-figs-designer` acquires the voice at the next polish pass, not at authoring time — neither skill reads the profile, deliberately, so a table or figure run stays as lean as it is today. Frontmatter: `updated:`, and `source:` — `interview` | `sample` | `preset:<name>` — recording how the dials were arrived at. Four sections:

```markdown
## Dials
| Dial | Setting | Notes |
| sentence length | short — median ≤ 22 words | |
| sentence rhythm | varied | longer sentences carry qualifications; short sentences state conclusions |
| voice | active, first-person plural | ANON=true keeps self-reference third-person (§3.4) |
| paragraph opener | claim-first | |
| transitions | implicit | use an explicit connective only when paragraph order does not show the relation |
| hedging | minimal | never below what the evidence requires — see Precedence |
| enumeration | \parahead runs, not itemize | |
| tense | present for method, past for experiments | |
| math density | standard | |

## Prefer / Avoid          | Prefer | Avoid | Why |          — constructions, not single words
## Never                   | Never | Use instead |          — the words and tics this paper does not use
## Samples                 paragraphs the author wrote or approved, each with its attribution
                           and one line naming what a run should take from it
```

Every `Setting` and every `Never` cell is a short English literal, because a polish report measures against them and a measurement greps; the `Notes` and `Why` columns are free text in the run's language (§7.6).

**Precedence, and it is why this file is a schema rather than a paragraph of taste.** §9 outranks it, then `notes/notation.md`, then the venue's format rules, then this profile. Concretely: no dial licenses a number, a citation key, or the removal of a `\todo{}` (§9a); no dial overrides a canon term or an abbreviation's first use (§8.6); and **no dial changes what a sentence asserts.** `hedging: minimal` tightens wording and never strips a qualifier the evidence requires — claim strength lives in the ledger row (§8.1), not in a preference, and a profile that would have to override one of these is a profile that is wrong. The run says so and leaves the sentence alone.

**A sample supplies dials, never sentences.** What crosses from a `## Samples` paragraph into `manus/` is the setting a run derived from it; wording that crosses is reuse, whatever the sample's origin. A sample from the author's own earlier paper carries the same rule, because a similarity check does not ask who wrote the source.

**It binds `manus/` prose and nothing else.** Not the Markdown a run writes under `notes/`, `tasks/`, or `wkdrs/` — those are records with schemas of their own — and not `cycls/<cycle>/response/`, whose register is fixed by the venue's `response_type` and `response_limit`. The file is optional: absent means every skill writes exactly as it does today, and no skill creates one as a side effect of another job.

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
- **Two skills may look past what the manuscript already cites**, and both do it under the same citation-integrity contract: a work is named only when it is **whitelist** (already in `manus/bibs/reference.bib`) or **verified** — fetched during that run, with the record (title, authors, year, venue, URL) and the query that found it logged, the queries that returned nothing included. A work recalled from memory is treated as nonexistent; what cannot be fetched is phrased as a direction ("check whether prior work exists on X"), never as a named fact. `stage-peer-reviewer` searches to attack the paper's positioning, and names what it finds in a simulated review. `stage-refs-curator discover` searches to propose candidates for the reference base, and proposes only: the author picks, and nothing a search surfaced reaches `reference.bib` or a reading note unpicked — an agent that chose the bibliography by its own taste has built a positioning nobody can defend at review time. These are the workflow's only two sanctioned uses of live search. Each skill bounds its own searching by structure rather than by quota — a sweep that ends when it stops surfacing anything new, an expansion forbidden to enlarge its own input, a set of questions fixed before the first query — because a quota picked out of the air is a number nobody can defend and nobody can check the log against, while a stopping condition is one the log already shows. The polite rate stays a number: it is a promise to someone else's server, not a parameter of ours. §2's bulk-fetch line still binds, and both drop to topic terms alone when the cycle carries `anonymized: true` or `.env` sets `ANON=true` — a query carrying the paper's title or one of its sentences identifies an anonymous submission to whoever holds the search logs.

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
| Venue styles | `manus/stys/`: `stage.cls`, `stage.sty`, and `stage.bst`, and nothing else — `manus/` is scanned by `lint.sh` and holds only files this workflow owns |
| Imported evidence (read-only) | `mates/<source-slug>/**` mirroring upstream paths; hand-registered drops in `mates/manual/**`; ledger `mates/MANIFEST.md` |
| Writing metadata | `notes/` fixed files: `story.md`, `claims.md`, `outline.md`, `notation.md`, `style.md`, `adopt.md`; reading notes in `notes/refs/` |
| Submission cycles | `cycls/<venue>_<year>/`: `venue.yml`, `template/` (the official venue kit, unpacked whole, byte-for-byte, never edited), `reviews/`, `response/`, `SUBMISSION_<date>.md`, `poster/` (the poster plan and its source, with an official poster kit under `poster/template/`) |
| Revision scratch, promise lists | `tasks/` |
| Builds, ephemeral reports, fetch caches | `wkdrs/builds/`, `wkdrs/reports/`, `wkdrs/refs_<date>/raw/` (gitignored, regenerable) |
| What earlier sessions learned, owned by no other file | `.stage/memory/`; the git-ignored `.stage/memory/local/` for `machine:` scoped facts and anything kept off the repository (§12) |
| Entrypoints | `execs/run.sh`, `execs/update.sh` — **execs/ root is closed**; utilities go in `execs/scpts/` (`import.sh`, `lint.sh`, `fmt.sh`). Every script under `execs/` is upstream-managed and `execs/update.sh` overwrites all five; per-project settings live in `.env`, never in an edited copy of one |
| Workflow docs (upstream-managed) | `docs/mds/stage-workflow/` |

Rules the table alone does not carry:
1. **`mates/` is read-only.** `import.sh` and `/stage-evid-curator` are the only writers, and they
   only add/replace whole files with fingerprints. Content fixes happen upstream, then re-import.
2. **`wkdrs/` is never committed.** Durable audit outcomes live as status flips in `notes/claims.md`
   and entries in `tasks/`, not in reports.
3. **`execs/` root is closed** (STAR's rule): `run.sh` + `update.sh` and nothing else.
4. **The manuscript always compiles as the preprint; a venue's format is a generated copy.**
   `manus/stys/` holds three files and which of them a venue swap replaces is load-bearing:
   `stage.cls` owns the look and is what a venue class replaces; `stage.bst` owns the reference
   list and is what a venue's own `.bst` replaces; `stage.sty` owns `\todo` plus the macros skills
   write into `secs/` and `tabs/` (`\parahead`, `\cmark`, `\tablestyle`, `\figref` …) and survives
   every swap. `stage.bst` is `plainnat` with four fields silenced — a DOI, URL, ISBN, or ISSN
   stays in `reference.bib`, where it is provenance and the input to `/stage-refs-curator`'s
   re-fetches, and is simply not typeset, which is the arrangement CVPR's own `.bst` makes and the
   reason a reference list here reads like a conference paper's. `run.sh` puts the entry point's
   `stys/` on `BSTINPUTS`, so `\bibliographystyle{stage}` resolves by bare name and so does a kit's
   `.bst` inside a generated copy. Project-specific macros go in `main.tex`, never in `stys/`.
   An official venue kit unpacks whole
   and unedited into `cycls/<cycle>/template/`, beside that cycle's `venue.yml` — never under
   `manus/`, a scanned namespace where a kit's example `.tex` would trip `lint.sh`'s `\todo` count
   and its identity-leak scan. `template:` in `venue.yml` names the class inside the kit;
   `stage-subm-packer convert` reads it and regenerates a standalone copy under `wkdrs/` that
   compiles under that class. `manus/main.tex` keeps its `\documentclass{stys/stage}`: there is no
   in-place swap and no second source of truth.
5. **Seven harnesses share one neutral skill store.** The same sixteen skills ship in `.agents/skills/`,
   `.claude/skills/`, `.cursor/skills/`, `.dsh/skills/`, `.kimi-code/skills/`, `.pi/skills/`, and
   `.qwen/skills/`. `.agents/skills/` is the authored, tool-neutral source required by the `AGENTS.md` convention
   and the only path shared skill files are stored under; the six named harness trees are generated from it,
   with harness-only behavior held in explicit adapters. Every byte-identical file in a named harness tree
   links there. Harness-specific manifests remain real files and name that harness's invocation and
   tools. Load your harness's native copy when one exists; otherwise the neutral copy is safe because it
   names roles rather than another harness's tools. Codex's per-skill UI manifests live under
   `.codex/skills/` and are linked into the `.agents/skills/` paths Codex scans. The complete `/stage`
   request router lives once at `.agents/commands/stage.md`, and the
   `/stage-auto` goal-run procedure (§11.5) beside it at `.agents/commands/stage-auto.md`; Claude, Cursor, Pi, and Qwen keep only thin
   native entry points that pass their argument syntax to those shared files and select their own skill tree.

## 11. The skill roster

Sixteen skills: `/stage-<name>` in Claude Code, Cursor, Pi, and Qwen Code; `$stage-<name>` in Codex; `/skill:stage-<name>` in DSH and Kimi Code. What each one does in full is [writing-workflow-skills.md](writing-workflow-skills.md); what each one writes is §8.

| Skill | Tier | Role |
| --- | --- | --- |
| `stage-proj-adopt` † | exec | wire a new or existing paper repo into STAGE |
| `stage-evid-curator` | exec | import, register, and map evidence |
| `stage-stry-coach` † | plan | shape the story; seed claims and the venue profile |
| `stage-outl-planner` † | plan | outline, budgets, section skeletons, notation |
| `stage-sect-drafter` | plan | draft one section per invocation |
| `stage-tabs-builder` | exec | generate tables from evidence only |
| `stage-figs-designer` | exec | figure inventory, sources, rendered PDFs |
| `stage-refs-curator` | exec | bibliography, reading notes, discovery, positioning |
| `stage-copy-editor` | exec | polish prose; never meaning, never numbers |
| `stage-clms-auditor` | exec | trace every number to a fingerprint |
| `stage-cite-auditor` | exec | verify citations against reading notes |
| `stage-peer-reviewer` | plan | simulated five-perspective review panel |
| `stage-resp-writer` † | plan | reviews → point ledger → response + promises |
| `stage-subm-packer` † | exec | preflight, venue conversion, package, freeze |
| `stage-pstr-builder` † | exec | select, render, and check the cycle's poster |
| `stage-flow-status` | read | read-only status and the one next action |

1. **The six marked † are slash-only.** Run them only when the user names them: they are the decision points — adoption, story, outline, response, submission, and what goes on the poster — and a decision point reached on an agent's own initiative is a decision nobody made. This table is the source of truth; each harness manifest carries its own guard against implicit invocation, named in that harness's vocabulary, and CI checks all seven harnesses against these markers in both directions — a † whose guard is missing, or a guard on a skill carrying no †, fails the build.
2. **Two skills never touch the manuscript.** `stage-peer-reviewer` writes only its review under `cycls/<cycle>/reviews/` — or, refereeing an external paper with `extern=`, only under `wkdrs/`; `stage-flow-status` writes nothing at all. Run the status skill first whenever you do not know where things stand — it reads the outline, the ledger, the manifest, and the cycle state, and names the single next action with its exact command.
3. **One skill per invocation, and one unit of work inside it.** A section, a table, a figure, a response — a run that quietly widens its scope is the failure this rule exists for; the next unit is the next invocation.
4. **A named next action is taken, not printed, when it names one of the ten.** Skills end by naming what comes next — the status skill's single next action, a red lint gate naming the owner of what broke, an auditor routing an unsupported claim to the section that carries it — and each of those is a command handed to the reader. Where the named command is one of the ten and its target is settled, run it instead of printing it: the reader is the agent, and a command printed to itself is a handoff to nobody. The six keep the printed command, because typing it *is* the decision they exist to leave with the author. Three limits make that safe. **The pickup happens after the naming run has ended, never inside it** — a skill that may not touch the manuscript gains no reach by naming a successor, so `stage-flow-status` stays the reporter it is and its successor starts once the report is done. **An unsettled target is asked about rather than guessed** — which section, which table, which figure, which cycle (§5 resolves them). And **item 3 holds unchanged**, one skill and one unit of work, with a run nobody typed saying what it is starting before it begins.
5. **`stage-auto` is the goal-run grant.** `stage-auto <goal> [involve=<level>]` is a command, not a skill — `/stage-auto` in Claude Code, Cursor, DSH, Pi, and Qwen Code, `$stage-auto` in Codex, `/stage-auto` (`/skill:stage-auto`) in Kimi Code — and typing it is the one request that authorizes pursuing a goal across runs. Its procedure, [`.agents/commands/stage-auto.md`](../../../.agents/commands/stage-auto.md), turns the goal into a check on repository state, runs `stage-flow-status` first, and stops at the first of: the check passing, a † skill, a STOP-line action, a question nobody can answer, or a full pass that moved nothing. It adds a goal to item 4, never an authority: item 4's pickup passes through the goal filter, so a named action that does not advance the goal is listed rather than taken; each start is one of the ten, one unit of work (item 3), at the goal run's `involve=` level — raised by a printed command that asks more, never lowered by one — and behaves exactly as if the user had typed it, its own commit step (§1) included. It never starts one of the six marked †: the run stops there and prints the exact command. It never writes `mates/`, enters a venue fact (§9c), crosses the STOP line (§2), answers a mandatory confirmation point (§7.7), or commits, tags, or writes anything itself, and green lint is never its goal.
6. **Where a run executes, and on which model.** Three `.env` keys (§3) name one model each: `STAGE_PLAN_MODEL` for the paper's judgment — the story, the outline, drafting, the simulated review, the response to reviewers — `STAGE_EXEC_MODEL` for production and checking — evidence, tables, figures, references, polish, the audits, the package, the poster — and `STAGE_READ_MODEL` for read-only status, the check modes, and delegates that only gather. The Tier column above says which of the three a skill's run belongs to, and all three are read in the one `.env` read that already gets `STAGE_LANG` and `INVOLVE` (§7.6), never a call of their own. **An empty key changes nothing**: the run stays on whatever model the session or the harness already gave it, and every other rule in this file reads exactly as it does with the keys unset.

   **One key can name one model per harness.** A value is either a single model name, used by whichever harness reads the key, or comma-separated `<harness>:<model>` entries tagged with the names `STAGE_HARNESSES` uses — `claude`, `codex`, `cursor`, `dsh`, `kimi`, `pi`, `qwen`. A run takes its own tree's entry, falls back to an untagged one, and reads the key as empty when it has neither; other and unknown tags are ignored. The first colon ends the tag, so a model name carrying a colon is written tagged, and a model name keeps its harness's spelling. **Only a harness whose dispatch tool takes a model per call reads the keys at all** — Claude Code, and Codex where its subagent interface accepts one. Cursor, DSH, Kimi Code, Pi, and Qwen Code, as STAGE ships them, cannot, and read all three as empty: no line, no routing. "The tier value", here and in every manifest, means that resolved result, never the raw line from `.env`. Never invent a model name or a dispatch parameter; where the harness refuses a configured model, keep the working route and say so once.

   **The mode overrides the roster tier for that run**, because what a skill does in one mode is not what it does in another: `stage-evid-curator check` (a bare invocation runs it too), `stage-figs-designer`'s no-argument audit, and `stage-pstr-builder check` are READ, and `stage-refs-curator position` is PLAN.

   **A run stays in the session that started it.** A skill runs on the session's model and never hands the whole run to a delegate. When its tier value — its mode's, where the mode overrides — names a model that is not an alias of the one this run is on, the run says so in one line at the start — the tier, that model, and the one way to get it: switch the session's model — and then runs where it is; an empty value, or an alias of this run's model, gives no line. An alias is the family name inside the id, or the id itself, a context-window suffix aside (`opus` for `claude-opus-5[1m]`); the model this run is on is what the resolver command in the session context's provenance line prints when run once (§8), or failing that the id that line states. That line is the paragraph led **Where this run executes.** that every manifest carries at the head of its Workflow, before its first step; no skill is exempt. Claude Code forks `stage-flow-status` on the model its own manifest names, pinned there by hand in the STAGE upstream until a configure step writes `STAGE_READ_MODEL` into it, so that run compares the READ value with the model it was forked on and names that upstream field, not the session's model, as the way to get it; a paper repository's `execs/update.sh` replaces a local edit to the field.

   **Inside a run, a delegate's model follows its work, not its skill**: a pure collector — read-only gathering — runs on READ; a delegate that writes files (§6.4), `stage-refs-curator`'s per-paper readers among them, on EXEC; an independent-perspective delegate (§6.6), the `stage-peer-reviewer` panel among them, on PLAN, even though it only reads; and a read-only delegate returning judgments the run relies on — `stage-cite-auditor`'s support verdicts — on its skill's tier. Pass the resolved model where the dispatch tool accepts one; an empty value passes none and keeps the host's default. A file a delegate writes records the delegate's model (§8), not the session's, and every fan-out records its tier and the model it actually got in the decisions record (§7.8).

## 12. Project memory

What a session learned and no file in the repository owns goes to `.stage/memory/`, one fact per file, reaching the next session as an index line the session hook (§13) builds from its frontmatter. The test is exclusive: a number belongs to a fingerprinted `mates/` entry, a claim to `notes/claims.md`, a page limit or deadline to the cycle's `venue.yml`, what a cited paper says to `notes/refs/`, a promise to `tasks/<cycle>_promises.md`, a venue follow-up to `tasks/<cycle>_venue.md`; memory is the residue, and where it disagrees with a file in the repository, the file wins. It cuts hardest against §9: **a memory is never a source for a number, a venue rule, or an assertion about a cited work** — a recalled value is unsourced whichever file recalls it. Recording is offered, never assumed — at most two offers a session, written only after the user agrees; `INVOLVE=low` (§7.7) records unasked and says so. Four types: `env`, a fact about a machine or TeX toolchain, usually learned by failing, and the one type the hooks age; `pref`, a standing user preference about how the writing is done; `insight`, a judgment that outlived the run that produced it; `deadend`, a framing, cut, or layout tried, rejected, and not worth retrying, with what it cost — between cycles, the knowledge a paper repository most needs kept.

**Where it lives.** `.stage/memory/<slug>.md` is versioned and travels with a clone; the template tracks only `.gitkeep` there. `.stage/memory/local/<slug>.md` is git-ignored like `.env` and holds a `machine:` scoped fact — a path, a font, a missing LaTeX package, an engine quirk true here and false on the next machine — and any memory the user keeps off the repository, whatever its scope. `global`, `cycle:`, and `manus:` facts hold on any clone and go to the versioned store: the split is by where a fact travels, not where it holds.

**The file.** Frontmatter with English keys and values — `type`; `scope` (`global`, `machine:<name>`, `cycle:<cycle>`, or `manus:<path>`: where the fact is true, not where it was learned); `summary` (the index line: what the fact *is*, "stage.cls builds here only under xelatex", not what it is about); `language` (the body's, §7.6); `verified` (when the fact was last confirmed true, from the clock, §4); `model_id` (the model that wrote or last re-verified it, verbatim, §8); `source` (the artifact it came out of, or `conversation`); optional `supersedes` (the slug it replaces) — then a body in the run's language, opening with one sentence stating the fact and holding only what a reader needs to act on it. No `model_trail` and no history: a re-verification rewrites `verified` and `model_id`, and git holds what the file used to say.

**The index line.** Nothing is hand-written: the hook reads every `<slug>.md` in the two directories and prints, newest `verified` first, the versioned store's lines then `local/`'s, and nothing for an empty store; `--list` on any copy prints the same lines as plain text.

    - <type> · <scope> · <verified> · [<slug>](<slug>.md) — <summary>

It reads the frontmatter literally: a block not closed by a second `---` is not listed; a file without `summary` is listed by its first body line; an `env` line — the type token as written — whose `verified` is more than 180 days old is marked stale, the other types never, since a dead end stays dead. Keep the store under roughly 60 memories; past that, retire rather than group, since every line reaches every session.

**Retiring.** Re-verified: set `verified` to today and `model_id` to the checking model. Superseded: write the new memory with `supersedes: <old-slug>` and delete the old file; git holds the history. Wrong: delete it. A deletion is confirmed with the user at every involve level (§7.7). A cycle is not a retirement event: a `cycle:<cycle>` memory from a frozen submission stays true of that cycle, and what retires it is being wrong, not being old.

## 13. Harness hooks and model provenance

Each harness tree ships `stage_model_id.sh` (§8), `stage_memory.sh` (§12), and `stage_commit_guard.sh` (§1) in its `hooks/` directory — Pi's in `.pi/extensions/stage-hooks/`, wired by `index.ts` — and Claude Code, Codex, and Qwen Code add §7.7's involve gates. The memory hook fires on the provenance hook's event and injects only the index.

| Harness | Registered in | Event | Provenance line injects | Read |
|---|---|---|---|---|
| Claude Code | `.claude/settings.json` | `SessionStart`; `SubagentStart` for a delegate | a `--resolve` command over the session transcript, or the delegate's own; the id itself when none was named | as you write |
| Codex | `.codex/hooks.json`, running once the project is trusted and the hook approved with `/hooks` | `SessionStart` | the exact `session_model_id`, a `--resolve` command over the rollout, and the `--check` command | as you write, then after |
| Cursor | `.cursor/hooks.json` | `sessionStart` | the id | at session start |
| DSH | `.dsh/hooks.json`, enabled by `bash .dsh/hooks/install.sh` and, per profile, `dsh plugin --profile <name> add @deepseek-ai/dsh-hooks-claude-code` | `SessionStart`, through the Claude Code hook bridge | a `--resolve` command over the session log, which needs `zstd` on `PATH` | as you write |
| Kimi Code | no project config: `bash .kimi-code/hooks/install.sh`, once per machine | `UserPromptSubmit`, once per session | `default_model` from `~/.kimi-code/config.toml` | from config, never the session |
| Pi | `.pi/extensions/stage-hooks/index.ts`, loaded only in a trusted project | `before_agent_start`, again after every model change | the live id | at the prompt that uses it |
| Qwen Code | `.qwen/settings.json`, running only in a trusted folder where folder trust is on | `SessionStart` | a `--resolve` command over the transcript; the id itself when none was named | as you write |

A hook that exists is not necessarily registered: a paper repository adopted before a hook existed keeps its own registration file, which `execs/update.sh` never overwrites — it reports the gap, and the entry is added by hand. Claude Code also states the model in its system prompt, so a Claude session with no hook line is not one that names no model.

**Read the id as you write it.** A value read at write time cannot be stale; Cursor's and Kimi's can, because a model switched mid-session changes nothing they read, and Pi's last injected line is the model writing. Run the resolver a line carries at the moment of the write, with the arguments it fills in, and copy what it prints:

    bash .claude/hooks/stage_model_id.sh --resolve <transcript_path> [session_model]
    bash .codex/hooks/stage_model_id.sh --resolve <transcript_path> [session_model]
    bash .qwen/hooks/stage_model_id.sh --resolve <transcript_path> [session_model]

Each reads the runtime's own per-turn record — Claude Code's main-loop assistant turns, sidechains skipped; Codex's `turn_context` records; Qwen Code's `assistant` records. `session_model`, what `SessionStart` reported, stands in while the record names nothing; Claude Code's and Codex's readers also let it win over an identical id to keep a suffix the record drops (`claude-opus-5[1m]` over `claude-opus-5`), never over a different one, which is a mid-session switch. A delegate reads its own record, never the session's: Claude Code writes a sub-agent's turns to `<transcript dir>/<session_id>/subagents/agent-<agent_id>.jsonl` (a workflow's under `subagents/workflows/wf_<id>/`), its `SubagentStart` line names that path with no session model, and `--resolve` finds the file by name under `subagents/` when the named one is missing; Codex and Qwen Code give a subagent a record of its own.

**The post-write check.** Codex's line also supplies `bash .codex/hooks/stage_model_id.sh --check <artifact> <rollout> <session_model>`, the check §8 requires: it compares the file's `model_id` with what the resolver prints for the same rollout and session model — the rollout's last model, else the `SessionStart` value, else `unrecorded` — and exits nonzero on a mismatch or a missing `model_id`.

**When no id arrives.** Kimi's line does not reach a skill opened by slash command before any plain user message, so before writing `unrecorded` read the value once — `grep -E '^[[:space:]]*default_model[[:space:]]*=' "${KIMI_CODE_HOME:-$HOME/.kimi-code}/config.toml"` — and record it verbatim, still self-reported and possibly stale. DSH's bridge payload carries no model, so its line is always a command, and without `zstd` that command prints nothing. `unrecorded` is right only when every read here comes back empty as well (§8).
