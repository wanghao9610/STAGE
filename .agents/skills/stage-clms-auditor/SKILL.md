---
name: stage-clms-auditor
description: >-
  The numbers audit: extracts every number from manus/tabs/ and manus/secs/, traces each through
  % src: comments and claim-ledger evidence links to fingerprinted mates/ entries, and issues a
  per-number verdict — matched, mismatched, or unsourced. Flips notes/claims.md statuses
  (drafted → verified / unsourced), checks evidence staleness via import.sh --diff, writes
  wkdrs/reports/CLAIMS_<date>.md (ephemeral) and one tasks/ item per failure. Never edits the
  manuscript or mates/ — every fix routes to the skill that owns the file. Use when the user
  invokes $stage-clms-auditor, or asks whether the paper's numbers are backed by evidence, or before any
  submission freeze.
---

# Claims Auditor — every number traced to a fingerprint, or caught

**Reply language (conventions §7.6).** `.env` `STAGE_LANG=en|zh` sets chat replies and the Markdown this run writes; resolve it once at the start of the run — `grep -sE '^STAGE_LANG=' .env || true`, folded into the opening load call. Unset or empty → follow the user's dialogue language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request wins. English whatever it says: everything under `manus/`, the response to reviewers, and every structural literal — frontmatter keys, ledger statuses, IDs, paths, bibkeys, venue and metric names. Repo resources (the conventions, this skill) are loaded as-is in English; their zh-CN editions — `SKILL_zh.md` beside this file, and `writing-workflow-conventions.zh-CN.md` for the conventions — are kept in step for human readers only and are never loaded at runtime, so this SKILL.md stays authoritative.

Invocation: `$stage-clms-auditor [SECTION | CLAIM_ID]` — a section argument resolves per
conventions §5 and audits that section's numbers; a claim ID (`C7`) audits one ledger claim
everywhere its `Stated in` reaches (unknown ID → ask, conventions §7); no argument audits all of
`manus/tabs/` and `manus/secs/`.

**Shared conventions.** `docs/mds/stage-workflow/writing-workflow-conventions.md` is the baseline
every STAGE skill shares — read the whole file at the start of every run (v1 has no
section-selective loading). The sections that bind this skill hardest: §8 the artifact registry
and its staleness rule, §9 the fabrication boundary (§9a is this skill's charter), §5 resolution,
§1 git. This file states what is specific to this skill and wins wherever it is stricter.

**Reusing an earlier load.** Skip the re-read only when the same conventions file's text is still
verbatim visible in this conversation. A summary that survived a compaction, or a memory of
having read it, does not count. When in doubt, read it again — a wasted read costs one message, a
wrong assumption costs the run.

## Role

You are the mechanical heart of STAGE's evidence discipline: the auditor who walks every number
in the manuscript back to a fingerprinted file under `mates/` — or proves that it cannot be
walked. `stage-sect-drafter` and `stage-tabs-builder` state numbers; `stage-evid-curator` imports
evidence; you check that the two actually meet. You verdict, flip, and file — you never fix: not
the manuscript (`$stage-sect-drafter`, `$stage-tabs-builder`), not the evidence (`mates/` is
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
   evidence).
3. **The trace has a fixed order.** In `manus/tabs/`: the data row's own
   `% src: mates/<...>#<anchor>` comment. In `manus/secs/`: an inline `% src:` comment when the
   drafter left one, else the Evidence links of the ledger claims whose `Stated in` covers that
   file. Nothing else counts — a number merely "consistent with" a file nobody cited is unsourced.
4. **Boundary with the citation audit.** A number attributed to a cited work — a `\cite` in its
   sentence or table row — is an assertion about that work, checked by `$stage-cite-auditor`
   against reading notes (§9b). This audit still value-checks any table row whose `% src:` points
   at imported evidence; everything not attributed to a cited work is this audit's alone.
5. **Stale evidence cannot verify.** Staleness is exact stamp and content comparison, never mtime
   (conventions §8). A drifted source taints every match made against it: report
   matched-but-stale, task a re-import, and do not flip those claims to `verified`.
6. **Flips are earned — in both directions.** A claim flips `drafted → verified` only when every
   number under it matched fresh evidence and all its evidence links resolve. Any naked unsourced
   number under it → `unsourced`. A previously `verified` claim that fails today loses the status
   — back to `drafted`, with a task saying why. A mismatch never flips anything up.
7. **Single session, no `spawn_agent` (conventions §6).** The audit's value is one context that has
   seen every number and every fingerprint; a split trace is a hole in it.

## Workflow

1. **Load.** Read the conventions whole; then `notes/claims.md`, `mates/MANIFEST.md`, and
   `notes/outline.md`. Real date from the system clock (conventions §4).
2. **Resolve scope (conventions §5).** Section → its `secs/` file plus every table it `\input`s
   or `\ref`s; claim ID → every file its `Stated in` names; none → all of `manus/tabs/` and
   `manus/secs/`.
3. **Staleness gate.** Run `execs/scpts/import.sh --diff` (shell) and record the result: clean, or
   the drifted / new-upstream / missing-upstream lists. Drifted paths taint matches (Principle
   5). No STAR source configured → note it and continue; MANIFEST fingerprints remain the
   reference.
4. **Extract.** Grep every numeric token from the in-scope `.tex`. In scope: results, deltas,
   dataset and split sizes, hyperparameters, resource and timing figures — any digit asserting a
   fact about the work or the field. Excluded by class: `\ref`/`\eqref`/`\cite`/`\label`
   arguments and counters, LaTeX lengths and layout literals (`pt`, `mm`, `em`, spacing, column
   specs), package versions, equation-internal indices. Arguable → include: a wasted row costs a
   line, a skipped number costs the audit.
5. **Bin.** `\todo{}`-wrapped numbers → declared-unsourced: the legal §9a state — counted and
   ledgered, no violation task (`lint.sh` counts them; this audit explains them). Cited-work
   numbers → the `$stage-cite-auditor` handoff list (Principle 4). Everything else → trace.
6. **Trace and verify.** Per number, follow Principle 3's order; open the cited `mates/` file at
   its anchor; confirm the path has a `MANIFEST.md` entry with a fingerprint; assign the verdict
   of Principle 2.
7. **Flip the ledger.** Apply Principle 6 to every in-scope claim in `notes/claims.md`; where the
   trace found an anchor the ledger's Evidence column lacked, record it; set frontmatter
   `updated:` to the real date. Ledger flips are the audit's durable outcome (conventions §10:
   `wkdrs/` is never committed).

   When `notes/adopt.md` exists and this run audited the whole manuscript, close the adoption loop
   in the same pass: every row of its unsourced backlog must by now be either a `verified` claim or
   an `unsourced` one whose statement carries its `\todo`. All resolved → set that file's
   `backfilled:` to the real date, which is what releases `$stage-subm-packer`'s adoption gate
   (conventions §8.9); any row still a naked number → leave it empty and name those rows in the
   report. `backfilled:` is the only field of `notes/adopt.md` this skill writes, and no other skill
   writes it at all.
8. **File failures.** Append one `- [ ]` per mismatch, naked-unsourced number, stale-tainted
   match, or dead evidence link to `tasks/claims_followups.md` under a `## <date>` heading —
   location, value, verdict, route: wrong or missing upstream number → fix in STAR, re-import via
   `$stage-evid-curator`; prose or table repair → `$stage-sect-drafter` / `$stage-tabs-builder`.
   A re-run checks off items it can prove resolved (a mismatch now matched, a todo now sourced).
9. **Report.** Write `wkdrs/reports/CLAIMS_<date>.md` (`mkdir -p` first) per Output.
10. **Digest in chat.** ≤300 words: counts per verdict, staleness state, ledger flips, tasks
    filed, and the one next action.
11. **Commit (conventions §1).** One commit — `notes/claims.md`, `tasks/claims_followups.md`, and
    `notes/adopt.md` when this run set its `backfilled:` — subject naming this skill. Never
    `wkdrs/`.

## Output

- `wkdrs/reports/CLAIMS_<date>.md` — registry row: Audit reports, producer `stage-clms-auditor`,
  ephemeral, date in filename. Frontmatter `date:`, `scope:`; sections: `## Verdict` (numbers
  audited; matched / mismatched / unsourced / declared-`\todo` counts; staleness state),
  `## Trace table` — `| Where | Value | Trace | Evidence | Verdict |`, failures first,
  `## Staleness` (the `import.sh --diff` output), `## Ledger` (each flip: ID, old → new, why),
  `## Handoffs` (cited-work numbers left to `$stage-cite-auditor`), `## Tasks filed`.
- Status flips, Evidence completions, and `updated:` in `notes/claims.md`; one `- [ ]` per
  failure in `tasks/claims_followups.md` — the durable outcomes.
- Never edits `manus/`, `mates/`, or the bib: verdicts, flips, and tasks are the entire write
  surface.
