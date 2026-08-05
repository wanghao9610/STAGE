---
topic: <这个文献库覆盖什么>
updated: YYYY-MM-DD
model_id: <this session's model id, verbatim | unrecorded>
model_trail:                    # append-only: one entry per write session, never rewritten
  - { date: YYYY-MM-DD, model: <id | unrecorded>, skill: stage-refs-curator, scope: <what this session wrote> }
---

# Reference Index —— <主题>（<YYYY-MM-DD>）

<!-- 由 /stage-refs-curator 写出。本文件是 manus/bibs/reference.bib 的审计线索：每条条目的出处
     都记在这里，因此 bib 里的任何字段都能对照它来自的那条记录复查。第 4 节里没有行的条目，
     不允许存在。 -->

## 1. 范围

<!-- 驱动本次运行的是什么：论文的 story 与主张台账、mates/ 下导入的 refs 树，或用户给的
     topic。存放原始内容的运行缓存：wkdrs/refs_<date>/raw/。
     模式：survey | intake | add | discover | seed | tidy | position | score | verify。
     跑过的每一条检索式，各自带上返回了多少条命中——命中为零的也写：查了没有是一个结果，
     只有这份记录能把它和"根本没查"分开。discover 那一轮还要写明请求预算与实际用掉多少。 -->

## 2. 有笔记的论文

<!-- notes/refs/ 下每份阅读笔记一行。"为什么在这里被引"写的是本篇稿件的理由，不是那篇论文的
     摘要。影响力分抄自第 5 节的总分，放这里是为了好读。 -->

| Citekey | 笔记 | 会议/期刊 | 为什么在这里被引 | 影响力分 | Model |
| --- | --- | --- | --- | --- | --- |
| `<2021_CLIP_Radford>` | [CLIP.md](CLIP.md) | <ICML 2021> | <一句话> | <9.6> | <model id> |

## 3. 类别

<!-- 跑过 `position` 之后 reference.bib 被组织成的那些 `%%` 块。条目数合计等于总条目数；
     第一次 `position` 之前，本节写"尚未聚类"。 -->

| 类别 | 条目数 | 范围 |
| --- | --- | --- |
| <具体的类名> | <n> | <一行> |
| **合计** | **<n>** | |

## 4. 出处（Provenance）

<!-- reference.bib 每条一行——100% 覆盖，无例外。"来源"是字段转录自的那条记录，播种来的写
     mates/<slug>，手工添加的写 user-supplied。自拟缩写标 †，arXiv-only 标 ‡。这里的记录 URL
     与抓取日期，就是该条目在 reference.bib 里那行 `% src:` 的内容。 -->

| Citekey | 来源 | 记录 URL | 抓取日期 |
| --- | --- | --- | --- |
| `<2021_CLIP_Radford>` | DBLP | <https://dblp.org/rec/conf/icml/...bib> | <YYYY-MM-DD> |

## 5. 影响力评分

<!-- 每条一行，算式与分档见 source-policy_zh.md"影响力分"一节：子指标带各自的抓取日期，然后是
     加权总分。`*` 标残缺总分（某分量没抓到，权重已归一化）；`new` 标发表 ≤18 个月的论文。星标
     只给论文自己页面挂出的仓库——unofficial 仓库在此登记，绝不计分。指标会漂移：日期说明新鲜
     度，/stage-refs-curator score 重建整表。 -->

| Citekey | 年均引用（抓取日） | 发表档 | 星标（仓库，抓取日） | 总分 |
| --- | --- | --- | --- | --- |
| `<2021_CLIP_Radford>` | <6100（YYYY-MM-DD）> | <10> | <30.1k（openai/CLIP，YYYY-MM-DD）> | <9.6> |

## 6. 待人工核对

<!-- 找不到权威记录的论文；有歧义的匹配（列出候选及其 URL）；字段看起来不对但仍照原样转录、
     没有静默修正的记录。每条写明要核什么、去哪核。干净时写"无"——绝不省略本节。这里是详细的
     一侧：reference.bib 末尾的 `%% Needs manual check` 块每篇一行，指到这里。 -->

## 7. 自查

<!-- 重抓并 diff 了哪些条目（随机 5 条；verify 模式下是全部）、结果如何、解析 / 括号 /
     唯一性检查的结果、从登记子指标复算的 3 条影响力分，以及因此改正了哪些条目。 -->

## 8. 下一步

<!-- 值得再跑一轮补的缺口（某个类别偏薄、被引却没有笔记的工作、方案没碰的历史 citekey），
     以及 discover 翻出来但没人收的每一条候选——是哪条检索式找到它的、为什么被放过，好让
     下一次运行提议点新的、而不是同一份清单。
     转交：拿这些笔记核验稿件里的断言 → /stage-cite-auditor；按聚类起草 Related Work →
     /stage-sect-drafter；以后单加一篇 → /stage-refs-curator <arxiv-id>；去找没人点过名的
     工作 → /stage-refs-curator discover；重查整个 bib →
     /stage-refs-curator verify；引用与星标漂了 → /stage-refs-curator score。 -->
