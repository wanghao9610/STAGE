# Review Templates（评审模板）

> 本文件是 `review-template.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是英文版。两版冲突时，以 `review-template.md` 为准。

五份模板：单视角评审、quick 模式的合并评审、综合评审、外部评审对象的审稿意见书、引用审计。每一节都要填；没什么可说的一节写 "None found."——缺失的一节读起来像是没查过的一节。所有产物都用英文写；对话是中文时，以 中文要点摘要 收尾综合评审。

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

魔鬼代言人的评审在 Scores 之前多加一节：

```markdown
## Verdict on the Rejection Case
Strongest case: <one sentence>. Best rebuttal: <one sentence>.
Survives rebuttal: <yes|no> — <why>.
```

## review_quick.md

把上面五个视角小节按评审组顺序串起来（魔鬼代言人放最后），每个压缩成没有 Summary 的形式（顶部共用一个 Summary），然后在同一个文件里直接接上下面的综合评审各节。开头写："Quick mode — single sequential pass; perspectives are not independent."

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

## REFEREE_<date>.md

带 `extern=` 的运行写出的报告。正文就是上面的 `meta_review.md`，只有四处改动，此外没有别的：

- frontmatter 写成 `type: referee_report`、`target: <extern= 拿到的那个路径>`、`venue:`、`scale:`、`mode:`、`generated:`、`recommendation:`——不带 `cycle:`，因为根本没有。
- `## Major Weaknesses` 每一行去掉 "attacks <claim IDs>" 那一段。锚点与"由哪些视角提出"保留；没有记录表可点名，不等于可以省掉位置。
- `## Action List` 整节省略。那是自评那一节，而这篇论文不归我们修。
- 文件以一行收尾，说清它是什么：给那位人类审稿人改的草稿。venue 收到的是那个人提交的东西，绝不是这份文件。

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
<!-- 评审员返回的每条线索一行。判据是那位评审员在主席去跑这条查询之前就写下的——由它决定结果，
     而不是看到命中之后再下的判断。 -->
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

每一份评审产物陈述的都是本次运行产生的事实；模板里没有任何一处邀请来自记忆的内容。如果某一列无法从本次运行自己的记录里填出来，那一行就不该出现在文件里。
