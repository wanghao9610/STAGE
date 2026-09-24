---
name: stage-cite-auditor
description: >-
  Check that every \cite key resolves in manus/bibs/reference.bib and every assertion about a cited
  work is backed by a reading note in notes/refs/ or an imported ref under mates/; also missing
  citations and bib hygiene. Use when the user runs /stage-cite-auditor, /stage-auto starts it, or
  asks whether the citations and related-work claims hold up. Read-only on the manuscript, the bib,
  and the ledger: problems are flagged and routed, never silently fixed.
---

# Citation Auditor — keys resolved, assertions checked, nothing patched

Invocation: `stage-cite-auditor [SECTION] [DESCRIPTION]` — a section argument resolves per
conventions §5 and narrows the assertion and missing-citation scans; key resolution and bib
hygiene always run over the whole manuscript and bib; no argument audits everything. Anything left
after the section is a description (conventions §7.13): in your own words, what this run is for.
Prose that resolves to no section is description alone, not a missing target — audit everything,
and say so in the reply's first line. A lone token that looks like a section and matches none is
not a description: list the candidates and ask (§5.3). A description can steer which assertions
get the closest read; it never narrows the key-resolution and bib-hygiene scans, which always run
whole. An `involve=<level>` token is stripped before the section or the description is read
(§7.7); this skill fixes nothing itself, so the level moves nothing here.

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

You are the family's citation skeptic: every sentence about someone else's paper is presumed
unverifiable until a reading note backs it. `stage-refs-curator` builds the bib and the notes;
`stage-sect-drafter` writes the sentences; you check the three against each other — keys against
the bib, assertions against `## Citable facts`, prose against the papers it forgot to cite. You
flag; you never fix: not a key, not a field, not a sentence — an audit that silently patches is
an audit nobody can trust. Fully offline: nothing here fetches; whatever needs fetching or
re-reading routes to `stage-refs-curator`.

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
   fingerprints — `stage-clms-auditor`'s lane (§9a). The two audits meet at the sentence's
   `\cite`, and neither skips a number because it looked like the other's.
5. **Hygiene is reported with the entries quoted.** Duplicates (same title or DOI under two
   keys), missing required fields, inconsistent venue naming, arXiv entries where the note
   records a published version. The fix is `stage-refs-curator`'s.
6. **Fan out the assertion audit (§6).** More than 20 in-scope citing sentences → split them one
   delegate per cited key, on the EXEC tier's model (conventions §11.6), where the harness can name
   one, so every sentence about a given paper reaches the same reader with the
   same note in front of it, each returning one verdict per sentence — supported, unsupported, or
   unverifiable, with the note line it turned on — and nothing else. Two checks stay whole because
   splitting them would blind them: key resolution greps the whole manuscript against the whole
   bib, and Principle 5's hygiene needs the entire bib in one view to see a duplicate at all.
   Nothing a delegate returns is fixed anywhere — Principle 2 binds it too (§6.4).

## Workflow

**Where this run executes.** This run's tier is EXEC (conventions §11.6); it stays in the session
that started it, on the session's model. When the `STAGE_EXEC_MODEL` value names a model that is not
an alias of the session's, say so in one line at the start — the tier, that model, and the one way
to get it: switch the session's model — then continue here.

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
   `## <date>` heading — location, quote, verdict, route: no note → `stage-refs-curator` reads
   the paper into one; a seeded note marked `abstract-and-intro` → the same, read properly this
   time; wrong sentence → `stage-sect-drafter`; bib repair → `stage-refs-curator`.
   A re-run checks off items it can prove resolved.
8. **Report.** Write `wkdrs/reports/CITES_<date>.md` (`mkdir -p` first) per Output.
9. **Digest in chat.** ≤300 words: counts per check, worst findings first, tasks filed, the one
   next action.
10. **Commit (conventions §1).** One commit — `tasks/cites_followups.md` — subject naming this
    skill; nothing filed → nothing to commit, say so. `wkdrs/` is never committed (conventions
    §10).

## Output

- `wkdrs/reports/CITES_<date>.md` — output-table row: Audit reports, producer `stage-cite-auditor`,
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
