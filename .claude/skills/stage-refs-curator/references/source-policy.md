# Source Policy — where bib records come from, and what may be changed

Every field in `manus/bibs/reference.bib` traces to a record fetched during this run, or to an upstream entry seeded from `mates/`. This file fixes where records may come from, in what order, how a record is matched to a paper, the closed list of edits allowed afterwards, and the shape of every citekey and provenance line. Read it before the first fetch.

## The one hard rule

A bib field is legal only if it appears in a machine-fetched record from a source below, or in an upstream entry copied byte for byte from `mates/`. Never write a field from model memory. Never "correct" a field the record got wrong. Never fill a missing field by inference — not the year, not the pages, not the publisher. A paper whose record cannot be fetched **does not become an entry**; it goes to the `%% Needs manual check` block described below. An entry that is 90% transcribed and 10% remembered is a fabricated entry (conventions §9).

Google Scholar is not a source here: it has no API, blocks automated queries behind CAPTCHAs, and its exported bibtex is itself machine-generated — frequently missing pages, using abbreviated venue strings, and preferring the preprint over the published record. A human may read it; this skill never scrapes it. The databases below are what a Scholar bibtex is generated *from*, so they are both fetchable and closer to the source.

## Search order

Per paper, stop at the first source that yields a matching record:

1. **DBLP** — authoritative for CS venues.
   - search: `https://dblp.org/search/publ/api?q=<query>&format=json&h=10`
   - bibtex: `https://dblp.org/rec/<key>.bib?param=1` (condensed form; `param=0` emits crossref-style entries — do not use)
   - When both a CoRR (arXiv) record and a conference/journal record exist for one title, take the published one.
2. **Crossref** — DOI-backed; journals and many proceedings.
   - `https://api.crossref.org/works/<doi>`, or `https://api.crossref.org/works?query.bibliographic=<title>&rows=5`
   - bibtex via content negotiation: `curl -LH "Accept: application/x-bibtex" https://doi.org/<doi>`
3. **Semantic Scholar** — best for coverage and citation counts. Use its `externalIds` (DOI, DBLP) to hop **back up** to sources 1–2 rather than treating it as a bib source.
   - search: `https://api.semanticscholar.org/graph/v1/paper/search?query=<q>&fields=title,year,venue,authors,externalIds,citationCount`
4. **arXiv** — only for work with no published version.
   - `http://export.arxiv.org/api/query?id_list=<id>` (Atom)
   - becomes `@misc` with `eprint`, `archivePrefix = {arXiv}`, `primaryClass`, `year`

Cache every fetched record under `wkdrs/refs_<date>/raw/<citekey>.<source>.<ext>` **before** using it. `wkdrs/` is regenerable and never committed (conventions §1.2), so the cache is what makes the run's own self-audit and a same-day re-run cheap; what outlives it is the `% src:` line in the bib and the entry's row in `notes/refs/refs_index.md`, which are tracked.

**A batch of three or more resolves its ids first.** One Semantic Scholar batch call — `POST https://api.semanticscholar.org/graph/v1/paper/batch?fields=externalIds,title,year,venue,authors`, up to 500 ids in the body, the same endpoint the score refresh uses — over every input that already carries an arXiv id or a DOI, and the `externalIds` it returns take each paper straight to its DBLP key or DOI at sources 1–2. Nothing about where a field comes from changes: the entry is still transcribed from the DBLP or Crossref record and still matched on all three fields. What goes away is the per-paper title search that produced most of the requests, and with them most of the backoff — a ten-paper `add` of arXiv ids costs one batch call and ten keyed lookups instead of ten searches. An input that is a title has no id to batch and resolves exactly as before.

## Discovery — finding candidates by topic

Everything above answers "what is the authoritative record for *this* paper". This section answers the question before it — which papers are worth looking at at all, when nobody has named one — and it is the only place in this skill where a query describes a topic instead of identifying a paper. The record rules do not loosen for it: a candidate becomes an entry only by going back through the search order above.

**Endpoints.** Relevance search, not record lookup:

- **Semantic Scholar relevance search** — `https://api.semanticscholar.org/graph/v1/paper/search?query=<q>&limit=20&fields=title,abstract,year,venue,authors,externalIds,citationCount` — the primary. Its `externalIds` hop straight back up to DBLP or Crossref when a candidate is taken in, and its `citationCount` gives the provisional score without a second call.
- **Citation-graph expansion**, once a few candidates are in hand — `https://api.semanticscholar.org/graph/v1/paper/<id>/references` and `/citations?fields=title,year,venue,citationCount` — what a close paper builds on, and what answered it. This reaches work no keyword query would surface, and it is how a thin result set is grown: more synonyms invent coverage, the citation graph finds it. **Expansion never enlarges its own input**: it runs over candidates the keyword sweep already produced, never over a paper expansion itself turned up. That is what makes it terminate, and it is why no count is needed here — one `/references` page returns a hundred nodes and every one of them expands, so a graph allowed to feed on its own finds has no last step, while one drawing from a frontier closed before the first call has nothing left to do once that frontier is walked. Expand the candidates that overlap the profile most, never the ones cited most.
- **DBLP publication search** — `https://dblp.org/search/publ/api?q=<q>&format=json&h=20` — better recall on venue- and author-shaped queries.
- **arXiv full-text query** — `http://export.arxiv.org/api/query?search_query=all:<q>&max_results=20` — reaches work too recent for the others to have indexed.

**Queries.** Built from the search profile and varied in kind rather than in wording, and the kinds are the floor: the task's own terms, the mechanism's terms, the synonyms the field actually uses (a query in only your vocabulary finds only the papers that share it), benchmark and dataset names, and the "X for Y" shape papers title themselves with — one query per kind that applies to this paper, none dropped for looking unpromising. Saturation is the ceiling, not a count: keep going while a query still returns candidates the earlier ones did not, and end the sweep when one comes back entirely already-seen. Log every query with the number of hits it returned — the zero-hit ones included, because "we looked and found nothing" and "we never looked" are different states and only one of them is a reason to stop. The log is also what makes the stopping condition checkable afterwards: a sweep that ended dry shows it, and one that stopped early shows that too.

**Termination.** Nothing here is rationed by a request quota. A quota would be a number nobody could defend and nobody could check the log against; each mechanism carries a stopping condition instead, and every one of them is visible in what the run writes down. The sweep stops when a query comes back entirely already-seen. Expansion stops because its input was closed before it began. What follows the author's pick stops when the picked papers are taken in — that count is the author's decision, not something this file rations. No step can run forever, and no step hands a counter to the next. Politeness is a separate question of a different kind — a rate, discharged by the per-host rates below, never by a total. A mechanism that stops names the condition that stopped it: gone dry, frontier walked, or the host refusing. Never quietly topped up from memory.

**Anonymity.** When the active cycle's `venue.yml` carries `anonymized: true`, or `.env` sets `ANON=true`, queries carry topic terms only: never the manuscript's title, never a verbatim sentence from it, never a guess at an author. A query leaves this machine, and one built out of the paper's own sentences can identify an anonymous submission to whoever holds the logs.

**A search hit is a lead, not a fact.** Nothing from a search payload is transcribed into `reference.bib`: the title in a hit is often the preprint's, the venue field is often empty or wrong, and the author list is often truncated. A candidate the user picks is re-fetched from the top of the search order and matched on all three fields like any other paper, and one whose authoritative record then fails to resolve does not become an entry. Absence is symmetrical — nothing returned is a fetch outcome, never evidence that no such work exists.

## Matching a record to the paper

A record matches only when all three agree:

- **title** — case- and punctuation-insensitive, subtitle included;
- **first-author surname**;
- **year** — ±1, to absorb the arXiv-to-proceedings gap.

One or two fields agreeing is not a match — near-duplicate titles across a workshop paper, its extension, and a survey are common. Ambiguous → do not guess: the paper goes to the `%% Needs manual check` block, its candidates and their URLs to the index's §6.

## Resolving a title

A paper may be named by title alone, so the title is all there is to match on. Resolution uses the search endpoints above (DBLP search, Crossref `query.bibliographic`, Semantic Scholar search) and the matching rule's normalization: case- and punctuation-insensitive. The input resolves when exactly one paper's record title equals it — the full title, or the main title before a subtitle's colon. Several distinct papers matching (a workshop paper and its extension are the classic pair), or best hits that only nearly match → ask, one direct question listing each candidate's title, venue, year, and URL; found nowhere → the needs-manual-check block. A resolved title is from then on just a paper: its record goes through the search order, the three-field matching rule, and published-over-preprint like any other.

## Published over preprint

Prefer the published record whenever one exists; the arXiv id survives only if the fetched record already carries it. arXiv-only work is legitimate and included — marked `preprint` (‡) in the index, typed `@misc`.

## Citekey

`<Year>_<Method>_<FirstAuthorSurname>` — e.g. `2021_CLIP_Radford`, `2023_SAM_Kirillov`.

- **Year** — the year of the record being cited (the published year when the published record won).
- **Method** — the paper's own abbreviation, as the paper writes it (`CLIP`, `DETR`, `SAM`). None → coin a compact CamelCase handle from the title (`MaskDistill`) and mark it coined (†) in the index.
- **FirstAuthorSurname** — ASCII, no diacritics, no spaces: `Müller` → `Mueller`, `van den Berg` → `vandenBerg`.
- Collision → append a lowercase letter (`2021_CLIP_Radforda`). Keys are unique across the file.

The citekey is the only field you author. Everything else is transcribed.

Two keys this scheme does not touch. An entry **seeded from `mates/`** keeps its upstream key byte for byte: the key is what ties the entry to the imported file it came from, and a rewritten key breaks that tie and the `% src:` line that records it. And a **legacy key already in the file** — from a repository adopted with its own bibliography, or written before this scheme — stays as it is: renaming a key `manus/` cites breaks the citation, and this skill never edits `manus/secs/`. New entries take the scheme; the mixed state is reported in the index's §8, not repaired silently.

The `ABBREV` a reading note is named for is a different string and stays what it is — `notes/refs/CLIP.md` beside citekey `2021_CLIP_Radford`, the `Method` segment being the tie between them. The note's frontmatter `bibkey:` carries the full citekey.

## Provenance comment — `% src:`

One line directly above each entry, carrying the same origin the index's Provenance table logs:

- A fetched record: `% src: <record URL> (fetched YYYY-MM-DD)` — the URL and the date identical to that entry's index row.
- An entry merged from an imported refs tree under `mates/`: `% src: mates/<slug>/metds/refs/reference.bib (seeded YYYY-MM-DD)`.
- An entry the user added by hand, with no fetched record: `% src: user-supplied`.

Strip any `mailto` parameter from the URL before writing it, because no comment in `reference.bib` may contain `@`. BibTeX scans for that character outside entries too, and reads `@article` inside a `%` line as the start of a new record, silently swallowing the entry beneath it — the bib parses, the key vanishes, and the failure surfaces as an undefined citation far from its cause. Name a type as "an article-type entry", never as the literal.

The comment belongs to the entry, not to its place in the file: reclassifying moves the two together, and an entry copied in from upstream arrives with its origin attached.

## Needs-manual-check block — `%% Needs manual check`

A paper with no fetchable authoritative record is not written as an entry; it is written as a comment line in this block. The block is last in the file, after every category block:

```text
%% Needs manual check — 2 papers, no authoritative record as of 2026-08-05
% "Learning to Segment Everything with Less" — no matching record in DBLP / Crossref / Semantic Scholar / arXiv; see refs_index.md section 6
% "Prompt Tuning for Dense Prediction" — three near-identical candidate titles, undecidable; candidates and URLs in refs_index.md section 6
```

One line per paper: the title, plus what was tried or what it is stuck on. Never a commented-out entry — a `%` line holding a record's opening brace is exactly the character the section above warns about, and a commented-out entry is both the form most likely to be reached for and the most expensive one to write. Keep URLs out for the same reason; the detail lives in the index's §6 and the line points there.

Once a record is fetched the paper becomes a real entry and its line leaves the block. It is never in both places.

## Normalization — the closed list

Permitted, and nothing beyond:

- Replace the source's key with the citekey.
- Drop noise fields: `bibsource`, `biburl`, `timestamp`, `abstract`, `keywords`, `url` when it merely restates the DOI, `month` when the venue already fixes it.
- Brace-protect capitals BibTeX would lowercase: `{CLIP}`, `{ImageNet}`, `{T}ransformer`. This changes rendering, not content.
- Expand a venue abbreviation **using the name already present in the fetched record**: DBLP's `booktitle` normally spells out `IEEE/CVF Conference on Computer Vision and Pattern Recognition (CVPR)`, so writing that is transcription. Inventing a full name the record never contained is not.

Not permitted: adding pages, editors, publishers, volumes, DOIs, or a year the record lacks; "fixing" author initials or name order; merging fields from two records for one paper (pick one record; the index says which).

## Entry types and fields

- `@inproceedings` — proceedings: `author`, `title`, `booktitle`, `year`, plus `pages` / `publisher` when present.
- `@article` — journal: `author`, `title`, `journal`, `year`, plus `volume` / `number` / `pages` when present.
- `@misc` — arXiv-only: `author`, `title`, `year`, `eprint`, `archivePrefix`, `primaryClass`.
- `@book`, `@incollection` — as the record states.

These literals are safe here: the rule against `@` binds comments inside `reference.bib`, where BibTeX is scanning, not a policy document nothing parses.

AI-conference templates (NeurIPS / CVPR / ICML / ICLR / ACL) render author, title, booktitle/journal, year, pages, volume, publisher. Keep those when the record has them; do not pad the rest.

## Impact score (0–10) — an index signal, never a bib field

The second axis beside relevance: how much attention the field has paid a work. It sets emphasis — which entries the index surfaces, which works `position` puts at the head of a cluster, which ones Related Work must engage first — and never decides what belongs in the base. Every input is a metric fetched during a run and logged in the index with its fetch date; the synthesis is the fixed arithmetic below and nothing else. No impression enters a score, and no component of it ever enters `reference.bib`.

**score = 0.40 × citation + 0.25 × venue + 0.35 × code**, one decimal, log-stepped bins per component:

- **Citation** — cites per year, `c = citationCount ÷ (current year − publication year + 1)`, from the Semantic Scholar record already in hand: `c ≥ 1000 → 10`, `≥ 300 → 9`, `≥ 100 → 8`, `≥ 30 → 6`, `≥ 10 → 4`, `≥ 3 → 2`, else `1`. Lifetime counts favor old papers; the per-year rate is what lets a 2024 paper stand beside a 2017 one.
- **Venue** — the tier table in `venue-tiers.md`, matched against the fetched record's venue field: flagship `10`, second tier `7`, other published `4`, preprint-only `2`.
- **Code** — no official repo → `0`. An official repo — one the paper's own page names; a repo found anywhere else is logged `unofficial` and scores nothing — starts at `4`, plus stars `≥ 10k → +5`, `≥ 3k → +4`, `≥ 1k → +3`, `≥ 300 → +2`, else `+1`, plus `+1` if pushed within 12 months; capped at `10`.

Three rules ride every score:

- **Partial, never guessed.** A component with no fetched metric is dropped and the remaining weights renormalize; the total carries `*` (`6.4*`). An entry whose paper text was never fetched has no code signal by construction.
- **Dated, because metrics drift.** Every sub-signal carries its fetch date in the index; the `score` mode re-fetches the metrics and rebuilds the table.
- **`new` is a flag, not a verdict.** A paper ≤ 18 months old is marked `new` beside its score: its citation rate is not settled, and prose treats a low-scored `new` paper as unproven, not ignorable.

The bins and weights are calibrated for CS/AI literature and live here precisely so a project in another field can retune them. The constants are editable; the no-impressions rule is not.

### Where the metrics come from

- **Citation counts** ride the Semantic Scholar calls already listed — `citationCount` is in the search field list, so intake pays nothing extra. The `score` mode refreshes the whole bib in one call: `POST https://api.semanticscholar.org/graph/v1/paper/batch?fields=citationCount,year,externalIds`, up to 500 ids in the body (`{"ids": ["DOI:…", "ARXIV:…", …]}`), the ids taken from the provenance the index already holds. An entry the batch cannot resolve keeps its old value and date.
- **Venue tier** is offline: the fetched record's venue field against `venue-tiers.md`.
- **Stars and last push** — `https://api.github.com/repos/<owner>/<repo>` → `stargazers_count`, `pushed_at`. Cache the response as `<citekey>.github.json` before use. Unauthenticated GitHub allows **60 requests/hour** — the binding cap, still several times the repos one run should need; serialize ~1/s like every host. A 403/429 here usually *is* the hourly cap: back off once, then record the failure and mark the component unfetched — a partial score, never a retry loop, never a number from memory.

**Official repos only.** A repo qualifies only when the paper's own page names it: the arXiv abs page, the project page, or the paper's PDF/HTML itself. Discovery order: the paper page the intake step reads anyway → the arXiv abs page → the paper's Hugging Face papers page (`https://huggingface.co/papers/<arxiv-id>`). Papers with Code shut down in July 2025 — do not fetch it. A repo surfaced any other way (code search, a citing repo's README) is logged `unofficial` in the index and never scored.

## Rate limits and failure

- Serialize per host: ~1 request/second to DBLP and Semantic Scholar, ~3/second to Crossref (add a `mailto` for its polite pool, and strip it again before the URL is written into a `% src:` line). The budget belongs to the whole session against each host.
- Paper pages — arXiv abs/HTML, ACL Anthology, CVF open access, project pages — follow the same polite default: ~1 request/second, and ~1 per 3 seconds to arXiv, which asks for that.
- **A reading fan-out divides the rate, not the quota** (conventions §6.9). Each delegate's brief states, as a number of seconds, how long it waits between its own requests to a host: the interval above multiplied by how many delegates this fan-out dispatched. Three readers of arXiv pages each wait 9 seconds, so the run as a whole still asks arXiv for one page every 3. There is no fixed cap — the width is the main agent's call and the brief carries the number it produced — and every fetch on this page other than a delegate's own paper pages is the main agent's.
- HTTP 429 / 503 → exponential backoff (2s, 4s, 8s), at most 3 retries, then move on and record the failure. A rate limit is never a reason to fill the gap from memory.
- A source returning nothing is logged as "not found in `<source>`" — that is a fetch outcome, not evidence the paper does not exist.

## Reading collector contract

What a delegate does, and what it returns, when the reading step fans out (SKILL.md Principle 9). One paper each. The delegate fetches that paper's own pages itself — conventions §6.9 — waiting between its own requests the seconds its brief states, and caching every payload under the prefix its brief names before reading it. It opens no other URL: not a bibliographic record, not a search endpoint, not the GitHub API, all of which stay with the main agent.

**It writes one repository file: the note its brief names.** `notes/refs/<ABBREV>.md`, and no other — one paper, one file, one writer (conventions §6.2). The filename is assigned in the brief rather than chosen here, because whether it is unique across `notes/refs/` is only visible to the main agent. The note carries `## What it does`, `## Citable facts`, and `## Relation to ours`, that last one written against the story and the claim ledger the brief supplies. It carries no `bibkey:` and no `added:`, no index row, and no impact score: those live in `reference.bib` and `refs_index.md`, single files with a single writer.

**§9b binds whoever writes the bullet, and here that is you.** A `## Citable facts` bullet is a manuscript assertion waiting to happen, and `/stage-cite-auditor` will later reach a verdict on a manuscript sentence from your note alone, without re-opening the paper. So every bullet is one self-contained fact — a number travelling with its dataset, metric, and setting — naming the section, table, or equation it came from, and carrying at most 25 words copied character for character out of the cached page. A fact you cannot pin to something you read this run does not go in the file, and a paraphrase presented as a quote is the failure this rule exists for.

Then return exactly these fields and nothing else:

- `note_path` — the file you wrote, or `none` with the reason in `failures`.
- `abbrev` — the handle your brief assigned, echoed back.
- `facts` — how many `## Citable facts` bullets the note carries.
- `floor_evidence` — `{sections_reached: [...], results_table: <the caption plus one row, verbatim>}`, or `not reached`. The floor is abstract, intro, method, and main results table; a paper that genuinely has no results table says so here and names what stands in its place. `not reached` means you wrote no note — say so in `note_path`, and the bib entry stands alone.
- `repo_named` — the repository this paper's own page names, or `none found`. You do not fetch it; the one GitHub call is the main agent's.
- `pages_fetched` — `[{url, cache_path, status}]`, one row per request you made, in the order you made them.
- `failures` — `[{what, why, host, retries}]`: a page that would not load, a section the fetched page did not contain, a table that would not parse, a scan with no extractable text.

**What the main agent does with the returns.** Per paper, the three things no delegate ever opens: the `refs_index.md` row, the `% src:` provenance line above the bib entry, and the impact score. `floor_evidence: not reached` is the same outcome as a text that could not be fetched at all — the bib entry stands and no note exists. A return claiming the floor was reached while naming no `note_path`, or reporting `facts` above zero with a note that is not on disk, contradicts itself, and that paper is read again here (conventions §6.3). Nothing in any return ever reaches `reference.bib`, whose fields came from the bibliographic record and not from the paper's own page.

## Self-audit before finishing

1. Every citekey in `reference.bib` has a cached record in the run dir **and** a provenance row in `refs_index.md` **and** a `% src:` line above the entry carrying that row's URL and date. A seeded entry's row says `mates/<...>`; a user-supplied entry's row says so.
2. Re-fetch 5 entries at random (all of them in `verify` mode); diff field-by-field against the file. Any mismatch → correct the file to match the source, then re-check that entry's whole batch.
3. Parse the file with a bib parser if one is already installed; otherwise check brace balance and key uniqueness mechanically. Never install one to run this check — say it was done by hand.
4. No entry has an empty required field; no key appears twice.
5. No paper in the `%% Needs manual check` block also appears as an entry; no line in that block contains `@`.
