# Review Templates

Four templates: the individual perspective review, the quick-mode combined review, the
meta-review, and the citation audit. Fill every section; a section with nothing to say gets
"None found." — an absent section reads as an unexamined one. All artifacts in English; the
中文要点摘要 closes the meta-review when the dialogue is Chinese.

## review_<perspective>.md

```markdown
# Review — <Perspective Name>

**Paper:** <title or target path> · **Venue/scale:** <venue_year, conference-6 | journal>

## Summary
<The panelist's 3–5 sentence paper_summary, verbatim.>

## Strengths
- <point> (<anchor>)

## Major Weaknesses
1. <point> (<anchor>)
   Evidence: <evidence> · Fixable: <yes|no|partially> · Attacks: <claim IDs or —>

## Minor Weaknesses
- <point> (<anchor>)

## Questions to the Authors
1. <question answerable in a rebuttal>

## Scores
<dimension>: <1–6> · Overall lean: <1–6> · Confidence: <1–5>

## References Named
| As cited | Origin | Record |
|---|---|---|
| <name_as_cited> | whitelist | <paper's bib key/number> |
| <name_as_cited> | verified | <title, authors, year, venue — URL> |
```

Devil's-advocate reviews add one section before Scores:

```markdown
## Verdict on the Rejection Case
Strongest case: <one sentence>. Best rebuttal: <one sentence>.
Survives rebuttal: <yes|no> — <why>.
```

## review_quick.md

The five perspective sections above concatenated in panel order (devil's advocate last), each
compressed to Summary-less form (one shared Summary at the top), followed directly by the
meta-review sections below in the same file. Open with: "Quick mode — single sequential pass;
perspectives are not independent."

## meta_review.md

```markdown
---
type: peer_review
target: <manus/main.tex | path>
cycle: <venue>_<year>
scale: <conference-6 | journal>
mode: <panel | quick>
generated: <YYYY-MM-DD>
recommendation: "<4 — Borderline Accept (confidence 3) | Major Revision>"
---

# Meta-Review — <paper title>

## Summary
<What the paper does and claims, 4–6 sentences, neutral.>

## Strengths
- <consolidated, with anchors and which perspectives raised each>

## Major Weaknesses
1. <consolidated point> (<anchor>) — attacks <claim IDs or —>; raised by <perspectives>; fixable: <…>

## Minor Weaknesses
- <batched, with anchors>

## Questions to the Authors
1. <deduplicated, rebuttal-answerable>

## Limitations & Ethics
<What the paper itself acknowledges; anything the panel adds; "None found." if clean.>

## Concern Matrix
| # | Concern | Nov | Snd | Exp | Clr | DA | Severity |
|---|---------|-----|-----|-----|-----|----|----------|
| 1 | <short name> | ✓ | ✓ | | | ✓ | major |

## Recommendation
**<score/tier>** · Confidence: <1–5, conference only>

<Justification paragraph: the anchor band matched and why, each triggered cap by name, what
independent agreement drove the majors, and — for 3/4 or Major Revision — what would move it up.>

<Journal only:>
### Required Revisions
1. <imperative, anchored, with its satisfaction condition (Major only)>
### Suggested (non-blocking)
- <…>

## Synthesis Notes
Dropped as unanchored: <items and whose, or "none">. Panel disagreements: <where and how
resolved, or "none">. Perspectives missing: <dropped panelist, or "none">.

<Self-review only:>
## Action List (ranked by score impact)
1. <fix> — <file> — <what it buys> — <sibling skill>

<Chinese dialogue only:>
## 中文要点摘要
<推荐意见与置信度、主要问题 3 条以内、最高优先级修改项；不引入英文正文没有的内容。>
```

## citation_audit.md

```markdown
# Citation Audit — <run directory>

Mode: <online | OFFLINE — degradation notice: reviews name whitelist references only>

## Named References
| Ref (as cited) | Used in | Origin | Query | Record URL | Fetched |
|---|---|---|---|---|---|
| <name> | <review file / weakness #> | whitelist | — | — | — |
| <name> | <…> | verified | "<query>" | <url> | <YYYY-MM-DD> |

## Leads
<!-- One row per lead a panelist returned. The criterion is what that panelist wrote before
     the chair ran the query — it decides the outcome, not a judgement made after the hit. -->
| Lead (query) | Raised by | What it would settle | Settled as |
|---|---|---|---|
| "<query>" | <perspective> | <criterion, written before the result> | <verified ref \| direction \| no result> |

## Searches With No Usable Result
| Query | By | Hits | Outcome |
|---|---|---|---|
| "<query>" | <perspective> | 0 | comment rewritten as direction |

## Rewritten or Dropped
- <comment> — <reason: unverifiable reference | lead that missed its criterion>
```

Every review artifact states facts the run produced; nothing in a template invites content from
memory. If a table column cannot be filled from the run's own records, the row does not belong in
the file.
