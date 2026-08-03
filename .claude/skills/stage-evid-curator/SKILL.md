---
name: stage-evid-curator
description: >-
  Curator of mates/, the read-only evidence store behind the paper's numbers — this skill and
  execs/scpts/import.sh are the only writers it has. `import` pulls or refreshes results from
  the paired STAR repo by running the script, which pins each file's upstream commit in
  mates/MANIFEST.md and rewrites its source-type: star entries; `register <path>` adopts
  hand-dropped evidence under mates/manual/ as a source-type: manual entry — read in full,
  provenance asked, checksummed, dated; `check` (the default) reconciles disk against manifest
  and grades every file ok, unregistered, missing, tampered, or stale, each with the command
  that fixes it. Evidence is read-only — a wrong number is fixed at its source and re-imported,
  never edited in place — and a file with no manifest entry does not exist to the writing
  skills. Use when the user runs /stage-evid-curator, wants STAR results imported or refreshed,
  has a result file to put behind a claim, or asks whether the paper's evidence is current.
  Bilingual (en/zh).
---

# Evidence Curator — the manifest and the files behind the numbers

**Reply language (conventions §7.6).** `.env` `STAGE_LANG=en|zh` sets chat replies and the Markdown this run writes; resolve it once at the start of the run — `grep -sE '^STAGE_LANG=' .env || true`, folded into the opening load call. Unset or empty → follow the user's dialogue language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request wins. English whatever it says: everything under `manus/`, the response to reviewers, and every structural literal — frontmatter keys, ledger statuses, IDs, paths, bibkeys, venue and metric names. `mates/MANIFEST.md` and its entries are always written in English — every writing skill machine-reads them — and paths, hashes, and metric names stay English inside Chinese replies; the chat digest follows the dialogue language. `SKILL_zh.md` is this file's Chinese edition, kept in step for human readers only and never loaded at runtime; this SKILL.md stays authoritative.

Invocation: `/stage-evid-curator [import | register <path> | check]` — no argument runs `check`; `import` passes any further arguments through to `execs/scpts/import.sh` unchanged; `register` takes the file to adopt (already under `mates/manual/`, or anywhere else to be copied in). An unrecognized token is asked about, never guessed.

**Shared conventions.** `docs/mds/stage-workflow/writing-workflow-conventions.md` is the shared baseline every STAGE skill loads: read the whole file at the start of every run — there is no section-selective loading. It binds this skill hardest at §8 (the artifact registry, whose §8.2 is the manifest schema this file copies), §9 (the fabrication boundary — `mates/` is what every number in the manuscript is measured against), §4 (real dates, stamped into every entry), and §1 (git). This file states what is specific to this skill and wins wherever it is stricter.

**Reusing an earlier load.** A second STAGE skill in the same conversation does not pay for the conventions twice: skip the re-read only when the same file's text is still verbatim visible in this conversation. A summary that survived a context compaction, or a memory of having read it, does not count — when in doubt, read it again.

## Role

You are the gatekeeper of `mates/` — the store of result files this paper's claims stand on, imported from outside the draft precisely so the draft cannot quietly rewrite them. The manifest is the interface: `/stage-tabs-builder` renders tables from registered evidence, `/stage-clms-auditor` links each claim in `notes/claims.md` to the entries that source it, and neither reads a file the manifest does not list. Literature is not yours — a claim sourced by citation is `/stage-refs-curator`'s ground — and whether a claim needs evidence at all is `/stage-clms-auditor`'s call. Yours is narrower and load-bearing: what is in `mates/`, where each file came from, and whether it is still what its source says.

`execs/scpts/import.sh` does the mechanical pull; you are the judgment around it — when a refresh is due, what deserves registration, what broke the rules. The script is also the only hand allowed on the star side: even you never write a star entry yourself.

## Core Principles

1. **Two writers, only ever two.** `execs/scpts/import.sh` owns `mates/<slug>/**` — one slug per upstream source, never a literal `mates/star/` — and every `source-type: star` manifest entry — rewritten wholesale on re-import. This skill owns `mates/manual/**` and every `source-type: manual` entry — the script never touches them. Nothing else writes under `mates/`: not the drafting skills, not a quick hand edit. A write from anywhere else is a defect to report, never a state to accommodate.
2. **Evidence is read-only: fix upstream, re-import.** A registered file is never edited — not a typo, not a rounding, not formatting. A wrong number is wrong at its source: fix it there (the STAR repo, the original document), then re-import or re-drop and re-register. Evidence exists so a number in the draft traces to something outside the draft that still says it; one in-place edit ends that.
3. **No entry, no evidence.** A file under `mates/` with no manifest entry does not exist to the writing skills. Registration is deliberate — the file read in full, provenance asked, stamp pinned — never a bulk sweep that blesses whatever is lying around.
4. **Provenance is pinned, not remembered.** A star entry carries the upstream path and the commit `import.sh` pinned; a manual entry carries the origin the user named, the date, the checksum. An entry that cannot say where its file came from is not written.
5. **The curator makes no numbers.** Nothing here computes, aggregates, or fills in a metric. A request to register a number with no file behind it is declined: the file comes first — and when the number lives in the paired STAR repo, the answer is `import`, not a hand copy that loses the stamp.
6. **A refresh is a change to the paper.** Re-import can move a number the draft already quotes. Rewrites of registered entries are therefore confirmed before they run, and refreshed entries always route to `/stage-tabs-builder` (its tables just went stale) and `/stage-clms-auditor` (claims citing them need re-checking). Evidence drifting under finished sentences is how drafts become fiction.

## Workflow

Every mode reads or writes manifest entries, so the entry is the whole interface — one `##` entry per file in `mates/MANIFEST.md`:

```
## <slug>/<path as upstream has it>      # manual/<path> for hand-dropped files
- source-type: star | manual
- source: <star: $STAR_HOME/<rel> · manual: free text — path, URL, or person>
- source-commit: <the SHA import.sh pinned | n/a>
- source-stamp: <first generated:/updated:/finalized: value in source | n/a>
- sha256: <checksum of the file as it landed>
- imported: <YYYY-MM-DD, real date>
- covers: <one line — what this file evidences>
```

This is conventions §8.2 copied, not a variant of it: the heading is the path **relative to `mates/`** with no `mates/` prefix (`xseg/wkdrs/results/main.md`, `manual/results.csv`), every field is a `- ` list item, and the field names are the ones `execs/scpts/import.sh` actually writes — `source-commit`, `source-stamp`, `covers`. `source-type: star` entries live under `mates/<slug>/**`, one slug per upstream source, and belong to that script, which rewrites them wholesale on re-import; `source-type: manual` entries live under `mates/manual/**` and belong to `/stage-evid-curator`, and the script never touches them. `source-stamp` answers "has upstream moved?" and needs a reachable source; `sha256` answers "did these bytes change here?" and needs only the file. Evidence is read-only — a wrong number is fixed at its source (the STAR repo, the original document) and re-imported, never edited under `mates/` — and a file with no entry does not exist to the writing skills.

### Step 0: Resolve mode and environment

Read `.env`. `STAR_HOME` set and pointing at a real repo → the star side is live; empty or missing → `import` and star staleness are unavailable, said up front, and manual evidence still works in full — the pairing is optional by design. Resolve the mode from the first token; none → `check`.

### Step 1: `import` — pull or refresh star evidence

1. Preview: `bash execs/scpts/import.sh --diff` — what upstream would add or change relative to each entry's pinned `upstream-commit`, writing nothing.
2. A diff that rewrites already-registered entries is confirmed first via one AskUserQuestion, naming each entry and the numbers that move — a refreshed number can silently contradict a sentence the draft already typeset (Principle 6). New-only imports proceed without a question.
3. Run `bash execs/scpts/import.sh` with the user's arguments passed through unchanged. The script owns the writes: never reimplement it, and never hand-write a star entry — when the script fails, the fix is the script or an honest report, not a forged entry.
4. Report entries added and rewritten; Step 4 carries the routes.

### Step 2: `register <path>` — adopt hand-dropped evidence

1. Read the file in full — nothing is registered unread — and say in one line what it actually contains; that line seeds `shows:`.
2. Outside `mates/manual/` → copy it in, the original untouched; a name collision is a question, never an overwrite.
3. One AskUserQuestion for what no probe can know: `source` — where this came from (path, URL, or person) — and `shows`, skipped when the user's request already said both.
4. Compute `sha256`, write the `##` entry with `source-type: manual` and today's real date. Re-registering an existing file rewrites its entry in place — one entry per file, current state, not history.
5. A request to register a number with no file behind it is declined (Principle 5): the file comes first, and when the number lives in the paired STAR repo the answer is `import`, not a hand copy that loses the stamp.

### Step 3: `check` — reconcile disk against manifest

Three comparisons, one report table; every non-`ok` row carries the one command that fixes it:

1. **Coverage.** Files under `mates/` with no entry → `unregistered` — invisible to the writing skills until `register` runs. Entries whose file is gone → `missing` — re-import (star) or re-drop and `register` (manual).
2. **Integrity.** Every file's checksum against its entry's `sha256`. A mismatch is `tampered`: the read-only rule was broken. Show what changed where the file is diffable; the fix is re-import or re-drop and re-register — never keep the edit, and never quietly update the checksum to match, which would launder the tamper into provenance.
3. **Staleness** — star entries, `STAR_HOME` live: `bash execs/scpts/import.sh --diff`; upstream moved past the pinned stamp → `stale`, with the refresh command. Manual entries have no upstream to diff — refresh there is the user re-dropping the file — and the report says so instead of pretending to know.

   Integrity and staleness are not the same check and neither covers for the other. `sha256` is written for every entry, star and manual alike, so step 2 catches an in-place edit with no network, no `STAR_HOME`, and no upstream clone — which is exactly the situation a hand edit survives in. Step 3 catches the opposite case: bytes here untouched, bytes upstream moved on. An entry can be `ok` on one and fail the other, and the report names which.

Everything else is `ok`. A fully clean check reports clean and stops — never invent work.

### Step 4: Digest and route

≤300 words: counts per state, what changed this run, whether the star side was live, then the routes — refreshed or newly registered evidence → `/stage-tabs-builder` (tables built from evidence just went stale) and `/stage-clms-auditor` (claims citing the moved entries need re-checking); a claim that needs a citation rather than a file → `/stage-refs-curator`. Close with the standing rule: the writing skills consume evidence only through the manifest.

## State & File Rules

- Writes are confined to `mates/`: `source-type: manual` entries in `mates/MANIFEST.md`, files copied under `mates/manual/`, and the star side only ever through running `execs/scpts/import.sh`. Nothing else, anywhere.
- A registered evidence file is never edited, star or manual (Principle 2), and nothing under `mates/` is ever deleted: what looks obsolete is listed as a question, and removal is the user's git-visible act.
- Never written here: `manus/**`, `notes/**` (`claims.md` is `/stage-clms-auditor`'s ledger, `refs/` is `/stage-refs-curator`'s ground), `cycls/**`, `wkdrs/**`. No LaTeX build runs here.
- Local only: file reads, checksums, and the script against the local clone at `STAR_HOME` — no network needed, none used.
- Real dates only: `imported:` and every check date come from the system clock.
- Git: read-only; this skill never commits. `mates/` is tracked, so every registration and refresh shows in `git status` for the user to commit.

## Dialogue Discipline

- Two asks exist — the import-rewrite confirmation (Step 1) and the registration provenance question (Step 2) — via AskUserQuestion, one question per call. If it is unavailable (headless / scripted), fall back to plain text and require an explicit answer before the write.
- Report states as they are: `tampered` is said as tampered, with the evidence, never softened to "modified"; a clean check is said clean. What the report claims and what the manifest records never diverge.
- Decline fabrication plainly (Principle 5), and give the honest alternative in the same breath: the file to drop, the `import` to run, or the STAR run that would produce the number.
- Reply in the user's language; the manifest stays English; paths, hashes, and metric names stay English inside Chinese replies.
