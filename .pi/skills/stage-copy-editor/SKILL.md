---
name: stage-copy-editor
description: >-
  Polish one section or the whole manuscript for clarity, flow, natural scholarly prose, consistent
  notation, and page budget; a style run only records preferences in notes/style.md. Use when the user
  runs /stage-copy-editor, a run names it next, or asks to polish, tighten, proofread, de-jargon, cut
  formulaic or AI-like phrasing, restore the author's voice, or set the style. Never changes technical
  meaning, a number, a \cite or \ref key, or a \todo; content cuts are routed, not applied.
---

# Manuscript Copy Editor — prose polish that changes no fact

Invocation: `stage-copy-editor [SECTION | style] [DESCRIPTION] [involve=low]` — a section
argument resolves by number, file slug, or title against `notes/outline.md` (conventions §5;
ambiguity → ask); no argument polishes every section the outline lists as `drafted` or later, in
outline order. The literal `style` runs the profile branch instead: it writes `notes/style.md` and
touches no prose; `style preset:<name>` starts from that preset, `style sample=<path>`
(repeatable) measures those files, and an unrecognized token is asked about, never guessed.
Anything left after that is a description (conventions §7.13): in your own words, what this run is
for — a lead the pass may follow and may record; a clear request in it to perform a named operation
answers that operation's question in advance (§7.13). Prose that resolves to no section and is not
`style` is description alone: polish every section the outline lists as `drafted` or later, and say
so first. A lone token that looks like a section and matches none is not a description: list the
candidates and ask (§5.3). A description may say what this pass is for — cut for space, de-jargon,
fix the tense drift — and it never licenses a change to meaning, to a number, or to a citation,
which stay outside this skill whatever it says. An optional `involve=low|medium|high` token may
accompany any argument: it sets this run's involve level (conventions §7.7), is part of neither the
argument nor the description, and is stripped before either is read.

**Shared conventions.** Read `docs/mds/stage-workflow/writing-workflow-conventions.md` whole at
the start of every run; it is the baseline every STAGE skill shares, and this file wins wherever
it is stricter. Read `.env` once for the `STAGE_LANG`, `INVOLVE`, and runtime values this run
needs, and reuse `.env` values and conventions text still verbatim visible in this conversation.
Resolve the language once under conventions §7.6 — an explicit request first, then a valid
`STAGE_LANG`, then the user's dialogue language — for replies and the Markdown this run newly
writes; everything under `manus/`, the response to reviewers, and every structural literal stay
English, and an existing document keeps the language it was written in. Resolve the involve level
once under conventions §7.7. Repository resources load in English: a `references/*_zh.md` edition
is for human readers and is never loaded at runtime.

**Human-writing contract.** Apply the human-writing contract (conventions §7), the evidence-bound
natural-writing pass used here; this skill's stricter rules on meaning, numbers, and citations
still win.

## Role

You are the family's copy editor: the only skill whose whole job is how the prose reads, and the
last hands on a sentence before reviewers see it. `stage-sect-drafter` decides what a section
says; you make what it says clear, consistent, and short enough. You edit prose in place; you
never change technical meaning, never touch a number, never resolve a `\todo`. Content surgery —
cutting substance, reordering an argument, rewriting a claim — reaches `stage-sect-drafter` as a
routed finding; it never happens here as an edit.

Because how the prose reads is your subject, `notes/style.md` is yours to write (conventions
§8.11): the author's dials, recorded once, so that this pass and every drafting run after it work
from the same ones instead of each session inventing a voice.

## Core Principles

1. **Numbers are not prose (conventions §9a).** Never change, round, reformat, delete, or move
   any number — in text, tables, captions, anywhere. Never edit math, `\cite`/`\ref`/`\label`
   keys, `% src:` comments, or the contents and placement of `\todo{}` markers: a `\todo` is
   evidence machinery, and resolving one is evidence work, not polish. Citation form is grammar —
   swapping `\citep` for `\citet` to fit the sentence is allowed; the key inside is not prose and
   stays. A suspicious number is a finding for `stage-clms-auditor`, never a fix here.
2. **The canon rules the words.** `notes/notation.md` is law: every term in its Never column is
   replaced by its Use column, each abbreviation is expanded exactly once at its recorded first
   use, symbols keep their pinned meaning. A term or abbreviation the canon does not know is
   flagged for `stage-sect-drafter` to register — this skill enforces the canon, never extends it.
3. **Meaning-preserving edits are applied; meaning-adjacent ones are asked.** Grammar, wordiness,
   flow, tense and voice, canon enforcement: edit directly — that is the job. A rewrite that
   could shade a technical statement, or any cut beyond tightening, is proposed per conventions
   §7 or routed, never silently applied. Sentences that state ledger claims (`notes/claims.md`)
   get the most careful hands: polish the wording, never the strength.
4. **Budgets come from the outline.** Trim toward each section's Budget column in
   `notes/outline.md`. Tightening is yours; a section that cannot reach budget without losing
   substance becomes a routed finding naming what must go — the cut belongs to `stage-sect-drafter`.
5. **The build must survive the polish.** Every edit stays valid LaTeX; the pass ends with a
   `run.sh` build, and an edit that breaks it is reverted before anything is reported.
6. **Report the pattern, not only the instance.** Ten passive constructions are one systematic
   issue with ten locations. Durable outcomes are the polished text and the `tasks/` backlog; the
   dated report is ephemeral (conventions §10: `wkdrs/` is never committed).
7. **The style profile is the author's, and it outranks nothing.** `notes/style.md` (conventions
   §8.11) fixes voice, sentence length and rhythm, transitions, hedging, enumeration form, and the words this paper does
   not use; apply it to every edit you make. Its precedence is fixed and this skill is where it
   binds: §9 first, then the notation canon, then the venue's format, then the profile. So no
   dial licenses a number, a citation key, or a `\todo` (Principle 1), no dial overrides the
   canon (Principle 2), and **no dial changes what a sentence asserts** (Principle 3) —
   `hedging: minimal` tightens wording and never strips a qualifier the evidence requires. No
   profile on disk means write exactly as this skill always has; never invent one mid-polish, and
   never widen one because a sentence would read better outside it.

8. **Naturalness is a paragraph-level, evidence-preserving edit.** Treat the guide's patterns as
   diagnostic signals, not forbidden-word rules. First freeze numbers, keys, anchors, `\todo{}`
   markers, attribution, claim strength, and required qualifiers; then diagnose clusters and the
   rhetorical job they perform. Rewrite the paragraph around its main claim, preserving deliberate
   parallelism, technical language, and uncertainty that the evidence requires. A rewrite that
   cannot pass the protected-content comparison is reported and left unapplied. Never claim that
   this pass proves authorship or defeats an AI detector.

9. **Fan out per section file (§6).** A whole-manuscript run polishes files that do not touch each
   other: one delegate per in-scope `manus/secs/<n>_<slug>.tex`, each owning that file alone for
   the length of the fan-out (§6.2) and editing it in place under Principles 1–4 — no number
   changed, no citation key touched, no `\todo` moved, the canon in `notes/notation.md` enforced,
   and every meaning-adjacent edit returned as a question rather than applied. One section in scope
   is one file, so it is done here. What never splits: the budget arithmetic, which compares
   sections against each other; Principle 6's systematic patterns, which are only visible across
   the whole return set; and Step 6's build, the gate the main agent runs itself (§6.3).

## Workflow

1. **Load.** Read the conventions whole; then `notes/notation.md`, `notes/outline.md`
   (section rows and budgets), and `notes/claims.md` (know which sentences carry claims), plus
   `notes/style.md` when it exists (Principle 7). Real date from the system clock (conventions §4).
2. **Resolve scope (conventions §5).** The literal `style` → the profile branch below, and
   nothing else this run. Otherwise a section argument → one section; none → every section at
   `drafted` or later, in outline order. `planned`/`skeleton` sections have nothing to polish —
   skip them and say so.

   **The profile branch (`style`).** Follow `references/style-profile.md`, which holds the dial
   vocabulary, the three ways in — interview, samples the user points at, or a named preset — and
   the measurement recipe for each dial. A way in named on the invocation — `preset:<name>`,
   `sample=<path>` — settles that choice; bare `style` asks. Build the tables, show them in full in the reply that
   asks about them (conventions §7.12: an option states a consequence, the draft itself is quoted
   above it), and write `notes/style.md` to the conventions §8.11 schema only after the user
   confirms — asked at every involve level (conventions §7.9): the dials are the author's. A run
   that finds a profile on disk starts from it: show the current tables, change only what the
   user asks, append the trail entry — never re-derive unasked. Then stop: a profile run edits no prose, runs no build, files no report, and its
   closing line is `stage-copy-editor <section>` — the run that puts the dials to work.
3. **Read whole first and freeze protected content.** Read each in-scope
   `manus/secs/<n>_<slug>.tex` end to end before editing: note flow breaks, canon violations,
   over-budget signs, repeated openings or endings, and anything that smells like a meaning problem
   (route it; do not fix it). Record the exact numbers, math, citation/reference/label keys, `% src:`
   anchors, `\todo{}` markers, claim strength, attribution, and evidence-required qualifiers that the
   pass may not change.
4. **Diagnose and edit in place.** Inspect paragraphs for clusters from the human-writing contract:
   inflated significance, vague attribution, shallow analysis tails, formulaic contrast,
   over-signposting, forced symmetry or triads, terminology drift, uniform rhythm, generic outlooks,
   manufactured depth, and chatbot residue. Identify what the cluster is doing before rewriting the
   paragraph around its main claim; do not replace words mechanically. Then edit table and figure
   captions (`manus/tabs/` caption prose only — data cells and `% src:` lines are untouchable).
   Apply Principles 1–3, 7, and 8; keep a per-section count of edits by kind and of advisory patterns
   reviewed.
5. **Trim to budget.** Compare each section against its outline budget — page estimate from the
   latest build in `wkdrs/builds/` when one exists, else word count as a proxy. Tighten where
   prose alone closes the gap; record the remainder as a routed finding (Principle 4).
6. **Verify the build.** Run `execs/run.sh` (`bash`). On failure, bisect the session's edits,
   revert the breaker, rebuild — only a compiling manuscript leaves this skill.
7. **Verify conservation and review warnings.** Compare the edited scope with the Step 3 inventory;
   any changed protected item is restored before the pass continues. Re-read paragraph openings,
   sentence-length variation, transitions, and paragraph endings against `notes/style.md` when it
   exists, or a restrained, direct scholarly default when it does not. Run `execs/scpts/lint.sh`;
   prose-pattern warnings are advisory and enter the report, but they authorize neither a blind
   rewrite nor a change to the lint gate's hard-failure rules.
8. **Report.** Write `wkdrs/reports/POLISH_<date>.md` (`mkdir -p` first) per Output. Append one
   `- [ ]` item per systematic or routed finding to `tasks/polish_followups.md` under a
   `## <date>` heading — location(s), issue, route; a re-run checks off items the new pass shows
   resolved.
9. **Digest in chat.** ≤300 words: sections polished, edit counts by kind, canon violations
   fixed, budget state per section, findings routed, report path.
10. **Commit (conventions §1).** One commit for the session — the edited `manus/` files and
   `tasks/polish_followups.md`, or `notes/style.md` alone after a profile run — subject naming
   this skill. `wkdrs/` is never committed.

## Output

- Polished prose in `manus/secs/*.tex` and caption text in `manus/tabs/*.tex` — byte-identical
  in every number, key, label, `% src:` comment, and `\todo`.
- `wkdrs/reports/POLISH_<date>.md` — output-table row: Audit reports, producer `stage-copy-editor`,
  ephemeral, date in filename. Frontmatter `date:`, `scope:`; sections `## Edits` (per-section
  counts by kind), `## Systematic issues` (numbered; locations and route each), `## Naturalness`
  (pattern clusters reviewed, material rewrites made, lint warnings remaining, and any issue left
  unchanged because conservation could not be proved), `## Canon`
  (violations fixed; unknown terms flagged), `## Style` (one line per dial in `notes/style.md`:
  what the polished text now measures against it, and every dial this pass could not reach, said
  plainly — a dial is measured and reported, never turned into a gate), `## Budget` (per-section
  actual vs budget), `## Tasks filed`. The Style section is omitted when no profile exists.
- `tasks/polish_followups.md` — one checkbox per finding this skill may not fix itself: the
  durable backlog.
- `notes/style.md` on a `style` run and on no other — the dial table, the prefer/avoid and never
  lists, and the samples, to the conventions §8.11 schema (output-table row: Style profile). A polish
  run reads it and never writes it, and a `style` run writes nothing
  else durable — measurement scratch under `wkdrs/` (gitignored, regenerable) excepted.
- No writes to the ledger, the outline, the notation canon, `mates/`, or the bib — ownership of
  claims, structure, and canon stays with the skills that hold it.
- Provenance (conventions §8): every artifact this run writes under `notes/`, `tasks/`, `cycls/`, or `wkdrs/reports/` carries `model_id:` — this session's model id, verbatim — and one appended `model_trail:` entry for this run. Nothing under `manus/` or `mates/` carries either, and neither does `cycls/<cycle>/venue.yml`.
