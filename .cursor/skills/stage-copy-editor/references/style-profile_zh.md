# Style Profile —— 档位、它们从哪来、每一个怎么量

> 本文件是 `style-profile.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是英文版。两版冲突时，以 `style-profile.md` 为准。

`notes/style.md` 把这篇论文的散文该怎么读记下来，只记一次，好让六周之后的一次起草写出和今天同一种腔调。schema 是规约 §8.11；本文件是干活用的细节：档位的封闭词表、得出一套档位的三条路径、打磨报告里每一行背后的量法，以及冷启动可以从哪儿开始的预设。

在 `style` 那一遍问出第一个问题之前读它。

## 唯一的硬规则

**一个档位改变一句话怎么读，绝不改变它断言了什么。** 下面的一切都是为了让这条可核查而不是靠指望：设定是报告能 grep 的字面量，量法是命令而不是印象，而每一个量不出来的档位都在报告里直说，绝不靠感觉给分。一份非得改掉一个数字、拿掉一个限定语、换掉一个规范术语、或了结一个 `\todo` 才能被满足的档案，不是一份严格的档案——是一份错的档案，这时运行把这件事说出来，并且不动那句话（规约 §8.11、§9）。

## 档位词表

封闭列表。一个 `Setting` 单元格只放下面的字面量之一，别的都不放；作者想要而这些表达不了的东西，作为句式写进 `## Prefer / Avoid`，或者作为自由文本写进 `Notes`——那是给人读的，没有报告去量它。

| Dial | Settings | 管什么 | 怎么量 |
|---|---|---|---|
| `sentence length` | `short` \| `medium` \| `long` | 每句词数的中位数——`short` ≤ 22，`medium` 23–30，`long` > 30 | 散文行的词数中位数 |
| `voice` | `active, first-person plural` \| `active, impersonal` \| `mixed` | 论文说"we"还是"this paper" | 每 100 句 we/our/us 出现率——只量人称；主动/被动靠判断 |
| `paragraph opener` | `claim-first` \| `context-first` | 一段的第一句是给出论点还是先铺垫 | 判断——只报告，不量化 |
| `hedging` | `minimal` \| `standard` \| `cautious` | 一个结果周围裹多少限定 | 每 100 句里含限定词的句数 |
| `enumeration` | `\parahead runs` \| `itemize lists` \| `mixed` | 一串要点用什么形式排 | `\begin{itemize}` 与 `\begin{enumerate}` 的数量对 `\parahead` 的数量 |
| `tense` | `present for method, past for experiments` \| `present throughout` | 跨章节的时态约定 | 判断——只报告，不量化 |
| `math density` | `sparse` \| `standard` \| `heavy` | 论证有多少跑在记号里而不是散文里 | 每页的行间公式环境数 |

有两个档位被刻意标成*判断*。把它们当成量出来的数报告，就是把一项从没跑过的检查报成跑过了（规约 §7.4）；一遍打磨只说它看见了什么、改了几处，不多说。

`hedging: minimal` 是唯一一个有杀伤半径的档位，所以它的边界写进了文件本身：它管的是填充——"we believe"、"it seems that"、"somewhat"、"arguably"——绝不管证据所要求的限定语。证据只覆盖 ADE20K 时写"improves on ADE20K"是最小限定；写"improves across benchmarks"是改了主张，那归 `/stage-sect-drafter` 和记录表，不归这里。

## 三条入口

一次运行选一条——调用时带的 token（`style preset:<name>`、`style sample=<path>`）直接选定——`source:` 记的就是用了哪条。修订性的运行从盘上的档案出发，只改被要求改的部分。

**1. `interview`。** 一个档位问一个问题，标出推荐项、陈述后果（规约 §7.3）——绝不七个一起问。从 venue 起手：一篇 8 页的会议论文和一篇期刊投稿想要的 `sentence length` 与 `math density` 默认值不一样，而该周期的 `venue.yml` 本来就已经装载了。作者在乎的档位定下来就停止提问，其余取下面预设的默认值并记录在案（规约 §7.8）。

**2. `sample`。** 作者指定 1–3 段——他们自己早先的论文、一篇他们欣赏的论文、他们为这篇写的一段。用下面的量法量这些样例，提出这些测量所蕴含的档位表，把数字和表一起摆出来，然后问。作者说得出"就照这个"却懒得回答七个问题时，这一条最值得优先。

**样例给什么，绝不给什么。** 它给的是档位设定、一种句式模式所蕴含的 `Prefer / Avoid` 行，别的都不给。措辞不从样例跨进 `manus/`——一个短语不行，一个原样搬过来的句式框架也不行。这对作者自己早先的论文同样适用：查重不问源文是谁写的。不是作者自己写的样例，存指针加短摘录，绝不存整段——仓库可能公开，档案要留的是档位，不是原文。每份样例连同出处存进 `## Samples`，并用一行说清该从中取走什么，好让之后的运行不必重读源文就能重新推出档位。

**3. `preset:<name>`。** 从下面某个命名预设起手，摆出来，让作者在写入之前改行。`source:` 记成 `preset:<name>`，好让之后的运行知道这些档位是采纳来的而不是推导来的。

## 那个文件

只有在表整份摆出来并被确认之后才写。真实日期取自系统时钟（规约 §4），本次会话的 `model_id` 与一条 `model_trail` 条目（规约 §8）。

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

## 量法

`execs/scpts/fmt.sh` 把 `manus/` 保持在一句一行（规约 §3.7），这正是下面这些能是一行命令而不是一个解析器的原因。每条都先滤掉纯注释行和纯标记行；每条都只跑在范围内的那些节上，绝不跑 `manus/stys/` 或 `cycls/*/template/` 下的 venue kit。

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

每一条作为一个数报在它对应的档位旁边。量不成的档位——没有构建、缺工具、某节还停在 `skeleton`——报成"未测量"并给出原因。绝不把没达标的数朝目标方向抹（规约 §7.4）。

有两条限制要说明，因为藏起来的报告会把自己检查过的范围说大。`Never` 扫描是**逐字且不分大小写**的：`delve into` 匹配不上 `delves into`，所以有屈折变化的词由作者在乎的每种形态各占一行，而报告要说清这次扫描是逐字的。另外，只有在 `fmt.sh` 跑过的地方，一个 `prose` 行才等于一个句子——仍按列宽折行的文件量的是它的行而不是它的句子，所以先跑 `bash execs/scpts/fmt.sh --check`，它报出漂移的地方就把句长那个档位报成未测量。

## 预设

只是起手点，不是家法。每个都是一整套档位；作者在任何东西被写入之前先改行。

**`preset:terse`** —— 8 页视觉会议的默认。`sentence length: short`、`voice: active, first-person plural`、`paragraph opener: claim-first`、`hedging: minimal`、`enumeration: \parahead runs`、`tense: present for method, past for experiments`、`math density: standard`。Never："novel"、"in this paper we propose"、"it is worth noting that"。

**`preset:expository`** —— 给贡献是一个想法而不是一张表的论文。`sentence length: medium`、`voice: active, first-person plural`、`paragraph opener: context-first`、`hedging: standard`、`enumeration: mixed`、`tense: present throughout`、`math density: standard`。

**`preset:journal`** —— 给篇幅更长、没有页数压力的投稿。`sentence length: medium`、`voice: active, impersonal`、`paragraph opener: claim-first`、`hedging: cautious`、`enumeration: itemize lists`、`tense: present for method, past for experiments`、`math density: heavy`。

## 什么绝不进这份档案

- **归别的文件管的规则。** 术语决定归 `notes/notation.md` 的术语规范；页数预算归 `notes/outline.md`；页数上限或匿名要求归 `venue.yml`。一个复述了其中之一的档位，制造出的是第二个真相源，而它一定会漂。
- **关于内容的规则。** "永远对比三个 baseline"是提纲的决定。"不要过度宣称"是记录表和 §9 的活。这份档案对论文说什么没有意见。
- **关于英文以外语言的规则。** 无论 `STAGE_LANG` 取什么值，`manus/` 下的一切都是英文（规约 §7.6）；档案的 `Notes` 列可以用本次运行的语言写，它的设定不行。
- **作者本次运行没有确认过的东西。** 档位是作者的，不是这一遍的——没被回答的档位取预设默认值并记录为"代为决定"，绝不编出来再当成他们的意思。
