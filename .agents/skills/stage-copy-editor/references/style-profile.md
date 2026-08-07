# Style Profile — the dials, where they come from, and how each one is measured

`notes/style.md` records how this paper's prose should read, once, so that a drafting run six weeks from now writes the same voice as this one. The schema is conventions §8.11; this file is the working detail: the closed vocabulary of dials, the three ways to arrive at a set of them, the measurement recipe behind every line the polish report prints, and the presets a cold start can begin from.

Read it before the first question of a `style` run.

## The one hard rule

**A dial changes how a sentence reads and never what it asserts.** Everything below is written to make that checkable rather than hoped for: settings are literals a report can grep, measurements are commands rather than impressions, and every dial that cannot be measured says so in the report instead of being scored by feel. A profile that would need a number changed, a qualifier dropped, a canon term replaced, or a `\todo` resolved to be satisfied is not a strict profile — it is a wrong one, and the run says so and leaves the sentence alone (conventions §8.11, §9).

## The dial vocabulary

Closed list. A `Setting` cell holds one of the literals below and nothing else; anything the author wants that these cannot express goes in `## Prefer / Avoid` as a construction, or in `Notes` as free text that a human reads and no report measures.

| Dial | Settings | What it governs | Measured by |
|---|---|---|---|
| `sentence length` | `short` \| `medium` \| `long` | the median words per sentence — `short` ≤ 22, `medium` 23–30, `long` > 30 | median word count per prose line |
| `voice` | `active, first-person plural` \| `active, impersonal` \| `mixed` | whether the paper says "we" or "this paper" | we/our/us rate per 100 sentences — person only; activeness is judged |
| `paragraph opener` | `claim-first` \| `context-first` | whether a paragraph's first sentence states its point or sets it up | judgment — reported, not measured |
| `hedging` | `minimal` \| `standard` \| `cautious` | how much qualification sits around a stated result | hedge-word rate per 100 sentences |
| `enumeration` | `\parahead runs` \| `itemize lists` \| `mixed` | how a series of points is laid out | `\begin{itemize}` and `\begin{enumerate}` count vs `\parahead` count |
| `tense` | `present for method, past for experiments` \| `present throughout` | the tense contract across sections | judgment — reported, not measured |
| `math density` | `sparse` \| `standard` \| `heavy` | how much of the argument runs through notation rather than prose | display-math environments per page |

Two dials are marked *judgment* on purpose. Reporting them as a measurement would be reporting a check that never ran (conventions §7.4); a pass states what it saw and how many places it changed, and nothing more.

`hedging: minimal` is the dial with a blast radius, so it is the one whose limit is written into the file itself: it governs padding — "we believe", "it seems that", "somewhat", "arguably" — and never a qualifier the evidence requires. "improves on ADE20K" where evidence covers ADE20K alone is minimal hedging; "improves across benchmarks" is a claim change, and it belongs to `$stage-sect-drafter` and the ledger, not here.

## Three ways in

Pick one per run — an invocation token (`style preset:<name>`, `style sample=<path>`) picks it directly — and `source:` records which was used. A revision run starts from the profile on disk and changes only what was asked.

**1. `interview`.** Ask the dials in one question each, recommendation marked, consequence stated (conventions §7.3) — and never all seven at once. Start from the venue: an 8-page vision paper and a journal submission want different `sentence length` and `math density` defaults, and the cycle's `venue.yml` is already loaded. Stop asking once the author has settled the dials they care about; the rest take the preset defaults below and are logged as such (conventions §7.8).

**2. `sample`.** The author points at 1–3 paragraphs — their own earlier paper, a paper they admire, a paragraph they wrote for this one. Measure the sample with the recipes below, propose the dial table those measurements imply, show both the numbers and the table, and ask. This is the mode worth preferring when the author can say "like this" faster than they can answer seven questions.

**What a sample gives, and what it never gives.** It gives dial settings, the two-column `Prefer / Avoid` rows a construction pattern implies, and nothing else. Wording does not cross from a sample into `manus/` — not a phrase, not a sentence frame carried over intact. This holds for the author's own earlier papers too: a similarity check does not ask who wrote the source. A sample the author did not write is stored as a pointer plus a short excerpt, never the whole paragraph — the repository may go public, and the dials, not the text, are what the profile keeps. Store each sample under `## Samples` with its attribution and one line naming what to take from it, so a later run can re-derive the dials without re-reading the source.

**3. `preset:<name>`.** Start from a named preset below, show it, and let the author edit rows before it is written. `source:` records `preset:<name>` so a later run knows the dials were adopted rather than derived.

## The file

Written only after the tables have been shown in full and confirmed. Today's real date (conventions §4), this session's `model_id` and one `model_trail` entry (conventions §8).

```markdown
---
updated: YYYY-MM-DD
source: sample
model_id: <verbatim from the runtime>
model_trail:
  - { date: YYYY-MM-DD, model: <id>, skill: stage-copy-editor, scope: initial profile — 7 dials, 4 never rows }
---
# Style profile

## Dials

| Dial | Setting | Notes |
|---|---|---|
| sentence length | short | derived from the sample: median 19 words |
| voice | active, first-person plural | ANON=true keeps self-reference third-person (conventions §3.4) |
| paragraph opener | claim-first | |
| hedging | minimal | never below what the evidence requires |
| enumeration | \parahead runs | itemize only in the checklist appendix |
| tense | present for method, past for experiments | |
| math density | standard | |

## Prefer / Avoid

| Prefer | Avoid | Why |
|---|---|---|
| name the mechanism in the topic sentence | "In this section, we first ... then ..." | a roadmap sentence spends a line and states nothing |
| one clause, one idea | three-clause sentences joined by semicolons | reviewers skim; a long sentence loses its verb |

## Never

| Never | Use instead |
|---|---|
| delve into | examine |
| leverage | use |
| novel | (drop it — the contribution section already says what is new) |
| it is worth noting that | (drop the phrase, keep the sentence) |

## Samples

- Ours, `2025_XSeg_Wang` §3, paragraphs 1–2 — take the claim-first openers and the short
  method sentences; do not reuse wording.
```

## Measurement recipes

`execs/scpts/fmt.sh` holds `manus/` at one sentence per line (conventions §3.7), which is what makes these one-liners rather than a parser. Each strips comment-only and markup-only lines first; each is run over the sections in scope, never over `manus/stys/` or a venue kit.

```bash
# The prose lines a measurement runs over: strip trailing comments, then drop
# blank, comment-only, and markup-only lines. Everything below reads this.
prose() { sed 's/\([^\\]\)%.*/\1/' "$@" \
  | grep -vE '^[[:space:]]*(%|$)' \
  | grep -vE '^[[:space:]]*\\(begin|end|item|label|input|includegraphics|caption|parahead|section|subsection)'; }

prose manus/secs/*.tex > wkdrs/reports/.prose.txt
TOT=$(wc -l < wkdrs/reports/.prose.txt)

# sentence length — median words per sentence
awk '{print NF}' wkdrs/reports/.prose.txt | sort -n \
  | awk '{a[NR]=$1} END {print (NR%2) ? a[(NR+1)/2] : (a[NR/2]+a[NR/2+1])/2}'

# voice — sentences carrying we/our/us, per 100
FP=$(grep -icE '(^|[^a-z])(we|our|us)([^a-z]|$)' wkdrs/reports/.prose.txt)
awk -v a="$FP" -v b="$TOT" 'BEGIN {printf "%.1f per 100\n", 100*a/b}'

# hedging — sentences carrying a hedge, per 100 — base lexicon; extend from the profile's Avoid column
HG=$(grep -icE 'we believe|it seems|arguably|somewhat|to some extent|may be able|it is worth noting' \
     wkdrs/reports/.prose.txt)
awk -v a="$HG" -v b="$TOT" 'BEGIN {printf "%.1f per 100\n", 100*a/b}'

# enumeration — which form the manuscript actually uses
grep -ch '\\begin{itemize}\|\\begin{enumerate}' manus/secs/*.tex | paste -sd+ - | bc
grep -ch '\\parahead' manus/secs/*.tex | paste -sd+ - | bc

# math density — display-math environments per page; the denominator is the newest build
EQ=$(grep -chE '\\begin\{(equation|align|gather|multline)\*?\}|\\\[' manus/secs/*.tex | paste -sd+ - | bc)
PG=$(pdfinfo "$(ls -t wkdrs/builds/*.pdf 2>/dev/null | head -1)" 2>/dev/null | awk '/^Pages:/ {print $2}')
[ -n "$PG" ] && awk -v a="$EQ" -v b="$PG" 'BEGIN {printf "%.1f per page\n", a/b}' \
  || echo "not measured — no build or pdfinfo missing; run execs/run.sh first"

# Never list — pull the terms out of the profile's own table, then locate every survivor
awk -F'|' '/^## /{s=($0 ~ /^## Never/)} s && /^\|/ && $2 !~ /^[- ]*$/ && $2 !~ /Never/ {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2 }' notes/style.md > wkdrs/reports/.never.txt
grep -niFf wkdrs/reports/.never.txt manus/secs/*.tex
```

Report each as a number beside its dial. A dial whose measurement could not run — no build, a missing tool, a section still at `skeleton` — is reported as not measured, with the reason. Never round a miss toward the target (conventions §7.4).

Two limits, stated because a report that hides them overstates what it checked. The `Never` scan is **literal and case-insensitive**: `delve into` does not match `delves into`, so a term with inflections earns a row per form the author cares about, and the report says the scan was literal. And a `prose` line is a sentence only where `fmt.sh` has run — a file still wrapped at a column measures its lines, not its sentences, so check `bash execs/scpts/fmt.sh --check` first and report the sentence-length dial as not measured where it reports drift.

## Presets

Starting points, not house style. Each is a full dial set; the author edits rows before anything is written.

**`preset:terse`** — the 8-page vision-conference default. `sentence length: short`, `voice: active, first-person plural`, `paragraph opener: claim-first`, `hedging: minimal`, `enumeration: \parahead runs`, `tense: present for method, past for experiments`, `math density: standard`. Never: "novel", "in this paper we propose", "it is worth noting that".

**`preset:expository`** — for a paper whose contribution is an idea rather than a table. `sentence length: medium`, `voice: active, first-person plural`, `paragraph opener: context-first`, `hedging: standard`, `enumeration: mixed`, `tense: present throughout`, `math density: standard`.

**`preset:journal`** — for a longer, no-page-pressure submission. `sentence length: medium`, `voice: active, impersonal`, `paragraph opener: claim-first`, `hedging: cautious`, `enumeration: itemize lists`, `tense: present for method, past for experiments`, `math density: heavy`.

## What never enters the profile

- **A rule that belongs to another file.** A terminology decision is `notes/notation.md`'s Terminology canon; a page budget is `notes/outline.md`'s; a page limit or an anonymity requirement is `venue.yml`'s. A dial that restates one of those creates a second source of truth that will drift.
- **A rule about content.** "Always compare against three baselines" is an outline decision. "Do not overclaim" is the ledger's job and §9's. The profile has no opinion about what the paper says.
- **A rule about a language other than English.** Everything under `manus/` is English whatever `STAGE_LANG` says (conventions §7.6); the profile's `Notes` column may be written in the run's language, and its settings may not.
- **Anything the author has not confirmed this run.** Dials are the author's, not the pass's — an unanswered dial takes its preset default and is logged as taken, never invented and presented as theirs.
