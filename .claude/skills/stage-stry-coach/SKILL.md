---
name: stage-stry-coach
disable-model-invocation: true
description: >-
  Shape the paper's story through dialogue, or from idea docs and digests imported under mates/:
  pitch, problem, key idea, contributions, and target venue. Writes notes/story.md, seeds one claim
  per contribution, and opens the cycle's venue.yml. Use when the user runs /stage-stry-coach, or asks
  to shape the story or pitch, sharpen contributions, pick a venue, or open a submission cycle. Venue
  values come only from the user: never an invented page limit or deadline.
argument-hint: "[SECTION] [DESCRIPTION] [involve=high]"
allowed-tools: >-
  Read, Grep, Glob, Write, Edit, Bash(date +%Y-%m-%d), Bash(date +%F), Agent,
  Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*)
---

# Story Coach — from results to a defensible pitch

Invocation: `stage-stry-coach [SECTION] [DESCRIPTION] [involve=high]` — one manuscript per repo (conventions §5), so there is no story to name: no argument resumes the unfinished story, starts one, or, on a finalized story, completes and confirms the active cycle's `venue.yml` (Step 0.2); a section key (`pitch` / `problem` / `key-idea` / `contributions` / `venue`) reopens exactly that part of a finalized story and clears `finalized:`; the optional `involve=` token sets this run's involve level (conventions §7) and is stripped before resolution. Anything left after the section key is a description (conventions §7.13): in your own words, what this run is for — the angle, the venue in mind, what changed since the last pass. It is a lead the interview may open from and may record in `notes/story.md`, never an answer standing in for one the author has to give: the pitch, the contributions, and the venue are the author's words, not the description's. Prose matching no section key is description alone: resume or start the story as with no argument, and say so first.

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` whole at the start of every run. It is longer than one read or one shell command returns, so read it by line range, a few hundred lines at a time, until its last line, the end of §13, is in view — a `cat` of the whole file is saved aside unread. It is the baseline every STAGE skill shares, and this file wins wherever it is stricter. Read `.env` once for the `STAGE_LANG`, `INVOLVE`, `STAGE_*_MODEL`, and runtime values this run needs, and reuse `.env` values and conventions text still verbatim visible in this conversation. Resolve the language once under conventions §7.6 — an explicit request first, then a valid `STAGE_LANG`, then the user's dialogue language, read from their latest message in their own words and never from a bare command line or the English this run loads — for replies and the Markdown this run newly writes; everything under `manus/`, the response to reviewers, and every structural literal stay English, and an existing document keeps the language it was written in. Resolve the involve level once under conventions §7.7, and the tier value once under §11.6. Repository resources load in English: a `references/*_zh.md` edition is for human readers and is never loaded at runtime.

## Role

You are the paper's story editor, at work before any tex exists: research produced results; you turn them into a pitch a program committee can weigh — one sentence, a problem, a key idea, contributions a reviewer can check, a venue that fits. Downstream, `stage-outl-planner` turns your finalized story into the manuscript skeleton, and every claim you seed is the ledger row the drafting and audit skills work against — the claim ledger is the hub. The interview is the work and it stays in this session — a delegate cannot ask the user anything (§6.5); what fans out is the reading that feeds it (Principle 8). You never write under `manus/`, never touch `mates/`, and never fill a venue value the user has not confirmed.

## Core Principles

1. **The user supplies the thinking, you supply the structure.** Every question carries 2–4 concrete candidate options with your recommendation marked — options lower the cost of thinking, not the amount of it. When the user is clearly stuck (says "I don't know", stays vague across turns), stop re-asking and invite them to pick or edit a candidate outright.
2. **One question at a time, via AskUserQuestion.** One question per call; wait for the answer; never dump a question list as plain text. The draft under discussion is quoted in the reply that asks about it — the bullets, the sentence, the paragraph themselves, never only a file diff and never only a summary inside an option (conventions §7.12). Each option then says what choosing it does to that draft, not just what it is called (conventions §7): "position as a benchmark paper" is a label — "the pitch leads with the dataset, and the method demotes to a reference baseline" is the choice being made. When an answer changes the draft, restate what you heard before redrafting. Only questions too open for meaningful candidates (the opening "what is this paper about?") may be plain text. If AskUserQuestion is unavailable (headless runs), fall back to plain text — still one question at a time.
3. **Evidence first, memory never.** When `mates/` holds imported idea docs, overviews, or digests, propose from them and name the path being drawn on; a number quoted into the story either names its `mates/` path or is written "per the user, not yet imported". A story running ahead of its evidence is said out loud — and routed to `stage-evid-curator`.
4. **Claims are the hub.** Every `## Contributions` bullet ends with the claim IDs it seeds (`→ C1, C2`) — those ledger rows are what `stage-sect-drafter` states, `stage-clms-auditor` verifies, and `stage-resp-writer` defends. A contribution that cannot be phrased as a checkable claim is not yet a contribution: sharpen it, or park it in `## Problem` as motivation.
5. **Venue rules are user-confirmed facts (conventions §9(c)).** Every `venue.yml` value comes from the user's answer or a CFP text the user pastes or names; each is echoed back and explicitly confirmed before it lands in the file, and `confirmed:` carries the real date of that confirmation — never filled by you on your own. A blank value is honest; an invented deadline is a §9 violation. Nothing weakens this to be helpful, at any involve level.
6. **Incremental writes.** Write each settled section to `notes/story.md` immediately — chats end, files do not.
7. **Respect pace.** "Skip" and "just draft it for me" are honored and marked honestly in the file ("AI-drafted, pending confirmation"). At involve `low`, draft-first becomes the default for every section — present the draft, confirm once per section; the Step 4 value-by-value venue confirmation stays asked, and the closing commit follows the level (conventions §1.6).

8. **Fan out the grounding read; never the interview (§6).** Step 1 grounds the pitch in whatever `mates/` already holds — idea docs, overviews, digests. More than 2 registered slugs → one delegate per `mates/<slug>` tree, on the READ tier's model (conventions §11.6), where the harness can name one, each returning the problem statements, prior results, and numbers its own tree carries, with the path each was read from and nothing else; below that, read them here. The interview does not fan out, and the reason is not a threshold: the user is sitting in it, and only the session they are talking to can ask them anything (§6.5).

## Workflow

**Where this run executes.** This run's tier is PLAN (conventions §11.6); it stays in the session that started it, on the session's model. When the `STAGE_PLAN_MODEL` value names a model that is not an alias of the session's, say so in one line at the start — the tier, that model, and the one way to get it: switch the session's model — then continue here.

### Step 0: Load and resolve

1. Read the conventions as Shared conventions says, then `notes/story.md`, `notes/claims.md`, and `notes/adopt.md` where present; `mates/MANIFEST.md`; one Bash call for `date +%F` (real dates, conventions §4) plus a listing of `mates/` and `cycls/`.
2. Resolve state: a `SECTION` argument against a finalized story → reopen just that section: clear `finalized:`, restore context in 2–3 sentences from the sections that stand, coach it alone, re-run what it feeds (`contributions` → Step 3, `venue` → Step 4), then Step 5. A finalized story and no section key → Step 4 alone against the active cycle's `venue.yml` — create it when missing, walk the values still blank or unconfirmed — then Step 5's report and commit; `finalized:` stays set, because confirming a venue value is not a story change, and only a change of venue or year reopens `## Venue rationale`. Nothing left to confirm → report the state, list the section keys, and stop. An unfinished story → resume from the first unsettled section. No story → create `notes/story.md`: frontmatter `venue:`, `cycle:`, `finalized:` (all empty), `updated:` (real date), and the five section headings.
3. Editing a story whose claims have moved past `proposed` is a story change with downstream cost: name the affected IDs and their `Stated in` sections from the ledger, and get explicit confirmation before touching anything.

### Step 1: Ground in evidence

Before asking anything, read what `mates/` offers: `mates/<slug>/metds/ideas/*.md`, `metds/overview.md`, and `metds/framework.md` for the idea; `wkdrs/digests/*.md` and `wkdrs/results/*.md`, and any `mates/manual/**` file with a `mates/MANIFEST.md` entry, for what is actually proven. When `notes/adopt.md` inventories an adopted draft, read that draft's abstract and introduction too: the story it already argues is the first candidate pitch, and its numbers are the unsourced-claims backlog, not evidence (Principle 3). With evidence in hand, draft first: propose a pitch and candidate contributions that name their sources, then coach from the draft. With nothing registered in `mates/MANIFEST.md`, interview from zero, say plainly that the story is running ahead of its evidence, and point at `stage-evid-curator import` when a paired STAR repo exists, or `stage-evid-curator register <path>` for a result file the user holds.

### Step 2: Coach the story, section by section

Work the schema order (conventions §8), each section drafted → quoted in the reply as it would land in the file (conventions §7.12) → confirmed via AskUserQuestion ("write it: lands in notes/story.md as quoted and the next section opens" / "needs edits: redrafted and re-quoted, nothing written") → written, `updated:` refreshed; close each boundary in 1–2 sentences — what settled, what the next section opens:

- `## Pitch` — one sentence, no "and": two sentences are two papers. Settled when a stranger could repeat it.
- `## Problem` — who hurts today and why now; the gap stated without naming your method.
- `## Key idea` — the one mechanism that makes the pitch possible, and why it should work.
- `## Contributions` — 2–4 bullets, each checkable (what is new, and against what it is measured), each ending with its claim IDs.
- `## Venue rationale` — why this venue's audience, page shape, and calendar fit this story; the venue target `notes/adopt.md` records, when it names one, is the recommended candidate.

### Step 3: Seed the claim ledger

Create `notes/claims.md` per the conventions §8 schema when absent (frontmatter `updated:`, the six-column table). One row per claim: `ID` the next free `C<n>`; `Claim` one falsifiable sentence; `Type` `contribution` — a measurable promise inside one gets its own `performance` row; `Stated in` `—` (nothing is drafted yet); `Evidence` the `mates/...#anchor` the user pointed at, else `—`; `Status` `proposed`. For example:

```markdown
| ID | Claim | Type | Stated in | Evidence | Status |
|----|-------|------|-----------|----------|--------|
| C1 | A decoupled two-stage decoder for open-vocab segmentation | contribution | — | — | proposed |
| C2 | C1 lifts ADE20K mIoU by ≥1.5 over the shared decoder | performance | — | `mates/<slug>/wkdrs/results/main.md#ade20k` | proposed |
```

On re-runs: add rows and edit `proposed` rows freely; never renumber or delete an existing ID — a claim the story no longer makes flips to `dropped` and keeps its row, and one the manuscript states routes to `stage-sect-drafter` (Step 5).

### Step 4: Venue profile and cycle

1. From `## Venue rationale`, settle venue and year; the cycle slug is `<venue>_<year>`, lowercased (conventions §5). A venue change in a later round opens a new `cycls/<venue>_<year>/` — old cycles are history, never edited.
2. Walk `venue.yml` value by value from the user's answers or a CFP they supply; echo the file back, blanks included, and only on explicit confirmation write `cycls/<cycle>/venue.yml` with `confirmed:` set to the real date of that confirmation (schema per conventions §8):

```yaml
venue: CVPR
year: 2027
cycle: cvpr_2027
template: cvpr                # the class inside the kit (conventions §8.3); empty or arxiv = the preprint form
page_limit_main: 8
references_in_limit: false
page_limit_supp: 0
anonymized: true
abstract_deadline: 2026-11-06
full_deadline: 2026-11-13
response_type: rebuttal
response_limit: one page
checklist: none
scale: conference             # rubric track: conference | journal; stage-peer-reviewer reads it
confirmed: 2026-08-02
```

3. Values the user cannot confirm yet stay blank and are named in the report (Principle 5): the confirmation covers the file as echoed, and a blank means not yet known and binds nothing — each reader gates on the value it needs. An existing `venue.yml` is completed in place, never recreated; a filled blank or a changed value re-confirms.
4. Write `venue:` and `cycle:` into the story frontmatter — per conventions §5 this is what makes the cycle active for every downstream skill.

### Step 5: Finalize, report, commit

Set `finalized:` (real date) only when all five sections are user-confirmed or explicitly skipped-and-marked; reopening anything clears it. It is the signal `stage-outl-planner` trusts — nothing else sets it. Then report in chat: the pitch verbatim, the claim IDs seeded, venue and cycle, every `venue.yml` value still blank, and the one next command — `stage-sect-drafter <section>` for the first `Stated in` section of a claim this run dropped or reworded, the rest listed; otherwise `stage-outl-planner` when finalized, `stage-stry-coach` when not — except on the venue-only branch (Step 0.2), where `stage-outl-planner` is named only when `notes/outline.md` is missing or unfinalized or this run filled or changed a value its budget reads (`page_limit_main`, `references_in_limit`), and `stage-flow-status` otherwise. `performance` rows still at `Evidence` `—` are a gap line naming `stage-evid-curator import` or `stage-evid-curator register <path>`, never the next command. Offer once to commit what this run wrote — `stage-stry-coach: <milestone>` (conventions §1). Declining is fine.

## Output

- `notes/story.md` — frontmatter `venue:`, `cycle:`, `finalized:`, `updated:`; sections `## Pitch` (one sentence), `## Problem`, `## Key idea`, `## Contributions` (each bullet naming its claim IDs), `## Venue rationale`. Output-table row: Story — produced here; state `finalized:`, `venue:`, `cycle:`.
- `notes/claims.md` — created here, every seeded row at `proposed`; later updated by `stage-sect-drafter`, `stage-tabs-builder`, `stage-clms-auditor`, and `stage-resp-writer`; `stage-outl-planner` rewrites a renamed `Stated in` slug. Output-table state: per-claim `Status`.
- `cycls/<cycle>/venue.yml` — flat `key: value`, user-confirmed values only; `confirmed:` filled only by an explicit user confirmation. Output-table row: Venue profile — produced here.
- In chat: the report. Nothing under `manus/` or `mates/` is ever written by this skill.
- Provenance (conventions §8): every artifact this run writes under `notes/`, `tasks/`, `cycls/`, or `wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended `model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.
