---
name: stage-cite-auditor
description: >-
  Citation audit: every \cite key must resolve in manus/bibs/reference.bib, and every assertion
  about a cited work must be checkable against a reading note (notes/refs/ or imported refs under
  mates/) — unverifiable or unsupported assertions are flagged, never silently fixed. Also scans
  for missing citations and bib field hygiene. Read-only on the manuscript, the bib, and the
  ledger; writes wkdrs/reports/CITES_<date>.md (ephemeral) plus tasks/ follow-ups, and routes
  every fix to $stage-refs-curator or $stage-sect-drafter. Use when the user
  invokes $stage-cite-auditor, or asks whether the citations and related-work claims hold up.
---

# Citation Auditor — keys resolved, assertions checked, nothing patched

Match the user's language in dialogue: for Chinese dialogue, reply in Chinese. All repo resources (the conventions, this skill) are English-only in v1 and are loaded as-is; zh-CN editions are on the roadmap and, when they exist, are kept in step for human readers only — this SKILL.md stays authoritative.

Invocation: `$stage-cite-auditor [SECTION]` — a section argument resolves per conventions §5 and
narrows the assertion and missing-citation scans; key resolution and bib hygiene always run over
the whole manuscript and bib; no argument audits everything.

**Shared conventions.** `docs/mds/stage-workflow/writing-workflow-conventions.md` is the baseline
every STAGE skill shares — read the whole file at the start of every run (v1 has no
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
re-reading routes to `$stage-refs-curator`.

## Core Principles

1. **§9b is the charter.** An assertion about a cited work — what it does, shows, achieves, or
   fails at — is checkable only against a reading note: `notes/refs/<ABBREV>.md`, found via the
   `refs_index.md` bibkey column, or an imported note under `mates/<slug>/metds/refs/`. No note →
   `unverifiable`; a note that does not carry the fact → `unsupported`. Never bridge the gap from
   memory: model recall of a paper is not a reading note (§9e). An empty or missing `notes/refs/`
   makes every assertion unverifiable — that is the finding, not an error.
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
   fingerprints — `$stage-clms-auditor`'s lane (§9a). The two audits meet at the sentence's
   `\cite`, and neither skips a number because it looked like the other's.
5. **Hygiene is reported with the entries quoted.** Duplicates (same title or DOI under two
   keys), missing required fields, inconsistent venue naming, arXiv entries where the note
   records a published version. The fix is `$stage-refs-curator`'s.
6. **Single session, no `spawn_agent` (conventions §6).** The audit's worth is one context that saw
   every key, every note, and every citing sentence.

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
   note (index first, imported `mates/` notes second — say which kind backed each verdict; an
   imported note is fingerprinted evidence); verdict per Principle 1, quoting the note line that
   supports or fails it.
5. **Scan for missing citations.** Prior-work claims, first-use method and dataset names, and
   borrowed numbers with no key — each with location, and the matching bib entry when one already
   exists.
6. **Check hygiene.** Principle 5's classes over the whole bib, entries quoted.
7. **File failures.** Append one `- [ ]` per undefined key, unsupported or unverifiable
   assertion, missing citation, and hygiene defect to `tasks/cites_followups.md` under a
   `## <date>` heading — location, quote, verdict, route: no note → `$stage-refs-curator` reads
   the paper into one; wrong sentence → `$stage-sect-drafter`; bib repair → `$stage-refs-curator`.
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
  `| Where | Assertion | Key | Note | Verdict |`, failures first, `## Missing citations`,
  `## Bib hygiene` (entries quoted), `## Tasks filed`.
- `tasks/cites_followups.md` — one checkbox per failure under a dated heading: the durable
  outcome.
- The manuscript, `manus/bibs/reference.bib`, `notes/refs/`, and the ledger are read-only here —
  flags and routes are the entire product.
