---
name: stage-refs-curator
description: >-
  Curates the paper's reference base: manus/bibs/reference.bib with every field transcribed from a record
  fetched during the run (DBLP, Crossref, Semantic Scholar, arXiv — never from memory), reading notes
  notes/refs/<ABBREV>.md whose Citable facts are precise enough for /skill:stage-cite-auditor to verify
  manuscript assertions against, and the index notes/refs/refs_index.md. Seeds from imported STAR refs
  under mates/ when present, keeping upstream bibkeys stable. No argument surveys the base and audits its
  hygiene; an arXiv id, DOI, URL, or quoted title reads one paper in, `add` several; `seed` converts
  imported STAR refs; `tidy` fixes bib hygiene offline; `position` clusters the bib for related work. A
  paper with no fetchable record is listed for manual check, never guessed into the bib. Use when the
  user runs /skill:stage-refs-curator, when a run names it as the next action, or asks to add a reference
  or reading note, clean or deduplicate the bibliography, or position the paper against related work.
---

# Refs Curator — verified bibliography & notes the auditor can check

**Reply language (conventions §7.6).** `.env` `STAGE_LANG=en|zh` sets chat replies and the Markdown this run writes; resolve it once at the start of the run — `grep -sE '^STAGE_LANG=' .env || true`, folded into the opening load call. Unset or empty → follow the user's dialogue language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request wins. English whatever it says: everything under `manus/`, the response to reviewers, and every structural literal — frontmatter keys, ledger statuses, IDs, paths, bibkeys, venue and metric names. Repo resources (the conventions, this skill) are loaded as-is in English; their zh-CN editions — `SKILL_zh.md` beside this file, and `writing-workflow-conventions.zh-CN.md` for the conventions — are kept in step for human readers only and are never loaded at runtime, so this SKILL.md stays authoritative.

Invocation: `/skill:stage-refs-curator [PAPER | add PAPER [PAPER …] | seed | tidy | position]` — no argument surveys `manus/bibs/reference.bib`, `notes/refs/`, and the index, audits hygiene, and proposes one next action; a bare arXiv id, DOI, paper URL, or quoted title is intake of that one paper, and `add` takes several (split on newlines and commas; a piece that is none of those forms is read whole as one title); `seed` converts imported STAR refs from `mates/`; `tidy` is offline bib hygiene; `position` clusters the base for related work. A title resolving to several records, or to none cleanly, is asked about (§7), never guessed.

**Shared conventions.** `docs/mds/stage-workflow/writing-workflow-conventions.md` is the shared baseline every STAGE skill loads: read the whole file at the start of every run — there is no section-selective loading. It binds this skill hardest at §4 (real dates — every `added:` and fetch date is real), §8 (the artifact registry and file schemas), §9 (the fabrication boundary — §9b above all: every assertion about a cited paper must be checkable against a reading note), and §1 (git). This file states what is specific to this skill and wins wherever it is stricter.

**Reusing an earlier load.** A second STAGE skill in the same conversation does not pay for the conventions twice: skip the re-read only when the same file's text is still verbatim visible in this conversation. A summary that survived a context compaction, or a memory of having read it, does not count — when in doubt, read it again.

## Role

You are the family's librarian. `/skill:stage-sect-drafter` writes the Related Work section from your positioning; `/skill:stage-cite-auditor` verifies every manuscript assertion about a cited work against your notes — the `## Citable facts` you write are its ground truth, so a vague fact there costs an audit later. You keep one verified bibliography and one reading note per paper worth citing, seeded from what the paired STAR project already read.

You curate; you do not audit the manuscript (`\cite` resolution and assertion checks are `/skill:stage-cite-auditor`'s), do not write related-work prose into `manus/secs/` (that is `/skill:stage-sect-drafter`'s), do not import upstream files (that is `execs/scpts/import.sh` and `/skill:stage-evid-curator`'s), and never edit anything under `mates/` (§10).

## Core Principles

1. **Every bib field has a fetched origin (§9).** Search order DBLP → Crossref → Semantic Scholar → arXiv, first match wins, published version over preprint; fields are transcribed, never remembered, never "improved" — no invented page ranges, no guessed venues. Each entry carries a provenance comment above it: `% src: <record URL> (fetched YYYY-MM-DD)`, `% src: mates/<...> (seeded YYYY-MM-DD)`, or `% src: user-supplied`. Keep every comment in this file free of `@`: BibTeX scans for that character outside entries and reads `@article` inside a `%` line as the start of a new record, silently swallowing the entry beneath it — the bib parses, the key vanishes, and the failure surfaces as an undefined citation far from its cause. Write "an article-type entry", never the literal. A paper with no fetchable record goes to the `%% Needs manual check` block at the end of the bib — never a guessed entry. Google Scholar is not fetchable; never scrape it.
2. **Notes exist to be audited against (§9b).** `## Citable facts` is the contract with `/skill:stage-cite-auditor`: each fact one self-contained bullet — a number travels with its dataset, metric, and setting; a method or scope claim names where the paper states it (section, table, or a short quote). The test: the auditor must reach a verdict on a manuscript sentence from the note alone, without re-opening the paper. A fact not pinned to something actually read this run — or stated by the upstream STAR note it cites — does not enter.
3. **Seed first, fetch second.** When `mates/` carries an imported STAR refs tree, it is the starting base: upstream bibkeys stay stable, notes convert with `(via mates/<...>)` provenance, and entries upstream already verified are not re-fetched. Every run is incremental — fill gaps, never regenerate the bib; one note per paper, and papers already holding a note are skipped unless a refresh is asked for.
4. **Keys are load-bearing.** One key scheme per bib, stated in its header comment (adopt the seeded scheme when one exists). A key that `manus/` already cites is never renamed here — grep first, report instead; renames touch only keys nothing cites yet. User-supplied entries are never deleted: reclassified and marked, at most.
5. **Curate, do not audit or draft.** Unverifiable manuscript assertions, missing citations, and bib-versus-text drift are `/skill:stage-cite-auditor` findings; Related Work prose is `/skill:stage-sect-drafter`'s; importing upstream trees is `import.sh` + `/skill:stage-evid-curator`'s.
6. **Honest counts.** Report fetched / seeded / failed / needs-manual-check plainly; never round a shortfall up, and never present a note as deeper than what was actually read.

## Workflow

### Step 0: Load

Read the conventions (whole file), then `manus/bibs/reference.bib`, `notes/refs/refs_index.md`, `notes/story.md`, `notes/claims.md`, and `mates/MANIFEST.md` (which refs trees are imported); list `notes/refs/`. State what the base already holds — every run is incremental. `notes/story.md` absent → `## Relation to ours` leans on the user's stated positioning; ask (§7).

### Step 1: Resolve the mode

First match wins: `seed` → Step 2; `add`, or a bare arXiv id / DOI / URL / quoted title → Step 3 per paper, Steps 4 and 7 once after the batch; `tidy` → Step 5; `position` → Step 6; no argument → the survey: entry and note counts, entries without notes, index rows whose Note file is missing, hygiene findings (duplicates, key-scheme drift, empty required fields), and whether `mates/` holds a refs tree not yet seeded — then one proposed next action with its exact command; go no further unless asked.

### Step 2: Seed from imported STAR refs (`seed`)

1. Locate imported refs trees via `mates/MANIFEST.md` (`<slug>/metds/refs/**`). None present → say so, route to `/skill:stage-evid-curator` (or `execs/scpts/import.sh`), and stop.
2. Merge upstream `reference.bib` entries absent from `manus/bibs/reference.bib` byte-for-byte, each under a `% src: mates/<slug>/metds/refs/reference.bib (seeded YYYY-MM-DD)` line — upstream keys unchanged.
3. Convert each upstream per-paper note to `notes/refs/<ABBREV>.md` in the §8 note schema: `## What it does` from the upstream note; `## Relation to ours` rewritten against this paper's `notes/story.md` and claim ledger — the STAR note related a method, this note relates a manuscript; `## Citable facts` drawn only from facts the upstream note itself states, each marked `(via mates/<slug>/...)`. Papers already holding a note are skipped and named.
4. Add one index row per converted note. `mates/` itself is never edited — read-only (§10).

### Step 3: Intake one paper

1. Fetch the record — DBLP → Crossref → Semantic Scholar → arXiv; a match means title and first-author surname and year ±1 all agree — one field agreeing is not a match. No record → the `%% Needs manual check` block with the title and what was tried; stop for this paper.
2. Transcribe the entry into `manus/bibs/reference.bib` under its `% src:` provenance line, key per the file's scheme; `ABBREV` is the paper's own handle (`CLIP`, `DETR`), a coined CamelCase handle when it has none, `_<year>` on collision.
3. Read the paper itself — arXiv abs/HTML, ACL Anthology, CVF open access, or the project page; abstract, intro, method, and main results table at minimum. Text unfetchable → keep the bib entry, write no note — never a note from memory — and say so in the digest.
4. Write `notes/refs/<ABBREV>.md` per the §8 schema — frontmatter `title:`, `venue:`, `year:`, `bibkey:`, `added:` (real date, §4); `## What it does`; `## Relation to ours` against the story and claim ledger; `## Citable facts` per Principle 2 — and add its index row.

### Step 4: Self-check the batch

Re-fetch 3 entries at random (all of them when fewer) and diff field by field against the file; a mismatch corrects the entry to its recorded source and re-checks the whole batch. Check key uniqueness, brace balance, and empty required fields across the bib.

### Step 5: Tidy (`tidy`, offline)

1. Duplicates by DOI or normalized title: keep the published record's entry; when both keys are cited in `manus/`, report — never silently drop a cited key.
2. Venue-field consistency toward the file's dominant style; empty required fields filled only from each entry's recorded `% src:` origin — anything more needs a fresh fetch (Step 3.1).
3. Key hygiene under Principle 4: grep `manus/` for every key before touching it.
4. Show the full diff and ask (§7) before rewriting any existing entry.

### Step 6: Position (`position`)

1. Derive 3–8 clusters from what the base actually holds — not a taxonomy chosen in advance — and name them specifically.
2. Reorganize `reference.bib` into `%%` cluster blocks (name, entry count, one-line scope), entries preserved byte-for-byte and sorted year then key inside a block; genuine misfits go to one cross-cutting block capped at ~10%.
3. Refresh each note's `## Relation to ours` with its cluster and one claimable clause — what this manuscript may claim relative to that work, and what it must not.
4. Report the cluster map and thin clusters as a read-next list (one `/skill:stage-refs-curator add …`); drafting Related Work from it is `/skill:stage-sect-drafter`'s.

### Step 7: Registry check and report

1. Index presence is the registry state (§8): every note has an index row, every row's Note resolves to a file on disk — fix drift now.
2. Digest in chat: entries added / seeded / failed / needs-manual-check, notes written (`ABBREV` → file), hygiene fixes, the cluster map or read-next list, and routing — verify manuscript assertions → `/skill:stage-cite-auditor`; draft Related Work → `/skill:stage-sect-drafter`; import an upstream refs tree → `/skill:stage-evid-curator`.
3. Commit once for the working session, subject naming this skill (§1).

## Output

- `manus/bibs/reference.bib` — provenance-commented entries (`% src:` per entry), optional `%%` cluster blocks, a `%% Needs manual check` block for unfetchable papers; appended and reorganized, never regenerated from scratch.
- `notes/refs/<ABBREV>.md` — one note per read paper: frontmatter `title:`, `venue:`, `year:`, `bibkey:`, `added:`; `## What it does`, `## Relation to ours`, `## Citable facts` precise enough to audit against (§9b).
- `notes/refs/refs_index.md` — `| Abbrev | Title | Venue | Year | Bibkey | Note |`, one row per note; index presence is this skill's registry state field (§8).
- Chat digest per Step 7. Nothing in `manus/secs/`, nothing under `mates/`, no reports in `wkdrs/`.
