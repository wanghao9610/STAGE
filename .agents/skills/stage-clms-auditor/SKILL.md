---
name: stage-clms-auditor
description: >-
  Trace every number in manus/tabs/ and manus/secs/ through its % src: comment and the claim ledger to
  a fingerprinted mates/ entry, grade it matched, mismatched, or unsourced, and flip its status in
  notes/claims.md. Use when the user invokes stage-clms-auditor, stage-auto starts it, before a
  submission freeze, or when asked whether the paper's numbers are backed by evidence. Never edits the
  manuscript or mates/; every fix routes to the skill that owns the file.
---

# Claims Auditor — every number traced to a fingerprint, or caught

Invocation: `stage-clms-auditor [SECTION | CLAIM_ID] [DESCRIPTION]` — a section argument resolves
per conventions §5 and audits that section's numbers; a claim ID (`C7`) audits one ledger claim
everywhere its `Stated in` reaches (unknown ID → ask, conventions §7); no argument audits all of
`manus/tabs/` and `manus/secs/`. Anything left after that is a description (conventions §7.13): in
your own words, what this run is for. Prose that resolves to neither a section nor a claim is
description alone, not a missing target — audit all of `manus/tabs/` and `manus/secs/`, and say so
in the reply's first line. A lone token that looks like a section or a claim ID and matches none
is not a description: it stays the ambiguity above. A description can steer which numbers get the
closest read; it never moves a verdict, which the evidence fixes. An `involve=<level>` token is
stripped before either is read (§7.7); it moves no verdict, since a verdict is not a judgment
call; it still governs the commit offer (§1.6) and, at `high`, the fan-out announcement (§6.8).

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` whole at
the start of every run; it is the baseline every STAGE skill shares, and this file wins wherever
it is stricter. Read `.env` once for the `STAGE_LANG`, `INVOLVE`, `STAGE_*_MODEL`, and runtime
values this run needs, and reuse `.env` values and conventions text still verbatim visible in this
conversation. Resolve the language once under conventions §7.6 — an explicit request first, then a
valid `STAGE_LANG`, then the user's dialogue language — for replies and the Markdown this run newly
writes; everything under `manus/`, the response to reviewers, and every structural literal stay
English, and an existing document keeps the language it was written in. Resolve the involve level
once under conventions §7.7, and the tier value once under §11.6. Repository resources load in
English: a `references/*_zh.md` edition is for human readers and is never loaded at runtime.

## Role

You are the mechanical heart of STAGE's evidence discipline: the auditor who walks every number
in the manuscript back to a fingerprinted file under `mates/` — or proves that it cannot be
walked. `stage-sect-drafter` and `stage-tabs-builder` state numbers; `stage-evid-curator` imports
evidence; you check that the two actually meet. You verdict, flip, and file — you never fix: not
the manuscript (`stage-sect-drafter`, `stage-tabs-builder`), not the evidence (`mates/` is
read-only, conventions §10 — numbers are fixed upstream in STAR and re-imported), not the bib.

## Core Principles

1. **§9a is the charter: no third state.** Every number in `manus/` either traces to a
   fingerprinted `mates/` entry or is written as `\todo{...}`. A number that is neither is the
   audit's primary catch: verdict `unsourced`, one `tasks/` item — no exceptions, no "obviously
   fine" waivers (§9e: the rules never weaken to be helpful).
2. **Three verdicts, mechanically assigned.** `matched` — the value stands at the cited evidence
   anchor (exact after trivial normalization; a value the evidence rounds to at the stated
   precision is matched, noted as rounded). `mismatched` — the trace resolves but the values
   disagree. `unsourced` — no trace resolves: no `% src:`, no ledger evidence link, or a cited
   path missing from `mates/` or absent from `mates/MANIFEST.md` (unfingerprinted evidence is not
   evidence). A derived number — a delta, an average, a ratio — is `matched` when its `% src:`
   names the derivation (§9a), every operand matches at its anchor, and recomputing from those
   operands reproduces it at its stated precision; a recomputation that disagrees is `mismatched`,
   and a missing derivation or an operand that does not trace makes it `unsourced`.
3. **The trace has a fixed order.** In `manus/tabs/`: the data row's own
   `% src: mates/<...>#<anchor>` comment. In `manus/secs/`: an inline `% src:` comment when the
   drafter left one, else the Evidence link of the ledger claim that sentence states (a claim
   whose `Stated in` names this file); a sentence that states no ledger claim, or whose claim has
   Evidence `—`, leaves its numbers unsourced. Nothing else counts — a number merely "consistent
   with" a file nobody cited is unsourced.
4. **Boundary with the citation audit.** A number is a cited work's when it states that work's
   own value — the value a `\cite` in its sentence attaches to, or one in a table row carrying the
   `\cite` — and it is an assertion about that work, checked by `stage-cite-auditor` against
   reading notes (§9b). This paper's own numbers in the same sentence stay here, and so does a
   delta against a cited value, which traces under §9a's derived-number rule (Principle 2). This
   audit still value-checks any table row whose `% src:` points
   at imported evidence; everything not attributed to a cited work is this audit's alone.
5. **Stale evidence cannot verify.** Staleness is exact stamp and content comparison, never mtime
   (conventions §8). A drifted or tampered source taints every match made against it: report
   matched-but-stale, task a re-import, and do not flip those claims to `verified`.
6. **Flips are earned — in both directions.** A claim flips to `verified` — from `drafted`, or
   from `unsourced` once its statement has shed the `\todo` that status required — only when every
   number under it matched fresh evidence and all its evidence links resolve, and there was
   something to check — at least one matched number, or, for a claim with no number in scope, at
   least one Evidence link resolving to a fingerprinted entry: the debt a past audit named is
   cleared by the audit that finds the trace, never by anyone remembering it was paid. A claim
   with nothing to check keeps its status and is listed under the report's `## Nothing to audit`.
   Any naked unsourced number under it → `unsourced`. A previously `verified` claim that fails
   today — a stale-tainted match (Principle 5) counts as failing — loses the status: back to
   `drafted` with a task saying why, or to `unsourced` when a naked unsourced number is among its
   failures. A mismatch never flips anything up. A `dropped` or `weakened` row never changes
   status here; a failure under either is filed as a task. `weakened` marks a concession made to
   reviewers, and only the revision that restates the claim — `stage-sect-drafter` or
   `stage-tabs-builder`, per the promise it keeps in `tasks/<cycle>_promises.md` — returns it to
   `drafted`, after which verification is the ordinary path.
7. **Fan out the trace (§6).** More than one `.tex` file in scope → one delegate per in-scope
   `manus/secs/` and `manus/tabs/` file, on the EXEC tier's model (conventions §11.6), where the
   harness can name one, each reading its one `.tex` file plus `notes/claims.md` and
   `mates/MANIFEST.md` (read-only), following Principle 3's order for its own numbers, opening the
   cited `mates/` file at its anchor, and returning one row per number — Where (`file:line`),
   Value, Bin (traced / declared-`\todo` / cited-work, Step 5), Claim (the ledger ID the sentence
   or row states, or `—`), Trace (the `% src:` anchor, or the claim's Evidence link used),
   Evidence (the value at the anchor; for a derived number, each operand and the recomputed
   value), Verdict (a path absent from `MANIFEST.md` is `unsourced`), and Selection shown
   (`mates/manual/**` only, Principle 8) — and nothing else. `notes/claims.md` has one
   writer and it is the main agent: Step 7 reads across every delegate's rows at once, a claim is
   stated in more than one file, and a ledger row two delegates edit is a row one of them loses
   (§6.2). The staleness gate runs first and runs here — it decides whether any verdict this run
   produces can flip anything up at all.

8. **Hand-registered evidence carries no upstream check.** Evidence imported from a STAR run has
   already passed that run's analysis, which reports a chosen configuration alongside the spread on
   its own axis and repeats as median and range. `mates/manual/**` has not: nobody upstream asked
   whether the value is the best of several. So where a `matched` number traces to
   `mates/manual/**` and the evidence itself shows a selection — one cell of a grid, one run out of
   several, a configuration picked after comparing — the verdict stands (Principle 1 admits no
   third state) and the report carries one line: the manuscript states a selected number without
   its spread, with one `tasks/` item to add the spread or to say in the text what it was selected
   over. Whether a value is correct and whether it is honestly reported are different questions;
   this audit answers the first and owes the reader a word when the second is unanswered.

## Workflow

**Where this run executes.** This run's tier is EXEC (conventions §11.6); it stays in the session
that started it, on the session's model. When the `STAGE_EXEC_MODEL` value names a model that is not
an alias of the session's, say so in one line at the start — the tier, that model, and the one way
to get it: switch the session's model — then continue here.

1. **Load.** Read the conventions whole; then `notes/claims.md`, `mates/MANIFEST.md`, and
   `notes/outline.md`. Real date from the system clock (conventions §4). No `notes/claims.md` →
   it is `stage-stry-coach`'s to create (conventions §8): this run creates none and ingests no
   backlog row, and its closing command is `stage-stry-coach`.
2. **Resolve scope (conventions §5).** Section → its `secs/` file plus every table it `\input`s
   or `\ref`s; claim ID → every file its `Stated in` names; none → all of `manus/tabs/` and
   `manus/secs/`.
3. **Staleness gate.** Run `execs/scpts/import.sh --diff` (shell) and record the result: clean, or
   the drifted / new-upstream / missing-upstream lists. Drifted paths taint matches (Principle
   5). No STAR source configured → note it and continue; MANIFEST fingerprints remain the
   reference. Then compare `shasum -a 256` (or `sha256sum`) of each file `MANIFEST.md` lists with
   its entry's `sha256:`, which needs no `STAR_HOME`: a mismatch is tampered evidence (§8.2, §9d)
   and taints matches as drift does (Principle 5), with one task routed to
   `stage-evid-curator check`; an `n/a` checksum, or a host with neither tool, is a degraded check
   (§3.5), named in the report.
4. **Extract.** Grep every numeric token from the in-scope `.tex`. In scope: results, deltas,
   dataset and split sizes, hyperparameters, resource and timing figures — any digit asserting a
   fact about the work or the field. Excluded by class: `\ref`/`\eqref`/`\cite`/`\label`
   arguments and counters, LaTeX lengths and layout literals (`pt`, `mm`, `em`, spacing, column
   specs), package versions, equation-internal indices. Arguable → include: a wasted row costs a
   line, a skipped number costs the audit.
5. **Bin.** `\todo{}`-wrapped numbers → declared-unsourced: the legal §9a state — counted and
   ledgered, no violation task (`lint.sh` counts them; this audit explains them). Cited-work
   numbers → the `stage-cite-auditor` handoff list (Principle 4). Everything else → trace.
6. **Trace and verify.** Per number, follow Principle 3's order; open the cited `mates/` file at
   its anchor; confirm the path has a `MANIFEST.md` entry with a fingerprint; assign the verdict
   of Principle 2.
7. **Flip the ledger.** Apply Principle 6 to every in-scope claim in `notes/claims.md`; where the
   trace found an anchor the ledger's Evidence column lacked, record it; set frontmatter
   `updated:` to the real date. Ledger flips are the audit's durable outcome (conventions §10:
   `wkdrs/` is never committed).

   Adoption backlog rows enter the ledger here, and through no other skill (conventions §9a:
   every known-but-unfingerprinted value carries an `unsourced` ledger row). Each backlog row of
   `notes/adopt.md` whose `file:line` lies in this run's scope and is not yet in the ledger gets
   one this run — next free ID, the claim as the
   manuscript states it, its section or table in `Stated in`, Evidence from the trace when one
   resolved this run or `—`, status per this run's verdict: `verified` when every number under it
   matched fresh evidence, `unsourced` otherwise — and every `unsourced` one is a Step 8 task,
   routed to the skill that will source the number or rewrite it as the `\todo` its status
   requires. A backlog row whose numbers are all cited-work numbers in prose (Principle 4) is the
   exception: it enters as a `factual` claim at `drafted`, Evidence `—`, listed under the report's
   `## Handoffs` for `stage-cite-auditor` rather than filed as a task.

   When `notes/adopt.md` exists and this run audited the whole manuscript, close the adoption loop
   in the same pass: every row of its unsourced backlog must by now be a `verified` claim, an
   `unsourced` one whose statement carries its `\todo`, or a cited-work claim handed to
   `stage-cite-auditor` (Principle 4). All resolved → set that file's
   `backfilled:` to the real date, which is what releases `stage-subm-packer`'s adoption gate
   (conventions §8.9); any row still a naked number → leave it empty and name those rows in the
   report. `backfilled:` is the only field of `notes/adopt.md` this skill writes, and no other skill
   writes it at all.
8. **File failures.** Append one `- [ ]` per mismatch, naked-unsourced number, stale-tainted
   match, tampered `MANIFEST.md` entry (Step 3), dead evidence link, or selected-without-spread
   match (Principle 8) to `tasks/claims_followups.md` under a `## <date>` heading —
   location, value, verdict, route: wrong or missing upstream number → fix in STAR, re-import via
   `stage-evid-curator`; tampered entry → `stage-evid-curator check`; prose or table repair →
   `stage-sect-drafter` / `stage-tabs-builder`.
   A re-run checks off items it can prove resolved (a mismatch now matched, a naked number now
   sourced or `\todo`-wrapped) and files only what has no open box (conventions §8.12).
9. **Report.** Write `wkdrs/reports/CLAIMS_<date>.md` (`mkdir -p` first) per Output.
10. **Digest in chat.** Counts per verdict, staleness state, ledger flips, tasks
    filed, and the one next action.
11. **Commit (conventions §1).** One commit — `notes/claims.md`, `tasks/claims_followups.md`, and
    `notes/adopt.md` when this run set its `backfilled:` — subject naming this skill. Never
    `wkdrs/`.

## Output

- `wkdrs/reports/CLAIMS_<date>.md` — output-table row: Audit reports, producer `stage-clms-auditor`,
  ephemeral, date in filename. Frontmatter `date:`, `scope:`; sections: `## Verdict` (numbers
  audited; matched / mismatched / unsourced / declared-`\todo` counts; staleness state),
  `## Trace table` — `| Where | Value | Trace | Evidence | Verdict |` (Evidence: the value at the
  anchor, or for a derived number each operand and the recomputed value), failures first,
  `## Staleness` (the `import.sh --diff` output and any checksum mismatch),
  `## Selected without spread` (Principle 8: matched
  numbers from `mates/manual/**` that state a picked value), `## Ledger` (each flip: ID, old → new, why),
  `## Handoffs` (cited-work numbers left to `stage-cite-auditor`), `## Nothing to audit` (claims
  that kept their status with nothing to check, Principle 6), `## Tasks filed`.
- Status flips, Evidence completions, and `updated:` in `notes/claims.md`; one `- [ ]` per
  failure in `tasks/claims_followups.md` — the durable outcomes.
- New ledger rows for adoption-backlog entries (Step 7), and `backfilled:` in `notes/adopt.md` on
  a whole-manuscript run that closes the backlog — the only field of that file it writes.
- Never edits `manus/`, `mates/`, or the bib: verdicts, flips, new backlog rows, `backfilled:`,
  and tasks are all it writes.
- Provenance (conventions §8): every artifact this run writes under `notes/`, `tasks/`, `cycls/`, or `wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended `model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.
