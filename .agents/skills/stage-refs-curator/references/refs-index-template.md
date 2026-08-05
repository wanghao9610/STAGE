---
topic: <what this reference base covers>
updated: YYYY-MM-DD
model_id: <this session's model id, verbatim | unrecorded>
model_trail:                    # append-only: one entry per write session, never rewritten
  - { date: YYYY-MM-DD, model: <id | unrecorded>, skill: stage-refs-curator, scope: <what this session wrote> }
---

# Reference Index — <topic> (<YYYY-MM-DD>)

<!-- Written by $stage-refs-curator. This file is the audit trail for manus/bibs/reference.bib:
     every entry's origin is recorded here, so any field in the bib can be re-checked against the
     record it came from. An entry with no row in section 4 is not allowed to exist. -->

## 1. Scope

<!-- What drove this run: the paper's story and claim ledger, an imported refs tree under mates/,
     or a topic the user gave. The run cache holding the raw payloads: wkdrs/refs_<date>/raw/.
     Mode: survey | intake | add | discover | seed | tidy | position | score | verify.
     Every query that was run, each with the number of hits it returned — the zero-hit ones
     too: "we looked and found nothing" is a result, and only the log tells it apart from
     "we never looked". A discover run also states its request budget and how much it spent. -->

## 2. Papers with notes

<!-- One row per reading note under notes/refs/. "Why it is cited here" is this manuscript's
     reason, not the paper's abstract. Score is section 5's total, repeated for reading. Depth is
     `—` for a note written here, where the read is a floor rather than a scale; for a seeded note
     it is the upstream note's depth verbatim, and `abstract-and-intro` there marks a paper still
     worth reading properly. -->

| Citekey | Note | Venue | Why it is cited here | Depth | Score | Model |
| --- | --- | --- | --- | --- | --- | --- |
| `<2021_CLIP_Radford>` | [CLIP.md](CLIP.md) | <ICML 2021> | <one clause> | — | <9.6> | <model id> |

## 3. Categories

<!-- The `%%` blocks reference.bib is organized into, after a `position` run. Counts sum to the
     entry count; before the first `position` this section says "not yet clustered". -->

| Category | Entries | Scope |
| --- | --- | --- |
| <specific name> | <n> | <one line> |
| **Total** | **<n>** | |

## 4. Provenance

<!-- One row per reference.bib entry — 100% coverage, no exceptions. "Source" is the record the
     fields were transcribed from, or mates/<slug> for a seeded entry, or "user-supplied".
     Mark coined abbreviations (†) and preprint-only entries (‡). The record URL and fetch date
     here are what that entry's `% src:` line in reference.bib says. -->

| Citekey | Source | Record URL | Fetched |
| --- | --- | --- | --- |
| `<2021_CLIP_Radford>` | DBLP | <https://dblp.org/rec/conf/icml/...bib> | <YYYY-MM-DD> |

## 5. Impact scores

<!-- One row per entry, the arithmetic and bins from source-policy.md (Impact score): sub-signals
     with their fetch dates, then the weighted total. `*` marks a partial total (a component
     unfetched, weights renormalized); `new` marks papers ≤18 months old. Stars only for a repo
     the paper's own page names — an unofficial repo is noted here, never scored. Metrics drift:
     the dates say how fresh, and $stage-refs-curator score rebuilds this table. -->

| Citekey | Cites/yr (fetched) | Venue tier | Stars (repo, fetched) | Score |
| --- | --- | --- | --- | --- |
| `<2021_CLIP_Radford>` | <6100 (YYYY-MM-DD)> | <10> | <30.1k (openai/CLIP, YYYY-MM-DD)> | <9.6> |

## 6. Needs manual check

<!-- Papers no authoritative record could be found for; ambiguous matches (list the candidates and
     their URLs); records whose fields look wrong but were transcribed anyway rather than silently
     corrected. Each with what to check and where. Write "none" when clean — never omit the
     section. This is the detailed side: reference.bib's `%% Needs manual check` block carries one
     line per paper pointing here. -->

## 7. Self-audit

<!-- Which entries were re-fetched and diffed (5 at random; all of them in verify mode), the
     result, the parse / brace / uniqueness check, the 3 impact scores recomputed from their
     logged sub-signals, and any entry corrected as a consequence. -->

## 8. Next actions

<!-- Gaps worth another pass (a thin category, a cited work with no note, a legacy citekey the
     scheme did not touch), and every candidate a discover run surfaced that nobody took in —
     the query that found it and why it was passed over, so the next run proposes something new
     instead of the same list. Routing: verifying manuscript assertions against these notes →
     $stage-cite-auditor; drafting Related Work from the clusters → $stage-sect-drafter; one more
     paper later → $stage-refs-curator <arxiv-id>; searching for work nobody has named →
     $stage-refs-curator discover; re-checking the whole bib →
     $stage-refs-curator verify; refreshing drifted citation and star metrics →
     $stage-refs-curator score. -->
