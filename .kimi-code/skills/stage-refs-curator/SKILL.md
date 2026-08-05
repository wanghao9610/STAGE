---
name: stage-refs-curator
description: >-
  Curates the reference base: manus/bibs/reference.bib, every field transcribed from a record fetched
  this run and never from memory; reading notes notes/refs/<ABBREV>.md whose Citable facts
  /skill:stage-cite-auditor checks assertions against; and the index notes/refs/refs_index.md. Citekeys are
  <Year>_<Method>_<FirstAuthorSurname>, every entry carries a % src: line, normalization is a closed list
  (references/source-policy.md). Seeds from imported STAR refs under mates/, keeping upstream bibkeys. No
  argument surveys the base; an arXiv id, DOI, URL, or title reads one paper in, `add`
  several; `tidy` fixes hygiene offline; `position` clusters for related work; `verify` re-fetches and
  diffs every entry; `score` refreshes impact metrics. A paper with no fetchable record goes to manual
  check, never guessed in. Use when the
  user runs /skill:stage-refs-curator, when a run names it as the next action, or asks to add a reference or
  reading note, dedupe the bibliography, or position the paper against related work.
---

# Refs Curator — verified bibliography & notes the auditor can check

**Reply language (conventions §7.6).** `.env` `STAGE_LANG=en|zh` sets chat replies and the Markdown this run writes; resolve it once at the start of the run — `grep -sE '^STAGE_LANG=' .env || true`, folded into the opening load call. Unset or empty → follow the user's dialogue language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request wins. English whatever it says: everything under `manus/`, the response to reviewers, and every structural literal — frontmatter keys, ledger statuses, IDs, paths, bibkeys, venue and metric names. Repo resources (the conventions, this skill) are loaded as-is in English; their zh-CN editions — `SKILL_zh.md` beside this file, and `writing-workflow-conventions.zh-CN.md` for the conventions — are kept in step for human readers only and are never loaded at runtime, so this SKILL.md stays authoritative.

Invocation: `/skill:stage-refs-curator [PAPER | add PAPER [PAPER …] | seed | tidy | position | verify | score]` — no argument surveys `manus/bibs/reference.bib`, `notes/refs/`, and the index, audits hygiene, and proposes one next action; a bare arXiv id, DOI, paper URL, or quoted title is intake of that one paper, and `add` takes several (split on newlines and commas; a piece that is none of those forms is read whole as one title); `seed` converts imported STAR refs from `mates/`; `tidy` is offline bib hygiene; `position` clusters the base for related work; `verify` re-fetches every entry and diffs it field by field; `score` refreshes the impact metrics and nothing else. A title resolving to several records, or to none cleanly, is asked about (§7), never guessed.

**Shared conventions.** `docs/mds/stage-workflow/writing-workflow-conventions.md` is the shared baseline every STAGE skill loads: read the whole file at the start of every run — there is no section-selective loading. It binds this skill hardest at §4 (real dates — every `added:` and fetch date is real), §8 (the artifact registry and file schemas), §9 (the fabrication boundary — §9b above all: every assertion about a cited paper must be checkable against a reading note), and §1 (git). This file states what is specific to this skill and wins wherever it is stricter.

**Reusing an earlier load.** A second STAGE skill in the same conversation does not pay for the conventions twice: skip the re-read only when the same file's text is still verbatim visible in this conversation. A summary that survived a context compaction, or a memory of having read it, does not count — when in doubt, read it again.

**The file formats live beside this file.** `references/source-policy.md` fixes what this skill writes and is read before the first fetch of a run: the search order and endpoints, the three-field matching rule, the citekey shape `<Year>_<Method>_<FirstAuthorSurname>`, the `% src:` provenance line, the `%% Needs manual check` block, the closed list of permitted normalizations, the entry types and their fields, the impact-score arithmetic, the polite request rates, and the five self-audit checks. `references/venue-tiers.md` is the offline lookup the score's venue component reads. `references/refs-index-template.md` is the shape of `notes/refs/refs_index.md` — its eight sections — and is read before the index is written. A run that neither fetches nor writes the index reads neither.

## Role

You are the family's librarian. `/skill:stage-sect-drafter` writes the Related Work section from your positioning; `/skill:stage-cite-auditor` verifies every manuscript assertion about a cited work against your notes — the `## Citable facts` you write are its ground truth, so a vague fact there costs an audit later. You keep one verified bibliography and one reading note per paper worth citing, seeded from what the paired STAR project already read.

You curate; you do not audit the manuscript (`\cite` resolution and assertion checks are `/skill:stage-cite-auditor`'s), do not write related-work prose into `manus/secs/` (that is `/skill:stage-sect-drafter`'s), do not import upstream files (that is `execs/scpts/import.sh` and `/skill:stage-evid-curator`'s), and never edit anything under `mates/` (§10).

## Core Principles

1. **Every bib field has a fetched origin (§9).** Search order DBLP → Crossref → Semantic Scholar → arXiv, first match wins, published version over preprint; a match is title **and** first-author surname **and** year ±1. Fields are transcribed, never remembered, never "improved" — no invented page ranges, no guessed venues, and only the closed list of normalizations in `references/source-policy.md` is applied. Every payload is cached under `wkdrs/refs_<date>/raw/` before it is used, and every entry carries a provenance comment above it: `% src: <record URL> (fetched YYYY-MM-DD)`, `% src: mates/<...> (seeded YYYY-MM-DD)`, or `% src: user-supplied`. Keep every comment in the bib free of `@`: BibTeX scans for that character outside entries and reads `@article` inside a `%` line as the start of a new record, silently swallowing the entry beneath it — the bib parses, the key vanishes, and the failure surfaces as an undefined citation far from its cause. Write "an article-type entry", never the literal. A paper with no fetchable record goes to the `%% Needs manual check` block at the end of the bib — one line, its title and what was tried, no URL, the detail in the index's §6 — never a guessed entry. Google Scholar is not fetchable; never scrape it.
2. **Notes exist to be audited against (§9b).** `## Citable facts` is the contract with `/skill:stage-cite-auditor`: each fact one self-contained bullet — a number travels with its dataset, metric, and setting; a method or scope claim names where the paper states it (section, table, or a short quote). The test: the auditor must reach a verdict on a manuscript sentence from the note alone, without re-opening the paper. A fact not pinned to something actually read this run — or stated by the upstream STAR note it cites — does not enter.
3. **Seed first, fetch second.** When `mates/` carries an imported STAR refs tree, it is the starting base: upstream bibkeys stay stable, notes convert with `(via mates/<...>)` provenance, and entries upstream already verified are not re-fetched. Every run is incremental — fill gaps, never regenerate the bib; one note per paper, and papers already holding a note are skipped unless a refresh is asked for.
4. **Keys are load-bearing.** The citekey is `<Year>_<Method>_<FirstAuthorSurname>` — `2021_CLIP_Radford` — built per `references/source-policy.md` and unique across the file; it is the only field this skill authors. Two keys it never rewrites: a seeded one, which keeps its upstream form byte for byte, and a legacy key already in the file, from a repository adopted with its own bibliography or written before this scheme. A key `manus/` cites is never renamed here — grep first, report instead — and the mixed state is a line in the index's §8, not a silent repair. The reading note keeps its own `ABBREV` filename (`notes/refs/CLIP.md`), with the full citekey in its frontmatter `bibkey:`. User-supplied entries are never deleted: reclassified and marked, at most.
5. **Curate, do not audit or draft.** Unverifiable manuscript assertions, missing citations, and bib-versus-text drift are `/skill:stage-cite-auditor` findings; Related Work prose is `/skill:stage-sect-drafter`'s; importing upstream trees is `import.sh` + `/skill:stage-evid-curator`'s.
6. **Honest counts.** Report fetched / seeded / failed / needs-manual-check plainly; never round a shortfall up, and never present a note as deeper than what was actually read.
7. **The impact score allocates attention, never membership.** Every entry carries a 0–10 score in the index — citation rate, venue tier, code adoption, weighted by the fixed arithmetic in `references/source-policy.md`, from metrics fetched and dated this run. It says which works a cluster leads with and which ones Related Work must engage first; it never decides what enters the base, and no part of it ever enters `reference.bib`. A component nobody fetched is dropped, the remaining weights renormalize, and the total carries `*` — partial, never guessed, and never an impression.

## Workflow

### Step 0: Load

Read the conventions (whole file), then `manus/bibs/reference.bib`, `notes/refs/refs_index.md`, `notes/story.md`, `notes/claims.md`, and `mates/MANIFEST.md` (which refs trees are imported); list `notes/refs/`. Add `references/source-policy.md` when this run will fetch anything, and `references/refs-index-template.md` when it will write the index. State what the base already holds — every run is incremental. `notes/story.md` absent → `## Relation to ours` leans on the user's stated positioning; ask (§7).

### Step 1: Resolve the mode

First match wins: `seed` → Step 2; `add`, or a bare arXiv id / DOI / URL / quoted title → Step 3 per paper, Steps 4 and 7 once after the batch; `tidy` → Step 5; `position` → Step 6; `verify` → Step 6a; `score` → Step 6b; no argument → the survey: entry and note counts, entries without notes, index rows whose Note file is missing, hygiene findings (duplicates, key-scheme drift, empty required fields), and whether `mates/` holds a refs tree not yet seeded — then one proposed next action with its exact command; go no further unless asked.

### Step 2: Seed from imported STAR refs (`seed`)

1. Locate imported refs trees via `mates/MANIFEST.md` (`<slug>/metds/refs/**`). None present → say so, route to `/skill:stage-evid-curator` (or `execs/scpts/import.sh`), and stop.
2. Merge upstream `reference.bib` entries absent from `manus/bibs/reference.bib` byte-for-byte, each under a `% src: mates/<slug>/metds/refs/reference.bib (seeded YYYY-MM-DD)` line — upstream keys unchanged. Each merged entry gets its index §4 row the same run: source `mates/<slug>`, no record URL, the seed date.
3. Convert each upstream per-paper note to `notes/refs/<ABBREV>.md` in the §8 note schema: `## What it does` from the upstream note; `## Relation to ours` rewritten against this paper's `notes/story.md` and claim ledger — the STAR note related a method, this note relates a manuscript; `## Citable facts` drawn only from facts the upstream note itself states, each marked `(via mates/<slug>/...)`. Papers already holding a note are skipped and named.
4. Add one index row per converted note. `mates/` itself is never edited — read-only (§10).

### Step 3: Intake one paper

1. Fetch the record — DBLP → Crossref → Semantic Scholar → arXiv; a match means title and first-author surname and year ±1 all agree — one field agreeing is not a match. Cache the payload under `wkdrs/refs_<date>/raw/<citekey>.<source>.<ext>` before using it. No record, or several candidates and no clean winner → one line in the `%% Needs manual check` block and the detail (candidates, URLs, what was tried) in the index's §6; stop for this paper.
2. Transcribe the entry into `manus/bibs/reference.bib` under its `% src:` provenance line, citekey `<Year>_<Method>_<FirstAuthorSurname>`, only the closed list of normalizations applied. Log its index §4 row in the same run, carrying the same record URL and fetch date as the `% src:` line; mark a coined `Method` handle (†) and a preprint-only entry (‡) there.
3. Read the paper itself — arXiv abs/HTML, ACL Anthology, CVF open access, or the project page; abstract, intro, method, and main results table at minimum. Where the paper's own page names a repository, fetch its stars and last push — one call, official repos only — to complete that entry's code component. Text unfetchable → keep the bib entry, write no note — never a note from memory — and say so in the digest.
4. Write `notes/refs/<ABBREV>.md` per the §8 schema — frontmatter `title:`, `venue:`, `year:`, `bibkey:` (the full citekey), `added:` (real date, §4); `## What it does`; `## Relation to ours` against the story and claim ledger; `## Citable facts` per Principle 2. `ABBREV` is the paper's own handle (`CLIP`, `DETR`), a coined CamelCase handle when it has none, `_<year>` on collision. Add its index rows: §2 for the note, §5 for the score with every sub-signal and its fetch date.

### Step 4: Self-check the batch

Run the five checks in `references/source-policy.md` (Self-audit): every citekey has a cached payload, an index §4 row, and a `% src:` line that agrees with it; 5 entries re-fetched at random (all of them when fewer) and diffed field by field, a mismatch correcting the entry to its recorded source and re-checking the whole batch; parse, brace balance, and key uniqueness; no empty required fields; and no paper both in the `%% Needs manual check` block and in the entries, with no `@` anywhere in that block. Write the outcome into the index's §7, including which entries were corrected.

### Step 5: Tidy (`tidy`, offline)

1. Duplicates by DOI or normalized title: keep the published record's entry; when both keys are cited in `manus/`, report — never silently drop a cited key.
2. Venue-field consistency toward the file's dominant style; empty required fields filled only from each entry's recorded `% src:` origin — anything more needs a fresh fetch (Step 3.1).
3. Key hygiene under Principle 4: grep `manus/` for every key before touching it.
4. Show the full diff and ask (§7) before rewriting any existing entry.

### Step 6: Position (`position`)

1. Derive 3–8 clusters from what the base actually holds — not a taxonomy chosen in advance — and name them specifically.
2. Reorganize `reference.bib` into `%%` cluster blocks (name, entry count, one-line scope), entries preserved byte-for-byte and sorted year then key inside a block, each keeping the `% src:` line it was written with; genuine misfits go to one cross-cutting block capped at ~10%. The `%% Needs manual check` block stays last, after every cluster.
3. Rewrite the index's §3 to match — one row per cluster, counts summing to the entry count — and, inside a cluster, let the §5 scores say which works lead: those are the ones Related Work has to engage first.
4. Refresh each note's `## Relation to ours` with its cluster and one claimable clause — what this manuscript may claim relative to that work, and what it must not.
5. Report the cluster map and thin clusters as a read-next list (one `/skill:stage-refs-curator add …`); drafting Related Work from it is `/skill:stage-sect-drafter`'s.

### Step 6a: Re-check the whole bib (`verify`)

Step 4's checks over **every** entry rather than a sample of 5: re-fetch each one from the URL its index §4 row records, diff field by field, and show the full diff before any correction lands — a field the record no longer states is corrected to the record, never explained away. An entry whose source has vanished keeps its fields, gains a line in the index's §6, and is named in the digest. Nothing else changes: no new entries, no clustering, no note edits. Record the pass in the index's §7.

### Step 6b: Refresh the impact metrics (`score`)

Rebuild the index's §5 with fresh metrics; nothing else changes — no reading, no new entries, no bib edits, and no score ever reaches `reference.bib`.

1. Read the index: the citekeys, §5's rows with their sub-signals, and every official repo already named there or in a note.
2. Re-fetch citation counts for the whole bib in one batch call (`references/source-policy.md`), and stars and last push for the known official repos, serialized under the same per-host cap. No page is fetched to discover new repos — that is intake's work. An entry that cannot be resolved keeps its old value and its old date.
3. Recompute every total by the arithmetic in `source-policy.md`, rewrite §5 with the new fetch dates, and carry the new totals into §2's Score column.
4. Digest ≤200 words: entries refreshed versus kept, every paper whose score crossed a whole point, and the failures — each keeping its old value and date, never a guess.

### Step 7: Registry check and report

1. Index presence is the registry state (§8): every note has a §2 row, every §2 row's Note resolves to a file on disk, every bib entry has a §4 row and every §4 row an entry, and §6 says "none" rather than being absent when nothing failed — fix drift now. The index carries `model_id` and an appended `model_trail` entry like every artifact under `notes/` (§8).
2. Digest in chat: entries added / seeded / failed / needs-manual-check, notes written (`ABBREV` → file), hygiene fixes, the top of the score table with any partial (`*`) or `new` marks explained, legacy citekeys the scheme did not touch, the cluster map or read-next list, and routing — verify manuscript assertions → `/skill:stage-cite-auditor`; draft Related Work → `/skill:stage-sect-drafter`; import an upstream refs tree → `/skill:stage-evid-curator`.
3. Commit once for the working session, subject naming this skill (§1).

## Output

- `manus/bibs/reference.bib` — entries keyed `<Year>_<Method>_<FirstAuthorSurname>`, each under its `% src:` line, optional `%%` cluster blocks, and a `%% Needs manual check` block last for papers no record could be fetched for; appended and reorganized, never regenerated from scratch. Exact shapes: `references/source-policy.md`.
- `notes/refs/<ABBREV>.md` — one note per read paper: frontmatter `title:`, `venue:`, `year:`, `bibkey:` (the full citekey), `added:`; `## What it does`, `## Relation to ours`, `## Citable facts` precise enough to audit against (§9b).
- `notes/refs/refs_index.md` — the audit trail for the bib, in the eight sections of `references/refs-index-template.md`: scope, papers with notes, categories, provenance (one row per entry, 100% coverage, † coined and ‡ preprint marked), impact scores with their sub-signals and fetch dates, needs-manual-check detail, self-audit, next actions. Index presence is this skill's registry state field (§8).
- Chat digest per Step 7. Nothing in `manus/secs/`, nothing under `mates/`, no reports in `wkdrs/`.
- Provenance (conventions §8): every artifact this run writes under `notes/`, `tasks/`, `cycls/`, or `wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended `model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.
