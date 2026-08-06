---
name: stage-resp-writer
disable-model-invocation: true
description: >-
  Turn every review in cycls/<cycle>/reviews/ — received_<id>.md files dropped by the user and
  SIM_REVIEW_* files from /stage-peer-reviewer — into a point ledger mapping each attack to
  claims and evidence, then draft the response within the venue's response_limit. Writes
  cycls/<cycle>/response/RESPONSE_<date>.md, mirrors every promised change as a checkbox in
  tasks/<cycle>_promises.md, and downgrades conceded claims to weakened in notes/claims.md.
  Never edits the manuscript or the review files themselves. Use when the user
  runs /stage-resp-writer, or asks to draft a rebuttal or response letter, answer reviewers
  point by point, or decide what to concede.
---

# Response Writer — point-by-point defense, promises on the books

**Reply language (conventions §7.6).** `.env` `STAGE_LANG=en|zh` sets chat replies and the Markdown this run writes; resolve it once at the start of the run — `grep -sE '^STAGE_LANG=' .env || true`, folded into the opening load call. Unset or empty → follow the user's dialogue language, so a Chinese conversation gets Chinese replies; an explicit in-conversation request wins. English whatever it says: everything under `manus/`, the response to reviewers, and every structural literal — frontmatter keys, ledger statuses, IDs, paths, bibkeys, venue and metric names. Repo resources (the conventions, this skill) are loaded as-is in English; their zh-CN editions — `SKILL_zh.md` beside this file, and `writing-workflow-conventions.zh-CN.md` for the conventions — are kept in step for human readers only and are never loaded at runtime, so this SKILL.md stays authoritative.

Invocation: `/stage-resp-writer [CYCLE]` — with no argument, the active cycle from
`notes/story.md` (conventions §5); a `CYCLE` argument names a directory under `cycls/` directly;
no match → list the candidates and ask (§7).

**Shared conventions.** `docs/mds/stage-workflow/writing-workflow-conventions.md` is the baseline
every STAGE skill shares — read the whole file at the start of every run; there is no
section-selective loading. The sections that bind this skill hardest: §5 cycle resolution, §7
dialogue, §8 the artifact registry (the response and promise schemas), §9 the fabrication
boundary.
This file states what is specific to this skill and wins wherever it is stricter.

**Reusing an earlier load.** Skip the re-read only when the conventions file's text is still
verbatim visible in this conversation. A summary that survived a context compaction, or a memory
of having read it, does not count — when in doubt, read it again.

## Role

You are the defense counsel after the objections are filed. `stage-peer-reviewer` simulates the
attack early; the venue's real reviews land in `cycls/<cycle>/reviews/` as `received_<id>.md`;
you answer both through one pipeline — every point, from the evidence record, inside the venue's
format and length. What to concede is the user's decision, and a concession goes on the record
in the ledger, not buried in polite wording. You never edit the manuscript — promised edits
route to the drafting skills — never edit review files, never argue past what `mates/` can
prove.

## Core Principles

1. **Every point gets a row.** Parse everything in `reviews/` — free-form `received_*.md` and
   `SIM_REVIEW_*` alike, one pipeline — into the point ledger. A point without a row is an
   unanswered reviewer, and venues notice unanswered reviewers.
2. **Attacks map to claims and evidence.** Match each point against `notes/claims.md`: which
   claim is under attack, which fingerprinted `mates/` entry defends it. SIM reviews name claim
   IDs already; free-form reviews are mapped here, and an uncertain mapping is called uncertain
   in the ledger row rather than silently guessed.
3. **Three dispositions; the costly ones are user-owned.** rebut — evidence in hand, cite it;
   promise — the paper will change, a checkbox is born; concede — the claim cannot be defended,
   its status drops to `weakened`. Concessions and promises always go through the user, one
   point at a time via AskUserQuestion (§7); evidence-backed rebuttals may proceed and are
   listed for review afterwards. The question quotes the reviewer's point and the wording
   you would send, neither of them summarized (§7.12).
4. **Response numbers obey §9a.** A number quoted to a reviewer either traces to a fingerprinted
   `mates/` entry or it does not enter the draft. "New results" without imported evidence are a
   promise to produce them — never a figure minted mid-rebuttal.
5. **A promise is a debt.** Every "we will …" in the draft has a matching `- [ ]` in
   `tasks/<cycle>_promises.md` naming its point and target; `/stage-subm-packer` refuses to pack
   camera-ready while a box is unchecked. Promise nothing the user has not confirmed the team
   will actually do.
6. **Venue response rules are user-confirmed facts (§9c).** `response_type` and `response_limit`
   come from `cycls/<cycle>/venue.yml`; missing or unconfirmed values are asked for, never
   invented. `response_type: none` → build the point ledger and promises for the revision, skip
   the draft, and say why.

## Workflow

### Step 1: Load

Read the conventions file whole. `notes/story.md` → active cycle; `cycls/<cycle>/venue.yml` →
`response_type`, `response_limit`; `notes/claims.md`; then list `cycls/<cycle>/reviews/`. An
empty `reviews/` → stop: name the drop path (`cycls/<cycle>/reviews/received_<id>.md`) and note
that `/stage-peer-reviewer` can simulate a panel meanwhile. No `Agent` subagents (§6).

### Step 2: Parse reviews into points

Per file: fix the reviewer label — `received_R2.md` → R2, `SIM_REVIEW_<date>.md` →
SIM-<date> — then split the text into atomic points: one weakness, question, or request each.
Point IDs reuse the reviewer's own numbering where present (`R2.W1`), else number in reading
order. Quote or tightly paraphrase; never soften a reviewer's words while carrying them into
the ledger.

### Step 3: Map and disposition

Per point: attacked claim IDs (SIM reviews carry them; free-form is inferred against the
ledger), then defending evidence from the ledger's Evidence column down to its `mates/` anchor.
Propose rebut / promise / concede with a one-line rationale each, then walk Principle 3's
approvals in point order, keeping a running record of what was decided so late answers can see
early ones.

### Step 4: Draft within the limit

Point-by-point, grouped by reviewer, register matching `response_type` (rebuttal vs
response-letter). Every answer cites its evidence by anchor ("Table 2; mates/<slug>/…") or
states its promise ("we will add the ablation — see revision"). `response_limit` is the venue's
own wording; measure the draft against it, report the measurement, and trim until it fits.

### Step 5: Write the artifacts

- `cycls/<cycle>/response/RESPONSE_<date>.md` — real date (§4); create `response/` when absent;
  shape below. **Always English, whatever `STAGE_LANG` says (§7.6)** — a program committee reads
  it. A Chinese dialogue still gets its chat report in Chinese; only the artifact is fixed.
- `tasks/<cycle>_promises.md` — one `- [ ]` per promise. Merge on re-runs: never uncheck,
  reword, or delete an existing box; append new ones.
- `notes/claims.md` — conceded claims flip to `weakened` and `updated:` is bumped. `weakened`
  is the only status this skill ever sets.

### Step 6: Report and commit

Digest ≤300 words: points by disposition, promises opened, claims weakened, measured length vs
`response_limit`. Routing: promised experiments run upstream in STAR, then `/stage-evid-curator`
re-imports; promised edits → `/stage-sect-drafter` / `/stage-tabs-builder`; promise state at a
glance → `/stage-flow-status`; the camera-ready gate that reads the boxes → `/stage-subm-packer`.
One commit per session (conventions §1), subject `stage-resp-writer: <cycle> response <date>`.

## Output

Registry row (§8): Response — producer `stage-resp-writer`, paths
`cycls/<cycle>/response/RESPONSE_<date>.md` plus promises in `tasks/<cycle>_promises.md`, state:
promise checkboxes; side effect: `weakened` downgrades in `notes/claims.md`. Exact shapes:

```markdown
---
cycle: <cycle>
date: YYYY-MM-DD
sources: [reviews/received_R2.md, reviews/SIM_REVIEW_<date>.md]
---
## Point ledger
| Point | Reviewer | Attacked claims | Evidence | Response summary | Promise? |
|-------|----------|-----------------|----------|------------------|----------|
| R2.W1 | R2 | C3, C7 | mates/<slug>/wkdrs/results/main.md#tab2 | rebut: reported in Tab. 2 | — |
## Draft response
```

```markdown
# Promises — <cycle>
- [ ] R2.W2: add ablation on X — run upstream, then /stage-evid-curator + /stage-tabs-builder
```

In chat: the Step 6 digest. Review files are read-only inputs and the manuscript is untouched —
every promised change is a checkbox pointing at the skill that will make it.

Provenance (conventions §8): every artifact above under `notes/`, `tasks/`, `cycls/`, or
`wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended
`model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.
