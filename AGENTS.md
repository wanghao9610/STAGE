# Agent Instructions

Behavioral guidelines to reduce common LLM writing mistakes. They bias toward caution over speed; for trivial tasks, use judgment. This is a STAGE repository: one repo, one paper, and every number in the manuscript traces to evidence or is visibly marked as missing.

## 1. Think Before Writing

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State your assumptions explicitly. When the target is ambiguous — which section, which figure, which claim, which cycle — stop, list the candidates, and ask. Never guess which one was meant.
- If a result admits more than one reading, present them - don't pick silently.
- If the evidence supports less than the sentence would claim, say so before writing it. Push back when warranted.

## 2. Evidence Before Prose

**Nothing in the manuscript pretends to be sourced.**

- Every number in `manus/` either traces to a fingerprinted `mates/` entry read this run or is written as `\todo{...}` — no third state. A visible todo is a state; a plausible invented number is a defect.
- Every assertion about a cited paper is checkable against a reading note in `notes/refs/`, or against imported refs under `mates/`.
- Venue rules — page limits, deadlines, checklists — are entered only as user-confirmed facts. A venue's LaTeX class is the same kind of fact: it comes from the official kit the user supplies, copied byte-for-byte, never fetched and never written from memory.
- Evidence is immutable in place. A wrong number is fixed at its source and re-imported, or a corrected file is registered; never "correct" one.
- Nothing may weaken these rules to be helpful. Deadline pressure is what they are calibrated for.

## 3. Surgical Changes

**Touch only what you must. Say it once, plainly.**

- Don't "improve" adjacent prose, captions, or formatting; don't rewrite what isn't broken. Match the manuscript's voice, even if you'd write it differently.
- Never renumber sections in passing: the `<n>_` prefix binds outline rows, the ledger's `Stated in` column, and the `\input` order in `main.tex` together (conventions §5.5).
- Minimum prose that makes the point: no filler, no padding toward a page budget, no second sentence restating the first.
- The registry moves with the text it tracks — the claim row, the outline row, the notation entry — in the same change, not as cleanup after it.

The test: every changed line traces to the user's request, and every number in it to a fingerprint.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

- Turn the task into a check you can run: "draft the experiments section" -> the build passes and every number carries a `% src:` anchor or a `\todo`; "cut it to eight pages" -> `lint.sh` reports the page count under the active cycle's `page_limit_main`; "answer the reviewers" -> every point in the ledger has a response or a promise.
- For multi-step tasks, state the steps and the check that closes each one.

## 5. Writing Workflow

**This project uses the STAGE writing workflow. Its records are files, not chat history.**

- Evidence lives read-only under `mates/`, fingerprinted in `mates/MANIFEST.md`; every claim's statements, evidence, and status are one row in `notes/claims.md`.
- Run `/stage-flow-status` first when you do not know where things stand — it reads the outline, the ledger, the manifest, and the cycle state, and names the single next action.
- The rules every workflow skill follows are in `docs/mds/stage-workflow/writing-workflow-conventions.md`, read whole at the start of every run; the skill roster is its §11, and what each skill does is in `writing-workflow-skills.md`.
- Commit once per skill run, at that skill's commit step, and not otherwise (conventions §1).
- Do not hand-edit generated reports under `wkdrs/`, and do not edit `docs/mds/stage-workflow/`, the skill trees, or the `execs/` entrypoints — `execs/update.sh` overwrites them, this file included.

## 6. Reply Language

**`.env` `STAGE_LANG` sets the language of chat replies and of the Markdown a run writes** — `notes/`, `tasks/`, simulated reviews, `wkdrs/` reports. Full rule: conventions §7.6.

- Set (`en` or `zh`) → use it, whatever the chat's language. Unset or empty → follow the user's dialogue language; an explicit in-conversation request wins over both. Resolve it once per run: `grep -sE '^STAGE_LANG=' .env || true`.
- Always English whatever it says: everything under `manus/` — prose, captions, `% src:` comments, `\todo{}` text — and the response to reviewers under `cycls/<cycle>/response/`. Both are read by people outside this repository.
- Structural literals stay English inside a document written in any language: frontmatter keys and values, ledger statuses, claim and point IDs, paths, bibkeys, venue, dataset, and metric names — anything a script greps.
- An existing document keeps the language it was written in; `STAGE_LANG` governs what a run writes, never a retranslation. The `*.zh-CN.md` docs and `SKILL_zh.md` files are editions for human readers: never loaded at runtime, never authoritative.

## 7. Reply Wording

**Write the action, not its name, in any language. The reader should never have to decode a term to know what you did.**

- A name that must appear brings its meaning with it, in the same sentence.
- Exception: strings matched literally — ledger statuses, IDs, field names, paths — stay verbatim. Explain beside one, never in place of it.
- A pointer that says nothing on its own — `§9`, `C4`, `R2.W1`, a cycle name — stays verbatim and takes a few words of what it points at, in parentheses: `C4 (the zero-shot transfer claim)`. First use in every reply, not once per conversation; the reader does not scroll back.
- Technical prose, no filler and no emoji. Plain does not mean chatty.

## 8. Project Layout

**Keep files in their designated directories.** Full table and rules: conventions §10.

- Manuscript under `manus/`: entry `main.tex`; sections `secs/<n>_<slug>.tex`; figures `figs/` with sources in `figs/srcs/`; tables `tabs/`; bibliography `bibs/reference.bib`; template layers `stys/`.
- The manuscript always compiles as the preprint, and a venue's format is a generated copy: the official kit unpacks whole into `cycls/<cycle>/template/`, never under `manus/`, which `lint.sh` scans (conventions §10.4).
- Evidence under `mates/` — read-only. `execs/scpts/import.sh` and `/stage-evid-curator` are its only writers, and they only add or replace whole files with fingerprints.
- Writing metadata under `notes/`: `story.md`, `claims.md`, `outline.md`, `notation.md`, `adopt.md`, and reading notes in `notes/refs/`.
- Submission cycles under `cycls/<venue>_<year>/`. Revision scratch, promise lists, and venue follow-ups in `tasks/`: `<cycle>_promises.md` blocks a camera-ready until every box is kept; `<cycle>_venue.md` blocks nothing.
- Builds and ephemeral reports under `wkdrs/` — gitignored and regenerable. Durable outcomes go to the ledger and `tasks/`, not to reports.
- `execs/` root is closed: `run.sh` and `update.sh` only. Utilities (`import.sh`, `lint.sh`) live in `execs/scpts/`.

## 9. Project Runtime

**Use the project's entrypoints. Do not guess local paths.**

- `bash execs/run.sh` is the only build: latexmk, out-of-tree into `wkdrs/builds/`, engine from `.env` `LATEX_ENGINE`. It prints the PDF path and the page count.
- `bash execs/scpts/lint.sh` is the deterministic gate: undefined references, `\todo` count, page count against the active cycle's `venue.yml`, identity leaks when `ANON=true`. Hard failures exit non-zero.
- Runtime configuration lives in `.env`, created from `.env.example`: `STAR_HOME` (empty means standalone), `LATEX_ENGINE`, `ANON`, `STAGE_REPOSITORY`, `STAGE_LANG`. Do not hardcode machine-specific paths.
- Real dates only: every date written into an artifact comes from the system clock, never from memory or invention (conventions §4).

## 10. Project Memory

**What a session learns goes to `.stage/memory/` in the project, not to your own memory store.**

- Record a fact there only when no file in the repository already owns it — a number belongs to `mates/`, a claim to `notes/claims.md`, a page limit to the cycle's `venue.yml`, what a paper says to `notes/refs/`, a promise to `tasks/`. Memory holds the residue.
- A memory is never a source: it can never back a number in `manus/`, a venue rule, or an assertion about a cited work (§2 stands whatever a memory says).
- Offer, never assume: at most two offers per session, and write only after the user agrees. `INVOLVE=low` records unasked and says so.
- A fact true only of this machine goes to `.stage/memory/local/`, which git ignores. Where a memory disagrees with a file in the repository, the file wins.
- Types, file format, the index line the hooks parse, and how a memory is retired: `docs/mds/stage-workflow/memory_spec.md`.

## 11. Verification

**Prove the change works before calling it done.**

- Build after touching anything under `manus/`; prose that has not compiled is not finished. Run `lint.sh` when the change could move a reference, a todo count, or a page.
- Re-read every number you cite from its `mates/` file in the same run. A fingerprint you remember is not a fingerprint you checked.
- If a check cannot be run, say why and name the remaining risk.
- Report what was verified, with evidence — the PDF path and page count, the lint verdict, the ledger rows that moved — not just that it "works".
