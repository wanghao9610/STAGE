---
name: stage-resp-writer
disable-model-invocation: true
description: >-
  Map every review under cycls/, received or simulated, into a point ledger tied to claims and
  evidence, then draft the response within the venue's response_limit, mirror each promise as a
  checkbox under tasks/, and mark conceded claims weakened. Use when the user runs
  /skill:stage-resp-writer, or asks to draft a rebuttal or response letter, answer reviewers point by
  point, or decide what to concede. Never edits the manuscript or the review files.
---

# Response Writer — point-by-point defense, promises on the books

Invocation: `stage-resp-writer [CYCLE] [DESCRIPTION] [involve=high]` — with no argument, the
active cycle from `notes/story.md` (conventions §5); a `CYCLE` argument names a directory under
`cycls/` directly; no match → list the candidates and ask (§7). Anything left after the cycle is a
description (conventions §7.13): in your own words, what this run is for — which reviewer worries
the author most, what the rebuttal has to win. It is a lead the run may follow and may record as
the reason behind a point's stance, never an instruction that stands in for the per-point approval
this skill asks for, and never a promise: a promise is made only where the response makes one, and
it lands in `tasks/<cycle>_promises.md`. Prose that names no cycle is description alone: use the
active cycle, and say so first. An optional `involve=low|medium|high` token may accompany any
argument: it sets this run's involve level (conventions §7.7), is part of neither the argument nor
the description, and is stripped before either is read.

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` whole at
the start of every run. It is longer than one read or one shell command returns, so read it by
line range, a few hundred lines at a time, until its last line, the end of §13, is in view — a `cat` of
the whole file is saved aside unread. It is the baseline every STAGE
skill shares, and this file wins wherever it is stricter. Read `.env` once for the `STAGE_LANG`, `INVOLVE`, `STAGE_*_MODEL`, and runtime
values this run needs, and reuse `.env` values and conventions text still verbatim visible in this
conversation. Resolve the language once under conventions §7.6 — an explicit request first, then a
valid `STAGE_LANG`, then the user's dialogue language, read from their latest message in their own words and never from a bare command line or the English this run loads — for replies and the Markdown this run newly
writes; everything under `manus/`, the response to reviewers, and every structural literal stay
English, and an existing document keeps the language it was written in. Resolve the involve level
once under conventions §7.7, and the tier value once under §11.6. Repository resources load in
English: a `references/*_zh.md` edition is for human readers and is never loaded at runtime.

## Role

You are the defense counsel after the objections are filed. `stage-peer-reviewer` simulates the
attack early; the venue's real reviews land in `cycls/<cycle>/reviews/` as `received_<id>.md`;
both enter one pipeline — every point, from the evidence record, inside the venue's
format and length. What to concede is the user's decision, and a concession goes on the record
in the ledger, not buried in polite wording. You never edit the manuscript — promised edits
route to the drafting skills — never edit review files, never argue past what `mates/` can
prove.

## Core Principles

1. **Every point gets a row.** Parse everything in `reviews/` — free-form `received_*.md` and
   `SIM_REVIEW_*` alike, one pipeline — into the point ledger. A point without a row is an
   unanswered reviewer, and venues notice unanswered reviewers. Once any `received_*` file exists,
   `## Draft response` answers received reviews only. SIM points stay in the ledger under reviewer
   `SIM-<date>`, for preparation, and open a promise or a concession only when the user names that
   point.
2. **Attacks map to claims and evidence.** Match each point against `notes/claims.md`: which
   claim is under attack, which fingerprinted `mates/` entry defends it. SIM reviews name claim
   IDs already; free-form reviews are mapped here, and an uncertain mapping is called uncertain
   in the ledger row rather than silently guessed.
3. **Three dispositions; the costly ones are user-owned.** rebut — evidence in hand, cite it;
   promise — the paper will change, a checkbox is born; concede — the claim cannot be defended,
   its status drops to `weakened`, and each section or table still stating it gets a box too.
   Concessions and promises always go through the user, one
   point at a time via AskUserQuestion (§7); evidence-backed rebuttals may proceed and are
   listed for review afterwards. The question quotes the reviewer's point and the wording
   you would send, neither of them summarized (§7.12).
4. **Response numbers obey §9a.** A number quoted to a reviewer either traces to a fingerprinted
   `mates/` entry or it does not enter the draft. "New results" without imported evidence are a
   promise to produce them — never a figure minted mid-rebuttal.
5. **A promise is a debt.** Every "we will …" in the draft has a matching `- [ ]` in
   `tasks/<cycle>_promises.md` naming its point and target; `stage-subm-packer` refuses to pack
   camera-ready while a box is unchecked; for `response_type: response-letter` it refuses the
   revision's review pack too, so those boxes are due before the revision is packed. Promise
   nothing the user has not confirmed the team will actually do.
6. **Venue response rules are user-confirmed facts (§9c).** `response_type` and `response_limit`
   come from `cycls/<cycle>/venue.yml`; missing or unconfirmed values are asked for, never
   invented. An answered value binds this run only: this skill never writes `venue.yml`, and the
   closing line names `stage-stry-coach` to record it: on a finalized story, that bare run
   completes the cycle's `venue.yml` alone. `response_type: none` → build the point ledger and
   promises for the revision, skip the draft, and say why.

7. **Fan out the parse (§6).** More than two files in `cycls/<cycle>/reviews/` → one delegate per
   review file, on the READ tier's model (conventions §11.6), where the harness can name one, each
   returning that review's points as ledger rows — point ID, the verbatim quote, the severity
   the review states (working data for Step 3; the ledger has no column for it), and the claim
   IDs a SIM review names, each copied and none judged; a free-form review's attacks are mapped
   here, in Step 3 — and nothing else. What does not split is everything
   after it: a disposition is decided against the whole point set, the costly ones are the user's
   call and stay at a confirmation point (§6.5), and the response is one document written to one
   limit. Every number quoted to a reviewer enters under Principle 4 whoever writes it (§6.4).

## Workflow

**Where this run executes.** This run's tier is PLAN (conventions §11.6); it stays in the session
that started it, on the session's model. When the `STAGE_PLAN_MODEL` value names a model that is not
an alias of the session's, say so in one line at the start — the tier, that model, and the one way
to get it: switch the session's model — then continue here.

### Step 1: Load

Read the conventions file whole. `notes/story.md` → active cycle; `cycls/<cycle>/venue.yml` →
`response_type`, `response_limit`, `anonymized`; `notes/claims.md`; `mates/MANIFEST.md`;
`tasks/<cycle>_promises.md`; then list `cycls/<cycle>/reviews/` and `cycls/<cycle>/response/`,
reading the newest `RESPONSE_*` and the `sources:` of every one. The draft answers the
`received_*` files no `RESPONSE_*` lists in `sources:` (a new round), or, when every `received_*`
file is listed, the newest `RESPONSE_*`'s `sources:` again (a re-draft). With no `received_*` yet,
it answers the `SIM_REVIEW_*` files. Say which set in one line before Step 3. An
empty `reviews/` → stop: name the drop path (`cycls/<cycle>/reviews/received_<id>.md`) and note
that `stage-peer-reviewer` can simulate a panel meanwhile. The parse that follows fans out per
review file (Principle 7).

### Step 2: Parse reviews into points

Per file: fix the reviewer label — `received_R2.md` → R2, `SIM_REVIEW_<date>.md` →
SIM-<date> — then split the text into atomic points: one weakness, question, or request each.
Point IDs reuse the reviewer's own numbering where present (`R2.W1`), else number in reading
order. Quote verbatim; never soften a reviewer's words while carrying them into
the ledger.

### Step 3: Map and disposition

Per point: attacked claim IDs (SIM reviews carry them; free-form is inferred against the
ledger), then defending evidence from the ledger's Evidence column: open each cited `mates/` file
at its anchor, confirm its MANIFEST entry, and note the claim's Status. A number drawn from a
claim not at `verified` is named with that status wherever the point is shown to the user (its
approval question, or the list of rebuttals shown for review afterwards). A point the newest
`RESPONSE_*` already settled keeps its disposition when its text is unchanged and no MANIFEST
entry it cites was `imported:` after that file's `date:`. A claim already at `weakened` is its
concession on record. Only new points, changed points, and points whose evidence moved are walked.
Propose rebut / promise / concede with a one-line rationale each, then walk Principle 3's
approvals in point order, keeping a running record of what was decided so late answers can see
early ones.

### Step 4: Draft within the limit

Point-by-point, grouped by reviewer, register matching `response_type` (rebuttal vs
response-letter). Every answer cites its evidence by anchor ("Table 2", "§4.3": the manuscript's
own anchors, while the `mates/` anchor stays in the Point ledger's Evidence column) or
states its promise ("we will add the ablation — see revision"). `response_limit` is the venue's
own wording; measure the draft against it, report the measurement, and trim until it fits.
Before Step 5 writes, re-read every number the draft quotes at its `mates/` anchor and compare,
as `stage-tabs-builder`'s re-read does. A mismatch or a missing MANIFEST entry turns that answer
into a promise or takes the number out. When `anonymized: true` or `.env` sets `ANON=true`, check
`## Draft response` for URLs, names and self-identifying phrasing ("our previous work"), because
`lint.sh` scans only `manus/`.

### Step 5: Write the artifacts

- `cycls/<cycle>/response/RESPONSE_<date>.md` — real date (§4); create `response/` when absent;
  a same-day file already on disk is overwritten only on its own confirmation (§7.7), with an
  option that keeps its `## Draft response` as it stands and rewrites the Point ledger alone;
  shape below. **Always English, whatever `STAGE_LANG` says (§7.6)** — a program committee reads
  it. The chat report still follows the language resolved under §7.6; only the artifact is fixed.
- `tasks/<cycle>_promises.md` — one `- [ ]` per promise, led by its point ID, and, for each
  conceded claim the manuscript still states, one per section its `Stated in` names —
  `- [ ] <point>: restate C<n> at conceded strength — stage-sect-drafter <section>` — and one per
  `tabs/<slug>` entry, routed to `stage-tabs-builder <slug>`. Merge on re-runs: never uncheck or
  reword an existing box, and append a box only for a point, or a conceded claim's `Stated in`
  entry, that has none. An open box whose point this draft answers without that promise is
  listed and asked about (§7.7, a deletion); on a yes it moves under `## Withdrawn` as
  `- <point>: <promise> — withdrawn <date>: <reason>`, with no checkbox.
- `notes/claims.md` — conceded claims flip to `weakened` and `updated:` is bumped. `weakened`
  is the only status this skill ever sets.

### Step 6: Report and commit

Digest: points by disposition, promises opened, claims weakened, measured length vs
`response_limit`, and the anonymity check's result when it ran. Routing: promised experiments run
upstream in STAR, then `stage-evid-curator` re-imports; promised edits → `stage-sect-drafter` /
`stage-tabs-builder`; promise state at a glance → `stage-flow-status`; the pack gate that reads the
boxes → `stage-subm-packer`.
One commit for the run (conventions §1), subject `stage-resp-writer: <cycle> response <date>`.

## Output

Output-table row (§8): Response — producer `stage-resp-writer`, paths
`cycls/<cycle>/response/RESPONSE_<date>.md` plus promises in `tasks/<cycle>_promises.md`, state:
promise checkboxes, ticked by the skill whose revision keeps each; side effect: `weakened`
downgrades in `notes/claims.md`. Exact shapes:

```markdown
---
cycle: <cycle>
date: YYYY-MM-DD
sources: [reviews/received_R1.md, reviews/received_R2.md]
---
## Point ledger
| Point | Reviewer | Attacked claims | Evidence | Response summary | Promise? |
|-------|----------|-----------------|----------|------------------|----------|
| R2.W1 | R2 | C3, C7 | mates/<slug>/wkdrs/results/main.md#tab2 | rebut: reported in Tab. 2 | — |
## Draft response
```

```markdown
# Promises — <cycle>
- [ ] R2.W2: add ablation on X — run upstream, then stage-evid-curator + stage-tabs-builder
- [ ] R1.W3: restate C4 at conceded strength — stage-sect-drafter 4_expts
- [ ] R1.W3: restate C4 at conceded strength — stage-tabs-builder main_results
## Withdrawn
- R2.W4: add runtime table — withdrawn YYYY-MM-DD: cut from the sent rebuttal
```

In chat: the Step 6 digest. Review files are read-only inputs and the manuscript is untouched —
every promised change is a checkbox pointing at the skill that will make it.

Provenance (conventions §8): every artifact above under `notes/`, `tasks/`, `cycls/`, or
`wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended
`model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.
