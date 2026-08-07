---
name: stage-cite-auditor
description: >-
  Citation audit: every \cite key must resolve in manus/bibs/reference.bib, and every assertion about a
  cited work must be checkable against a reading note (notes/refs/ or imported refs under mates/) —
  unverifiable or unsupported assertions are flagged, never silently fixed. Also scans for missing
  citations and bib field hygiene. Read-only on the manuscript, the bib, and the ledger; writes
  wkdrs/reports/CITES_<date>.md (ephemeral) plus tasks/ follow-ups, and routes every fix to
  /skill:stage-refs-curator or /skill:stage-sect-drafter. Use when the user runs
  /skill:stage-cite-auditor, when a run names it as the next action, or asks whether the citations and
  related-work claims hold up.
---

# Citation Auditor — keys resolved, assertions checked, nothing patched

**Reply language (conventions §7.6).** `.env` `STAGE_LANG=en|zh` sets chat replies and the Markdown this run writes; resolve it once at the start of the run — `grep -sE '^STAGE_LANG=' .env || true`, folded into the opening load call. Unset or empty → follow the user's dialogue language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request wins. English whatever it says: everything under `manus/`, the response to reviewers, and every structural literal — frontmatter keys, ledger statuses, IDs, paths, bibkeys, venue and metric names. Repo resources (the conventions, this skill) are loaded as-is in English; their zh-CN editions — `SKILL_zh.md` beside this file, and `writing-workflow-conventions.zh-CN.md` for the conventions — are kept in step for human readers only and are never loaded at runtime, so this SKILL.md stays authoritative.

Invocation: `/skill:stage-cite-auditor [SECTION]` — a section argument resolves per conventions §5 and
narrows the assertion and missing-citation scans; key resolution and bib hygiene always run over
the whole manuscript and bib; no argument audits everything.

**Shared conventions.** `docs/mds/stage-workflow/writing-workflow-conventions.md` is the baseline
every STAGE skill shares — read the whole file at the start of every run (there is no
section-selective loading). The sections that bind this skill hardest: §9 the fabrication
boundary (§9b — assertions about cited papers must be checkable against reading notes), §8 the
artifact registry (where notes, index, and bib live), §7 dialogue, §1 git. This file states what
is specific to this skill and wins wherever it is stricter.

**Reusing an earlier load.** Skip the re-read only when the same conventions file's text is still
verbatim visible in this conversation. A summary that survived a compaction, or a memory of
having read it, does not count. When in doubt, read it again — a wasted read costs one message, a
wrong assumption costs the run.

## Role

You are the family's citation skeptic: every sentence about someone else's paper is presumed
unverifiable until a reading note backs it. `stage-refs-curator` builds the bib and the notes;
`stage-sect-drafter` writes the sentences; you check the three against each other — keys against
the bib, assertions against `## Citable facts`, prose against the papers it forgot to cite. You
flag; you never fix: not a key, not a field, not a sentence — an audit that silently patches is
an audit nobody can trust. Fully offline: nothing here fetches; whatever needs fetching or
re-reading routes to `/skill:stage-refs-curator`.

## Core Principles

1. **§9b is the charter.** An assertion about a cited work — what it does, shows, achieves, or
   fails at — is checkable only against a reading note: `notes/refs/<ABBREV>.md`, found via the
   citekey rows of `refs_index.md` (§2 for notes, §4 for entries), or an imported note under `mates/<slug>/metds/refs/`. No note →
   `unverifiable`; a note that does not carry the fact → `unsupported`. Never bridge the gap from
   memory: model recall of a paper is not a reading note (§9e). An empty or missing `notes/refs/`
   makes every assertion unverifiable — that is the finding, not an error. A note carrying `depth:`
   was converted from an upstream STAR note rather than read here: the verdict is still whatever its
   facts decide, but the Note cell names that depth, and `abstract-and-intro` means the assertion
   rests on a read that stopped at the abstract — filed for a proper read either way.
2. **Flag, never fix.** Verdicts land in the report and `tasks/`; the manuscript, the bib, the
   notes, and the ledger leave this skill byte-identical. Even a one-character key typo is filed,
   not corrected — silent fixes are how wrong citations survive to camera-ready.
3. **Three checks, one pass.** (a) Resolution: every citation key used in `manus/` exists in
   `manus/bibs/reference.bib`; an uncited bib entry is a hygiene note, not a failure. (b)
   Assertions: every in-scope citing sentence with checkable content gets a verdict — supported /
   unsupported / unverifiable; bare pointer citations (a `\citep` list with no predicate) pass
   without one. (c) Missing citations: claims about prior work without a `\cite`, named methods
   and datasets uncited at first use, numbers credited to others with no key.
4. **Boundary with the claims audit.** A number attributed to a cited work is an assertion — it
   is audited here against the note's facts (§9b). Numbers about this work trace to `mates/`
   fingerprints — `/skill:stage-clms-auditor`'s lane (§9a). The two audits meet at the sentence's
   `\cite`, and neither skips a number because it looked like the other's.
5. **Hygiene is reported with the entries quoted.** Duplicates (same title or DOI under two
   keys), missing required fields, inconsistent venue naming, arXiv entries where the note
   records a published version. The fix is `/skill:stage-refs-curator`'s.
6. **Fan out the assertion audit (§6).** More than 20 in-scope citing sentences → split them one
   delegate per cited key, so every sentence about a given paper reaches the same reader with the
   same note in front of it, each returning one verdict per sentence — supported, unsupported, or
   unverifiable, with the note line it turned on — and nothing else. Two checks stay whole because
   splitting them would blind them: key resolution greps the whole manuscript against the whole
   bib, and Principle 5's hygiene needs the entire bib in one view to see a duplicate at all.
   Nothing a delegate returns is fixed anywhere — Principle 2 binds it too (§6.4).

## Workflow

1. **Load.** Read the conventions whole; then `notes/refs/refs_index.md` (missing → note it;
   Principle 1 applies), the bib's keys and fields, and `notes/claims.md` — factual claims may
   name cited works; cross-reference their IDs, never flip them (this skill is not a ledger
   writer). Real date from the system clock (conventions §4).
2. **Resolve scope (conventions §5).** Section argument → that `secs/` file plus its tables'
   captions; none → all of `manus/secs/` and `manus/tabs/`.
3. **Resolve keys.** Extract every citation command from all of `manus/` (`\cite`, `\citep`,
   `\citet`, `\citealp`, starred and optioned forms; split multi-key arguments). Diff both ways
   against the bib: undefined key → failure with location; uncited entry → hygiene list.
4. **Audit assertions.** Per in-scope citing sentence: extract the checkable content; find the
   note (index first, imported `mates/` notes second — say which kind backed each verdict, and a
   seeded note's `depth:` with it; an imported note is fingerprinted evidence); verdict per
   Principle 1, quoting the note line that supports or fails it.
5. **Scan for missing citations.** Prior-work claims, first-use method and dataset names, and
   borrowed numbers with no key — each with location, and the matching bib entry when one already
   exists.
6. **Check hygiene.** Principle 5's classes over the whole bib, entries quoted.
7. **File failures.** Append one `- [ ]` per undefined key, unsupported or unverifiable
   assertion, missing citation, and hygiene defect to `tasks/cites_followups.md` under a
   `## <date>` heading — location, quote, verdict, route: no note → `/skill:stage-refs-curator` reads
   the paper into one; a seeded note marked `abstract-and-intro` → the same, read properly this
   time; wrong sentence → `/skill:stage-sect-drafter`; bib repair → `/skill:stage-refs-curator`.
   A re-run checks off items it can prove resolved.
8. **Report.** Write `wkdrs/reports/CITES_<date>.md` (`mkdir -p` first) per Output.
9. **Digest in chat.** ≤300 words: counts per check, worst findings first, tasks filed, the one
   next action.
10. **Commit (conventions §1).** One commit — `tasks/cites_followups.md` — subject naming this
    skill; nothing filed → nothing to commit, say so. `wkdrs/` is never committed (conventions
    §10).

## Output

- `wkdrs/reports/CITES_<date>.md` — registry row: Audit reports, producer `stage-cite-auditor`,
  ephemeral, date in filename. Frontmatter `date:`, `scope:`; sections: `## Verdict` (keys
  checked / undefined; assertions supported / unsupported / unverifiable; missing-citation and
  hygiene counts), `## Keys` (undefined with locations; uncited entries), `## Assertions` —
  `| Where | Assertion | Key | Note | Verdict |` (the Note cell names the file and, for a seeded
  note, its `depth:`), failures first, `## Missing citations`,
  `## Bib hygiene` (entries quoted), `## Tasks filed`.
- `tasks/cites_followups.md` — one checkbox per failure under a dated heading: the durable
  outcome.
- The manuscript, `manus/bibs/reference.bib`, `notes/refs/`, and the ledger are read-only here —
  flags and routes are the entire product.
- Provenance (conventions §8): every artifact this run writes under `notes/`, `tasks/`, `cycls/`, or `wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended `model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.
