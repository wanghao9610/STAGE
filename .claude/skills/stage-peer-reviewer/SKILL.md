---
name: stage-peer-reviewer
description: >-
  Simulated program committee. Convenes a five-perspective panel — novelty & related work, technical
  soundness, experimental rigor & reproducibility, clarity & presentation, devil's advocate — under a
  citation-integrity contract (whitelist or verified references only, every search logged), scoring by
  anchored rubric bands with hard caps and honest confidence (6-point conference scale or journal
  tiers). On this repo's manuscript it builds first, a broken build being finding #1, and writes
  cycls/<cycle>/reviews/SIM_REVIEW_<date>.md whose weaknesses name the claim IDs they attack, so
  /stage-resp-writer reads simulated and real reviews alike; extern=<path> referees someone else's
  paper instead — same panel and rubric, no build, no ledger, confidential search, report under wkdrs/.
  quick mode runs a single pass. Never edits the manuscript or the ledger. Use when the user runs
  /stage-peer-reviewer, asks for a mock review, a review panel, a pre-submission attack, or to referee
  an external paper.
argument-hint: "[panel | quick] [extern=<path>] [out=<path>] [DESCRIPTION]"
allowed-tools: >-
  Read, Grep, Glob, Write, Edit, Bash(bash execs/run.sh:*), Bash(execs/run.sh:*), Agent,
  WebSearch, WebFetch, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*),
  Bash(git commit:*)
---

# Peer Reviewer — a five-perspective panel with an anchored rubric

**Reply language (conventions §7.6).** `.env` `STAGE_LANG=en|zh` sets chat replies and the Markdown this run writes; resolve it once at the start of the run — `grep -sE '^STAGE_LANG=' .env || true`, folded into the opening load call. Unset or empty → follow the user's dialogue language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request wins. English whatever it says: everything under `manus/`, the response to reviewers, and every structural literal — frontmatter keys, ledger statuses, IDs, paths, bibkeys, venue and metric names. Repo resources (the conventions, this skill) are loaded as-is in English; their zh-CN editions — `SKILL_zh.md` beside this file, `references/*_zh.md`, and `writing-workflow-conventions.zh-CN.md` for the conventions — are kept in step for human readers only and are never loaded at runtime, so this SKILL.md stays authoritative.

Invocation: `/stage-peer-reviewer [MODE] [extern=<path>] [out=<path>] [DESCRIPTION]` — `MODE` is
`panel` (default) or `quick`. With no `extern=`, the target is this repository's manuscript and
the cycle is the active one from `notes/story.md` (conventions §5); an `involve=<level>` token is
stripped before anything else is read (§7.7). Anything left after the mode and the `extern=` /
`out=` tokens is a description (conventions §7.13): in your own words, what this run is for —
which venue's bar to review against, which weakness the author already fears. It steers where the
panel presses hardest and it is recorded in the review's header; it never softens a score, waives
a rubric cap, or excuses a broken build, which stays finding #1 whatever the description says.
Prose that names no mode is description alone: run the full `panel`, and say so first.

**The external target (`extern=`).** `extern=<path>` points the panel at a paper this
repository did not write — the PDF somebody asked you to referee. Everything below holds, with
five substitutions that are the whole of the difference.
**No cycle:** nothing is read from `notes/story.md`, `notes/claims.md`, or a `venue.yml`, so
the venue and its scale (`conference-6` or `journal`) are asked once before the panel is
briefed — mandatory at every involve level, because guessing them picks the rubric (§7.7) —
and no `venue.yml` is written, these being facts about somebody else's submission (§9c).
**No build:** the file is read as given and `execs/run.sh` is never pointed at it; a `.tex`
source is read as source, with the partiality stated in the Summary exactly as a failed build
would be.
**No claim IDs:** there is no ledger to attack, so `attacked_claims` is empty everywhere and
the meta-review writes `—`; the anchor stays mandatory in exchange.
**Confidential by default:** a paper handed to a referee is under review until the user says
it is public, so the citation-integrity contract's confidential mode is ON unless they do.
**A different destination:** the report is `REFEREE_<date>.md` inside
`wkdrs/reports/extern_<slug>_<date>/`, or at the path `out=<path>` names — `<slug>` is the
target's basename lowercased, each run of non-alphanumerics turned to `-`. Nothing under
`manus/`, `notes/`, `cycls/`, `mates/`, or `tasks/` is read, created, or edited for it, and
writing an external review into `cycls/<cycle>/reviews/` is the one failure this path may
never have: `/stage-resp-writer` reads that directory as reviews of *this* paper and would
draft a rebuttal to somebody else's.

**Shared conventions.** `docs/mds/stage-workflow/writing-workflow-conventions.md` is the baseline
every STAGE skill shares — read the whole file at the start of every run; there is no
section-selective loading. The sections that bind this skill hardest: §2 the STOP line, §5
cycle resolution, §6 delegation (the panel is this workflow's largest sanctioned fan-out, and
§6.9 is what lets a panelist run its own searches, and what that costs), §8 the artifact registry, §9 the fabrication
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
flip a ledger status, never soften a finding to be kind. Under `extern=` the committee is a
real one and you are drafting for the human who sits on it — the same five readings and the
same rubric, owing their honesty to authors who never asked for your kindness either.

## Core Principles

1. **Five perspectives, one chair.** The panel is the five briefs of
   `references/review-dimensions.md` — novelty & related work, technical soundness, experimental
   rigor & reproducibility, clarity & presentation, devil's advocate — each dispatched as a
   delegate that fetches nothing but its own leads (§6.9) and writes exactly one file, its own
   `review_<perspective>.md` in the run directory (§6.2, §6.4), carrying its brief and the two
   contracts verbatim plus the built paper. It writes nothing under `manus/`, `notes/`, or
   `cycls/`: the meta-review is the chair's synthesis, not five reviews concatenated. Exactly five, all dispatched in one message so the panel is genuinely concurrent (§6.2). `quick` is the
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
   logged. **A panelist runs its own leads (§6.9).** The rate divides rather than the
   quota: each brief states, in seconds, the wait between that panelist's own requests to a
   host — the host's interval times the five running at once — so the panel as a whole asks
   each host no faster than one agent would have. Every payload is cached under that
   panelist's own prefix in the run directory. What does not move is the discipline the leads
   were built on: a panelist writes `what_it_would_settle` into its return **before** it runs
   the query — "if work before 2023 does X, the novelty claim falls" — and its own verdict on
   the hit is advisory. The chair opens the cached record and applies that criterion itself
   (Principle 5), which is what keeps a reference from being talked into existence by whoever
   wanted it. Nothing is rationed: the leads are fixed before the first request and the
   searching ends when the last one is settled. Confidential mode is
   ON when `venue.yml` has `anonymized: true`, when `.env` sets `ANON=true`, and — by default —
   whenever the run carries `extern=` and the user has not said the paper is public: topic-term searches
   only — never the title, author guesses, or verbatim sentences — and it now binds each
   panelist directly, because each one is the thing making the request.
4. **Weaknesses attack claims by ID.** Panelists receive the ledger and fill `attacked_claims`
   per major weakness; the chair carries the IDs into the meta-review. Claims sitting at
   `unsourced` or `proposed` are exactly the soft spots a sharp reviewer finds first: attack
   them. A weakness that maps to no claim still carries its anchor. An `extern=` run has no
   ledger at all, so `attacked_claims` is empty for every weakness and the meta-review writes
   `—`; the anchor is not what it trades away.
5. **The chair confirms before it publishes (§6.6).** A panel is the one fan-out whose reading
   the chair repeats rather than replaces — the second opinion is the entire product, and a
   verdict nobody checked is one reviewer's opinion wearing five hats. So every major
   weakness's anchor is opened and read by the chair before it enters the meta-review; an unanchored item is dropped and the
   drop recorded in Synthesis Notes. A panelist's own coverage claim is audited like any other
   return (§6.3). A `verified` reference is confirmed twice over, and this is the cost of
   Principle 3's fan-out rather than a formality: the chair opens the payload at the cache path
   the panelist returned, and re-applies the criterion that panelist wrote before its query.
   No path, no payload, or a record the criterion does not actually settle → the reference is
   demoted to a direction with no name attached, and the demotion is recorded in the citation
   audit.
6. **One durable artifact, real-review shaped.** The meta-review
   `cycls/<cycle>/reviews/SIM_REVIEW_<date>.md` follows `references/review-template.md` exactly —
   `/stage-resp-writer` parses everything in `reviews/` through one pipeline and must not be
   able to tell simulated from received. A `verified` reference surviving into it carries its
   record inline (title, year, venue, URL). Per-perspective reviews, the citation audit, and
   fetch caches are working files in the run directory under `wkdrs/reports/` (§1.2) —
   regenerable, never committed. An `extern=` run writes the same shape to `REFEREE_<date>.md`
   at its own destination and never into `cycls/`; being nobody's rebuttal, it drops the
   claim-ID column and keeps everything else.
7. **Build first; a broken build reviews as broken.** The panel reads the PDF `execs/run.sh`
   produces — a real venue reviews your PDF, not your intentions. A failed build is finding #1,
   and the review proceeds over `manus/` sources with its partiality stated in the Summary and
   in Synthesis Notes — never papered over (§7.4). An `extern=` run has nothing to build: it
   reads the file it was handed, and a source-only target states that partiality the same way.

## Workflow

### Step 1: Load and resolve

Read the conventions whole, then `notes/story.md` (active cycle), `cycls/<cycle>/venue.yml`
(`scale:`, `anonymized:`, the venue's form), `notes/claims.md`, and this skill's `references/`
per the list above. Resolve the mode (default `panel`) and the involve level once (§7.7).
Missing story, ledger, or venue profile → stop and route to `/stage-stry-coach`. A manuscript
that is still skeletons → stop and route to `/stage-sect-drafter`; a review of empty sections
is noise. Under `extern=` none of that resolves and none of it is read: open the target
instead, confirm it is readable, and ask the venue and scale. A target that cannot be opened
is reported, never reviewed from its filename.

### Step 2: Build

`execs/run.sh` (§3.3). Success → note the PDF path and page count for every brief. Failure →
Principle 7. Either way, record what the panel reviews — date, build state, `git log -1`
commit — so staleness is later detectable by exact comparison (§8). Under `extern=` this step
is skipped whole; record the target's path, its page or word count, and the date, which is all
the identity an external file has.

### Step 3: Prepare the run directory and digest

Create `wkdrs/reports/peer_<cycle>_<date>/` — `wkdrs/reports/extern_<slug>_<date>/` under
`extern=`. Write the chair's digest into it: paper location (PDF plus the source map from the
outline), the claims table, the venue line (venue, scale, page limit), the confidential-mode
flag. The digest is a map, not the territory — every panelist reads the paper itself, in full.
An external digest carries the target path, the venue and scale the user confirmed, and the
line "no claim ledger — `attacked_claims` is empty" in place of the claims table.

### Step 4: Dispatch the panel (or walk it in quick mode)

Panel: five delegates, disjoint by perspective — `Agent` subagents (`subagent_type: general-purpose`), all five dispatched in a single message so the panelists run concurrently. No question precedes it: fanning out is the chair's call and it does not ask (§6.1). Only a host that offers no dispatch, or one that refuses the call, takes the `quick` path — the meta-review then says `mode: quick`, which is the honest name for a panel that was never independent, and the digest names the fan-out that did not fire. Each brief contains
its perspective section from `references/review-dimensions.md` verbatim, both contracts
verbatim, the digest, and the scope line "ONLY this perspective; return the collector
contract's fields and nothing else". Each brief also carries the seconds that panelist waits
between its own requests to a host and its own cache prefix under the run directory
(Principle 3) — never a request quota, which is not what politeness is made of. At involve
`high`, announce the partition before dispatch (§6.8). Quick: the chair reads the
paper once and fills all five collector returns itself, in perspective order, devil's advocate
last.

### Step 5: Confirm and synthesize

The chair's own confirming first: for every reference a panelist returned as `verified`, open
the payload at the cache path it gave and settle the hit by the criterion that panelist wrote
before running the query — a record meeting it keeps `verified` and carries its record, one
that does not becomes a direction with no name attached. A lead nobody could run comes back
unsettled; the chair runs it here, one request at a time. Then Principle 5 — anchors opened, unanchored items dropped and logged. The
per-perspective files are already in the run directory, one written by each panelist; a `quick`
run writes its own `review_quick.md` here. Consolidate the concern matrix (which perspectives raised what), dedupe the
questions, and record panel disagreements for Synthesis Notes.

### Step 6: Score

Match bands per Principle 2. Walk the caps table top to bottom against confirmed findings only;
apply the lowest triggered cap and name it. Set confidence per the rubric's definitions.
`scale: journal` → the tier plus the required-revisions list, Required split from Suggested,
each item anchored and carrying its satisfaction condition. Map to the venue's form last.

### Step 7: Write the artifacts

Run directory: the perspective reviews and `citation_audit.md` — every named reference with its
origin, query, and cache path, every lead with the criterion it was settled by and who ran it,
every reference the chair demoted and why, searches with no result;
OFFLINE degradation noted when the host had no network (§3.5). Durable:
`cycls/<cycle>/reviews/SIM_REVIEW_<date>.md` — the meta-review per the template, `mode:`
honest, the 中文要点摘要 section appended when the dialogue is Chinese. Real date (§4); a
same-day re-run replaces its file after saying so. Touch nothing else: not `manus/`, not
`notes/claims.md`, not `venue.yml`, not `tasks/`. Under `extern=` the durable file is instead
`REFEREE_<date>.md` at the destination the external-target paragraph fixes, in the
external-report shape of `references/review-template.md`; `cycls/` is not written at all.

### Step 8: Report and commit

Digest ≤300 words (§7.1): the recommendation and confidence with the scale named, caps
triggered, top majors with their attacked claim IDs (each explained at first use, §7.11),
dropped-item and disagreement counts, and the decisions record (§7.8). Routing: answer it via
`/stage-resp-writer`; repair majors via `/stage-sect-drafter`, `/stage-clms-auditor`,
`/stage-refs-curator`, `/stage-figs-designer`; clean enough to ship → `/stage-subm-packer`.
Offer one commit (§1): the one `SIM_REVIEW_<date>.md` file, subject
`stage-peer-reviewer: <cycle> <mode> review`.

An `extern=` run ends differently, because none of that applies to it. No routing — the
sibling skills repair this repository's paper and there is nothing here for them to repair.
No commit either: its report is not a repository artifact, and under the default destination
it sits in `wkdrs/`, which git ignores and any clean regenerates — so the reply names the
report's path and says, in one clause, that keeping it means copying it out or re-running with
`out=<path>`. The recommendation is a draft for the human referee to edit and submit;
submitting it anywhere is over the STOP line (§2) at every involve level.

## Output

Registry row (§8): Simulated review — producer `stage-peer-reviewer`, durable path
`cycls/<cycle>/reviews/SIM_REVIEW_<date>.md` (the panel meta-review; per-perspective reviews,
`citation_audit.md`, and fetch caches live in `wkdrs/reports/peer_<cycle>_<date>/`), state:
date in filename. Exact shapes: `references/review-template.md`, schema summary in conventions
§8.8. The manuscript and the claim ledger leave this run byte-identical to how they entered —
reviewing never edits.

An `extern=` run adds no registry row, and that is the honest record rather than an omission:
the registry is what `stage-flow-status` checks this paper's stages against, and a referee
report on somebody else's paper is not one of its stages. Its whole output is the run
directory — `REFEREE_<date>.md` beside the perspective reviews and `citation_audit.md`, at the
default destination or the one `out=` named.

Provenance (conventions §8): every artifact above under `notes/`, `tasks/`, `cycls/`, or
`wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended
`model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.
