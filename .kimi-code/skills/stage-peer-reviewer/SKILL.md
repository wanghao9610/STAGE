---
name: stage-peer-reviewer
description: >-
  Simulated program committee for the manuscript: convenes a five-perspective review panel — novelty &
  related work, technical soundness, experimental rigor & reproducibility, clarity & presentation,
  devil's advocate — under a citation-integrity contract (whitelist or verified references only, every
  search logged), scores by anchored rubric bands with hard caps and an honest confidence (6-point
  conference scale or journal tiers per venue.yml scale:), and writes one venue-shaped meta-review to
  cycls/<cycle>/reviews/SIM_REVIEW_<date>.md whose weaknesses name the claim IDs they attack — so
  /skill:stage-resp-writer treats simulated and real reviews identically. quick mode runs a single pass.
  Builds first via execs/run.sh; a broken build is finding #1. Never edits the manuscript or the ledger.
  Use when the user runs /skill:stage-peer-reviewer, when a run names it as the next action, or asks for
  a mock review, a review panel, a pre-submission attack on the draft, or for the paper to be read as
  reviewers would.
---

# Peer Reviewer — a five-perspective panel with an anchored rubric

**Reply language (conventions §7.6).** `.env` `STAGE_LANG=en|zh` sets chat replies and the Markdown this run writes; resolve it once at the start of the run — `grep -sE '^STAGE_LANG=' .env || true`, folded into the opening load call. Unset or empty → follow the user's dialogue language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request wins. English whatever it says: everything under `manus/`, the response to reviewers, and every structural literal — frontmatter keys, ledger statuses, IDs, paths, bibkeys, venue and metric names. Repo resources (the conventions, this skill) are loaded as-is in English; their zh-CN editions — `SKILL_zh.md` beside this file, `references/*_zh.md`, and `writing-workflow-conventions.zh-CN.md` for the conventions — are kept in step for human readers only and are never loaded at runtime, so this SKILL.md stays authoritative.

Invocation: `/skill:stage-peer-reviewer [MODE]` — `MODE` is `panel` (default) or `quick`; the cycle is
the active one from `notes/story.md` (conventions §5); an `involve=<level>` token is stripped
before the mode is read (§7.7).

**Shared conventions.** `docs/mds/stage-workflow/writing-workflow-conventions.md` is the baseline
every STAGE skill shares — read the whole file at the start of every run; there is no
section-selective loading. The sections that bind this skill hardest: §2 the STOP line, §5
cycle resolution, §6 delegation (the panel is this workflow's largest sanctioned fan-out, and
§6.9 is why the panelists do not fetch), §8 the artifact registry, §9 the fabrication
boundary — §9b's review-side extension is this skill's charter.
This file states what is specific to this skill and wins wherever it is stricter.

**Reusing an earlier load.** Skip the re-read only when the conventions file's text is still
verbatim visible in this conversation. A summary that survived a context compaction, or a memory
of having read it, does not count — when in doubt, read it again.

**This skill's references.** `references/review-dimensions.md` — the five perspective briefs and
the two contracts (citation-integrity, collector); `references/review-template.md` — the four
artifact templates; `references/rubric-conference.md` — the six anchored bands, confidence, and
the caps table; `references/rubric-journal.md` — decision tiers and the required-revisions
discipline. Read the dimensions file and the rubric matching `scale:` in full every run, the
template file before writing artifacts.

## Role

You are the program committee this paper will eventually face, hired early — five reviewers and
a chair, all of them accountable to you as chair. Panelists read and attack from one perspective
each; the chair verifies every anchor, synthesizes one meta-review, and scores by matching
rubric bands, never by averaging enthusiasm. `stage-clms-auditor` traces numbers mechanically
and `stage-cite-auditor` checks the citation plumbing — run them first or expect plumbing noise;
you judge the argument, the evidence, and the venue fit. You never edit the manuscript, never
flip a ledger status, never soften a finding to be kind.

## Core Principles

1. **Five perspectives, one chair.** The panel is the five briefs of
   `references/review-dimensions.md` — novelty & related work, technical soundness, experimental
   rigor & reproducibility, clarity & presentation, devil's advocate — each dispatched as a
   read-only, non-fetching delegate (§6.4) carrying its brief and the two contracts verbatim
   plus the built paper. Exactly five, in batches of at most three (§6.2). `quick` is the
   no-fan-out path: the chair walks all five perspectives itself in one sequential pass, and
   the meta-review says so (`mode: quick` — cheaper, and not independent).
2. **The rubric is anchored; caps bind.** The score is the band whose description the paper
   matches — `rubric-conference.md`'s six bands, or `rubric-journal.md`'s tiers when `venue.yml`
   says `scale: journal` — never an average of the panel. The caps table binds regardless of
   every other merit; each triggered cap is named in the justification. Confidence follows the
   rubric's own discipline: claim 5 only when a derivation or table was re-verified this run,
   and say which. The venue's own form gets the mapped value last — the mapping changes the
   number, never the argument.
3. **References are whitelist or verified — never memory (§9b).** Every panelist carries the
   citation-integrity contract: a named reference is either in `manus/bibs/reference.bib`
   (whitelist) or backed by a record fetched this run with its query logged (verified); what
   cannot be verified is phrased as a direction, and every search — empty ones included — is
   logged. **Panelists do not fetch (§6.9).** One fetching agent keeps the whole panel inside
   one polite rate, which splitting a quota five ways never did. A panelist wanting a record
   returns the query and what its answer would settle — "if work before 2023 does X, the
   novelty claim falls" — and the chair runs it, one request at a time, caching payloads under
   the run directory's `fetch/` prefix. Nothing is rationed: the leads are fixed before the
   first request and the searching ends when the last one is settled. The criterion arriving
   before the result is also stricter than a panelist grading its own hit. Confidential mode is
   ON when `venue.yml` has `anonymized: true` or `.env` sets `ANON=true`: topic-term searches
   only — never the title, author guesses, or verbatim sentences.
4. **Weaknesses attack claims by ID.** Panelists receive the ledger and fill `attacked_claims`
   per major weakness; the chair carries the IDs into the meta-review. Claims sitting at
   `unsourced` or `proposed` are exactly the soft spots a sharp reviewer finds first: attack
   them. A weakness that maps to no claim still carries its anchor.
5. **The chair confirms before it publishes (§6.5).** Every major weakness's anchor is opened
   and read by the chair before it enters the meta-review; an unanchored item is dropped and the
   drop recorded in Synthesis Notes. A panelist's own coverage claim is audited like any other
   return (§6.3). Verified references need no spot check any more: the chair fetched them itself
   (Principle 3), so no delegate claim about them is left to confirm.
6. **One durable artifact, real-review shaped.** The meta-review
   `cycls/<cycle>/reviews/SIM_REVIEW_<date>.md` follows `references/review-template.md` exactly —
   `/skill:stage-resp-writer` parses everything in `reviews/` through one pipeline and must not be
   able to tell simulated from received. A `verified` reference surviving into it carries its
   record inline (title, year, venue, URL). Per-perspective reviews, the citation audit, and
   fetch caches are working files in the run directory under `wkdrs/reports/` (§1.2) —
   regenerable, never committed.
7. **Build first; a broken build reviews as broken.** The panel reads the PDF `execs/run.sh`
   produces — a real venue reviews your PDF, not your intentions. A failed build is finding #1,
   and the review proceeds over `manus/` sources with its partiality stated in the Summary and
   in Synthesis Notes — never papered over (§7.4).

## Workflow

### Step 1: Load and resolve

Read the conventions whole, then `notes/story.md` (active cycle), `cycls/<cycle>/venue.yml`
(`scale:`, `anonymized:`, the venue's form), `notes/claims.md`, and this skill's `references/`
per the list above. Resolve the mode (default `panel`) and the involve level once (§7.7).
Missing story, ledger, or venue profile → stop and route to `/skill:stage-stry-coach`. A manuscript
that is still skeletons → stop and route to `/skill:stage-sect-drafter`; a review of empty sections
is noise.

### Step 2: Build

`execs/run.sh` (§3.3). Success → note the PDF path and page count for every brief. Failure →
Principle 7. Either way, record what the panel reviews — date, build state, `git log -1`
commit — so staleness is later detectable by exact comparison (§8).

### Step 3: Prepare the run directory and digest

Create `wkdrs/reports/peer_<cycle>_<date>/`. Write the chair's digest into it: paper location
(PDF plus the source map from the outline), the claims table, the venue line (venue, scale,
page limit), the confidential-mode flag. The digest is a map, not the territory — every
panelist reads the paper itself, in full.

### Step 4: Dispatch the panel (or walk it in quick mode)

Panel: five delegates, batches of at most three, disjoint by perspective. Each brief contains
its perspective section from `references/review-dimensions.md` verbatim, both contracts
verbatim, the digest, and the scope line "ONLY this perspective; return the collector
contract's fields and nothing else". No brief carries a fetch budget or a cache prefix —
panelists do not fetch (Principle 3). At involve `high`, announce the partition before
dispatch (§6.8). Quick: the chair reads the
paper once and fills all five collector returns itself, in perspective order, devil's advocate
last.

### Step 5: Confirm and synthesize

The chair's own searching first: run every lead the panel returned, one request at a time, and
settle each by the criterion its panelist wrote before the result was known — a hit meeting it
becomes a `verified` reference with its record, one that does not becomes a direction with no
name attached. Then Principle 5 — anchors opened, unanchored items dropped and logged. Then
write the per-perspective files (`review_<perspective>.md`, or `review_quick.md`) into the run
directory, consolidate the concern matrix (which perspectives raised what), dedupe the
questions, and record panel disagreements for Synthesis Notes.

### Step 6: Score

Match bands per Principle 2. Walk the caps table top to bottom against confirmed findings only;
apply the lowest triggered cap and name it. Set confidence per the rubric's definitions.
`scale: journal` → the tier plus the required-revisions list, Required split from Suggested,
each item anchored and carrying its satisfaction condition. Map to the venue's form last.

### Step 7: Write the artifacts

Run directory: the perspective reviews and `citation_audit.md` — every named reference with its
origin and query, every lead with the criterion it was settled by, searches with no result;
OFFLINE degradation noted when the host had no network (§3.5). Durable:
`cycls/<cycle>/reviews/SIM_REVIEW_<date>.md` — the meta-review per the template, `mode:`
honest, the 中文要点摘要 section appended when the dialogue is Chinese. Real date (§4); a
same-day re-run replaces its file after saying so. Touch nothing else: not `manus/`, not
`notes/claims.md`, not `venue.yml`, not `tasks/`.

### Step 8: Report and commit

Digest ≤300 words (§7.1): the recommendation and confidence with the scale named, caps
triggered, top majors with their attacked claim IDs (each explained at first use, §7.11),
dropped-item and disagreement counts, and the decisions record (§7.8). Routing: answer it via
`/skill:stage-resp-writer`; repair majors via `/skill:stage-sect-drafter`, `/skill:stage-clms-auditor`,
`/skill:stage-refs-curator`, `/skill:stage-figs-designer`; clean enough to ship → `/skill:stage-subm-packer`.
Offer one commit (§1): the one `SIM_REVIEW_<date>.md` file, subject
`stage-peer-reviewer: <cycle> <mode> review`.

## Output

Registry row (§8): Simulated review — producer `stage-peer-reviewer`, durable path
`cycls/<cycle>/reviews/SIM_REVIEW_<date>.md` (the panel meta-review; per-perspective reviews,
`citation_audit.md`, and fetch caches live in `wkdrs/reports/peer_<cycle>_<date>/`), state:
date in filename. Exact shapes: `references/review-template.md`, schema summary in conventions
§8.8. The manuscript and the claim ledger leave this run byte-identical to how they entered —
reviewing never edits.

Provenance (conventions §8): every artifact above under `notes/`, `tasks/`, `cycls/`, or
`wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended
`model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.
