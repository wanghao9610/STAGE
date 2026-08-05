# 写作工作流 Skill 通用规约

**语言：** [English](writing-workflow-conventions.md) | 简体中文

本文件是 `writing-workflow-conventions.md` 的中文对照版，随英文版同步维护，供人阅读；两版冲突时以英文版为准。

STAGE 写作工作流中每个 skill 都遵守的规则。十六个 skill——`stage-proj-adopt`、`stage-evid-curator`、`stage-stry-coach`、`stage-outl-planner`、`stage-sect-drafter`、`stage-tabs-builder`、`stage-figs-designer`、`stage-refs-curator`、`stage-copy-editor`、`stage-clms-auditor`、`stage-cite-auditor`、`stage-peer-reviewer`、`stage-resp-writer`、`stage-subm-packer`、`stage-pstr-builder`、`stage-flow-status`——各有自己的工作流、自己的写入边界、自己的质检表。它们共用的部分只在这里存一份。不做分节选读：**每个 skill 每次运行开始时都整份读完本文件。**

**优先级。** 本文件是**基线**。某个 skill 的 `SKILL.md` 可以更**严**——更窄的写入边界、更低的阈值、额外的确认点、乃至"本 skill 永不提交"——更严者生效。skill 绝不放松本文件设下的规则。若 `SKILL.md` 里带有下述某条规则的一行摘要，那一行是有约束力的提醒，本文件是完整规则。各 skill 以"规约 §n"的形式引用这些节；编号是冻结的，永不重排。

本文件既是给 skill 的约定，也是给读者的说明：它写明了这套工作流会对你的手稿做什么、不会做什么。

## 0. 词汇表

本文件与各 `SKILL.md` 直接使用、不再解释的术语。完整定义见"定义处"一列。

| 术语 | 一句话 | 定义处 |
|---|---|---|
| 手稿 manuscript | 本仓库产出的那一篇论文：`manus/main.tex` 加上它 `\input` 的一切 | §5、§10 |
| 章节 section | 一个源文件 `manus/secs/<n>_<slug>.tex`，对应提纲 Sections 表里的一行 | §5 |
| 证据 evidence | `mates/` 下的只读文件，从 STAR 仓库快照而来或由人手工登记，数字与主张引用它 | §8、§9、§10 |
| 指纹 fingerprint | `mates/MANIFEST.md` 里钉住某个证据文件的条目：来源、commit、来源时间戳、导入日期 | §8 |
| 主张 claim | 台账里的一行：论文断言的一句话，连同它写在哪、证据是什么、状态如何 | §8、§9 |
| 台账 ledger | `notes/claims.md`，把每条主张的陈述处 ⇄ 证据 ⇄ 状态连起来的枢纽 | §8 |
| 投稿周期 cycle | 面向一个 venue 的一次投稿尝试：`cycls/<venue>_<year>/` 及其中的一切 | §5、§8 |
| 当前周期 | skill 作用的那个周期：`notes/story.md` frontmatter 里的 `cycle:` | §5 |
| venue 档案 | `cycls/<cycle>/venue.yml`：该 venue 的规则，只以用户确认过的事实录入 | §8、§9 |
| 冻结 freeze | git tag `freeze/<cycle>_<date>`，标记提交出去的究竟是哪一版；只有 `stage-subm-packer` 会创建 | §1 |
| 承诺 promise | 在回复里许下的改动，在 `tasks/<cycle>_promises.md` 里是一个 `- [ ]` 复选框，兑现前一直挂着 | §8 |
| `\todo{...}` | `manus/stys/stage.sty` 提供的红色加粗、可 grep 的宏，标记手稿里每一个尚无来源的取值 | §9 |
| 过期 staleness | 已导入文件的上游时间戳与它记录在案的指纹对不上；靠逐字比对判定，绝不看 mtime | §8 |

## 1. Git

**纪律是"一个 skill 工作会话一次提交"**——由 skill 提出、绝不静默执行，只暂存这次会话的产出，提交标题前缀点名是哪个 skill：`stage-sect-drafter: 3_method — first full draft`、`stage-evid-curator: import xseg results`。一个 skill，在 log 里就是一个命名空间。

**永不提交的 skill**——两个，理由各不相同。`stage-flow-status` 根本什么都不写，所以它对 git 只读使用（`status` / `diff` / `log`）。`stage-proj-adopt` 写得不少——文件搬迁、搬迁逼出的 tex 改动、接入记录——却同样从不提交：接入是在重排别人搭起来的手稿，而复核这次重排不该由一个 skill 替用户跳过。`git mv` 会暂存它自己执行的重命名，除此之外不再 add 任何东西；提交是用户的。

**可以提交的 skill**，及各自能暂存的范围：

| Skill | 提交时机 | 暂存范围 |
| --- | --- | --- |
| `stage-evid-curator` | 会话结束时提供一次 | 本次运行导入或登记的 `mates/` 文件，外加 `mates/MANIFEST.md` |
| `stage-stry-coach` | 会话结束时提供一次 | `notes/story.md`、播下种子的 `notes/claims.md`，以及新建时的该周期 `venue.yml` |
| `stage-outl-planner` | 会话结束时提供一次 | `notes/outline.md`、`notes/notation.md`、新建的 `manus/secs/` 骨架文件，以及 `manus/main.tex` 里的 `\input` 改动 |
| `stage-sect-drafter` | 每起草完一节提供一次 | 该节的 `.tex`，加上它带来的台账、记号表、提纲更新 |
| `stage-tabs-builder` | 会话结束时提供一次 | 写出的表格，加上它们的提纲与台账更新 |
| `stage-figs-designer` | 会话结束时提供一次 | `manus/figs/` 渲染产物、`manus/figs/srcs/` 源文件、提纲更新 |
| `stage-refs-curator` | 会话结束时提供一次 | `manus/bibs/reference.bib`、`notes/refs/` 下的笔记与索引 |
| `stage-copy-editor` | 完成一遍打磨后提供一次 | 只有这一遍改过的 `.tex` 文件——打磨报告留在 `wkdrs/` |
| `stage-clms-auditor` | 完成审计后提供一次 | `notes/claims.md` 的状态翻转与新增的 `tasks/` 条目——审计报告留在 `wkdrs/` |
| `stage-cite-auditor` | 仅当本次运行修过 bib 字段时提供 | `manus/bibs/reference.bib`——发现的问题留在 `wkdrs/` 报告里 |
| `stage-peer-reviewer` | 每份评审提供一次 | 它写出的那一个 `SIM_REVIEW_*` 文件 |
| `stage-resp-writer` | 会话结束时提供一次 | `RESPONSE_*` 文件、`tasks/<cycle>_promises.md`、台账里的降级 |
| `stage-subm-packer` | 打包时一次；`convert` 运行注册 venue 模板包时再一次 | `cycls/<cycle>/SUBMISSION_<date>.md`；`freeze/<cycle>_<date>` tag 随后落在这个提交上——包本身留在 `wkdrs/builds/`。`convert` 的提交是单独一次，只暂存那次运行在 `wkdrs/` 之外写下的东西——`cycls/<cycle>/template/` 下的模板包与 `tasks/<cycle>_venue.md`——好让冻结提交保持它自称的那一个文件 |

**通用规则：**

1. **只暂存本次运行创建或编辑过的东西。** 绝不 `git add -A`，绝不 `git add .`。一把梭的暂存会顺手扫进构建垃圾、登记到一半的证据，以及用户自己尚未提交的改动。
2. **`wkdrs/` 永不提交**（§10）。构建产物可重新生成，报告只是某一刻的快照；一次审计真正留下的东西，是它带来的台账状态翻转和 `tasks/` 条目，而那些都是被跟踪的。一份报告若让人觉得"值得提交"，恰恰说明它本该产出的台账翻转或 `tasks/` 条目缺失了。`.env` 与机器绑定，被忽略。除此之外，登记表（§8）点名的一切都被跟踪——手稿、证据、笔记、周期目录、`tasks/`。
3. **不 push、不改写历史**（`rebase`、`amend`、`reset --hard`）、**不切分支。** 分支和远端归用户所有。
4. **打 tag 的权限是封闭的。** 只有一个 skill 打 tag：`stage-subm-packer` 在打包时创建 `freeze/<cycle>_<date>`。其他 skill 都不创建，任何 skill 都不删除或移动它——冻结 tag 是"提交出去的到底是什么"的不可变记录。
5. **运行开始时就已带有未提交改动的路径，绝不暂存。** 提问时点名这些路径，让用户先自行提交或 stash——一个 skill 的提交绝不能捆进它没做过的工作。
6. **绝不静默提交。** 每次提交都作为一个独立问题提出（§7.2）。拒绝始终是合法答案。

**为什么要紧。** `stage-resp-writer` 会告诉评审人他们读的是哪一版，`SUBMISSION_<date>.md` 会宣称"这个 tag 就是投出去的东西"。这两句话之所以为真，只因为提交来自具名的会话、tag 只来自唯一一个 skill。

## 2. 红线

skill 可以改文本、跑构建、跑**轻量验证**。任何**重的、贵的、外部的、不可逆的**动作都越过红线：把确切命令或操作备好交回用户，然后停下。绝不自主启动——无论 skill 多有把握，也无论周边工作是否已被某个确认点批准。

**轻——skill 可以跑：**

- `execs/run.sh` 构建与 `execs/scpts/lint.sh` 检查——一次完整的 latexmk 编译就是这套工作流的单元测试。
- `execs/scpts/import.sh --diff` 过期报告；`bash -n`；对 `manus/` 与 `notes/` 的 grep 扫描；`texcount`、`pdfinfo`、bib 解析。
- 从 `manus/figs/srcs/` 源文件渲染单张图，只要它几分钟内跑完、且只写自己的产物。
- 任何在**普通笔记本上几分钟内跑完**、且只写在该 skill 允许写入范围之内的动作。

**越过红线——交回用户：**

- **向任何地方提交任何东西。** venue 投稿系统、arXiv 上传、发给编辑或 chair 的邮件。工作流把包打到 `wkdrs/builds/`；上传由用户来做。任何参与度档位（§7.7）都改变不了这一条。
- **启动实验。** 数字缺失从来不构成在这里跑训练或评测的理由——那份工作属于配对的 STAR 仓库和它自己的红线。写作工作流的整个姿态是：缺失的数字变成一个 `\todo{}` 加一条上游任务（§9a），而不是一个计算作业。
- **删除或覆盖 `mates/` 下的证据**、删除冻结 tag、任何 git 历史手术（§1 直接禁止这些；确认点也解锁不了）。
- **`sudo` 或系统包管理器**（apt、brew、tlmgr 安装）——缺工具是一次要如实报出的降级检查（§3.5），不是要去装的东西。
- **超出 skill 自定礼貌速率的批量远端抓取**，以及任何按次计费的大批量调用。
- 任何开销、耗时或影响面**无法界定**的动作。拿不准时，就按红线处理。

**怎么交接。** 给用户确切命令，经 `.env` 环境调用，有对应入口（`execs/run.sh`）时走它；说明它产出什么、落在哪；说明要带回什么，结果才能被核验。把命令写成可运行脚本是轻的；运行它不是。

## 3. `.env` 与构建工具链

五个变量，按 `.env.example` 出厂的样子：

```bash
# Paired STAR project repo (optional — leave empty when writing without one)
STAR_HOME=
# Build engine: pdflatex | xelatex | lualatex
LATEX_ENGINE=pdflatex
# Submission anonymity mode: when true, lint.sh hunts identity leaks
ANON=false
# Upstream STAGE repo used by execs/update.sh
STAGE_REPOSITORY=https://github.com/wanghao9610/STAGE.git
# Optional. Reply and document language: en | zh; empty = follow the conversation
STAGE_LANG=
```

其中四个由入口脚本读取。`STAGE_LANG` 是例外：没有脚本读它，读它的是 skill（§7.6）。

1. **仓库根目录的 `.env` 是这些取值的存放处**，而优先级是**环境变量 → `.env` → 文档写明的默认值**。每个入口脚本都是从文件里读出自己需要的键，而不是 source 整个文件，所以 `STAR_HOME=… bash execs/scpts/import.sh` 和 `LATEX_ENGINE=xelatex bash execs/run.sh` 说什么就是什么，不会被文件悄悄盖掉——这个顺序 `execs/update.sh` 处理 `STAGE_REPOSITORY` 时本来就在用，现在四个入口一致。临时覆盖用命令行变量，长期覆盖去改 `.env`。绝不猜某个本地路径，绝不硬编码，绝不凭对另一个项目的记忆填写。`.env` 本身被 git 忽略，且与机器绑定。
2. **每个变量都有可用默认值**，所以缺 `.env` 从不阻塞构建：`LATEX_ENGINE` 回落到 pdflatex，`ANON` 回落到 false，`STAGE_LANG` 回落到对话本身的语言。`STAR_HOME` 为空是被支持的状态——没有配对仓库地写作——此时 `import.sh` 要求 `--source`，证据以人工投放的形式到达。需要 `STAR_HOME` 却找不到的 skill 会提问（§7）；它绝不臆造一个路径。
3. **每次构建都走 `execs/run.sh`**，它以**树外**方式跑 latexmk：`latexmk -<engine> -interaction=nonstopmode -halt-on-error -outdir=wkdrs/builds manus/main.tex`，engine 取自 `LATEX_ENGINE`。绝不在源码树里裸跑 latexmk：`manus/` 要保持没有 `.aux`/`.log` 垃圾，并且每个构建产物都能随 `wkdrs/` 一起丢弃。成功时 `run.sh` 打印 PDF 路径与页数；`lint.sh` 在它之上做确定性检查。
4. **`ANON=true` 表示仓库处于投稿匿名模式。** `lint.sh` 会额外搜捕身份泄漏——`\author` 内容、致谢、`github.com/<user>`、`\thanks`——泄漏即硬失败。venue 档案里的 `anonymized:` 记录的是 venue 的要求；`ANON` 是操作开关，由用户来拨。发现两者不一致的 skill 要说出来并提问（§7），而不是静默改掉其中任何一个。
5. **没有任何 skill 安装东西。** 缺失的工具——latexmk、pdfinfo、texcount、bib 解析器——意味着一次**降级检查**：能跑的照跑，在报告里点名缺口，并把安装命令交给用户（§2 禁止代跑）。
6. **shell 是无状态的。** `run.sh` 从自身路径定位仓库根，在任何位置都能工作；skill 用绝对路径解析，绝不依赖此前的 `cd`。

## 4. 真实日期

1. **skill 写下的每个日期都取自运行时的系统时钟**（`date +%Y-%m-%d`）。绝不凭记忆、绝不由上下文推断、绝不照抄模板或 schema 示例里的那个（§8 里的 `YYYY-MM-DD` 是占位符）。
2. 写下的日期指明它对应的事件：`imported:` 是导入运行的那天；评审或报告日期是写出它的那天；`SUBMISSION_<date>` 戳的是打包的那天。
3. **唯一的例外是 venue 自己的日历。** `abstract_deadline:` 与 `full_deadline:` 是关于世界的事实，不是关于这次运行的：它们只以用户确认过的取值进入 `venue.yml`（§9c），绝不从时钟、从对往年的记忆、或从"一般是十一月中"推导出来。
4. **同一天重新生成的带日期文件覆盖当天那份；换一天则写自己的那份。** 正是这一点让一个周期目录可以当作时间线来读。

## 5. 手稿、章节与周期的解析

1. **一个仓库一篇论文。** `manus/main.tex` 是入口；这里从不存在"哪一篇"的问题。第二篇论文是模板的第二个实例，而不是这棵树里的第二个分支。
2. **章节参数对着 `notes/outline.md` 的 Sections 表解析**：按编号（`3` 匹配 `#` 列与 `<n>_` 文件名前缀）、按文件 slug（`method`、`3_method`，或一个 `manus/secs/…` 路径）、或按标题匹配（对 Title 列大小写不敏感的子串）。提纲存在之前，只有显式文件名能解析。
3. **缺失或有歧义 → 列出最接近的候选**（编号 + 文件 + 状态，一行一个）并问一个直接的问题（§7.2）。绝不猜用户指的是哪一节。`involve=low` 不下调这一条：对用户本意的歧义在任何档位都要问（§7.7）。
4. **当前周期是 `notes/story.md` frontmatter 里的 `cycle:`**，指向 `cycls/<cycle>/`。调用里显式给出的周期在该次运行中覆盖它。两者都没有 → 提问，或转交 `/stage-stry-coach`，由它创建周期；没有任何 skill 会把创建周期目录当作副作用。
5. **绝不顺手给章节重新编号。** `<n>_` 前缀是承重的：提纲行、台账的 `Stated in` 列、`main.tex` 里的 `\input` 顺序都建在它上面。重新编号是 `stage-outl-planner` 的一次刻意操作，把文件、提纲、`main.tex` 与台账一起改掉——绝不是起草时的副作用。
6. **文件与提纲必须一致。** 有 `manus/secs/` 文件却没有提纲行，或某行指向的文件不存在，都是要报出的漂移（`stage-flow-status` 会点名），而不是在任务中途默默修掉的东西。

## 6. 委派

1. **默认本地执行。** 只委派边界清楚、彼此独立、且委派确实带来实质收益的工作。绝不给每个琐碎的顺序步骤都配一个委派者。**"实质收益"是可判定的**：输入很大、返回很小，且主 agent 事后要重读的是抽查，而不是同一份内容再读一遍。凡本文件或某个 `SKILL.md` 已经要求主 agent 重开同一份证据的地方——每个被审计的数字都要回到它标注的那一行复核（§6.5）、每条评审意见进入逐点台账前都要重读——委派只是把这次读取挪了个地方，并没有省掉它，这种活儿就该留在本地做。**宿主根本不提供委派能力时，本条就是 §6 的全部**：写着"派发"的步骤仍然欠着它那份返回格式，由主 agent 在本地按同样的顺序、照同样的格式把它填出来。**可能并行分派的步骤，要在那一步里把自己的阈值写成一个具体的数**——规模低于这个数，就由主 agent 自己读。"很多章节"这种说法谁也没法拿去核对；"超过 6 个文件"才行。
2. **交给委派者的是**：确切的文件清单、逐项列明字段并以"除此之外什么都不返回"收尾的返回格式、以及逐字写明的范围（"只做这些条目"）。并发的委派者之间**文件归属互不重叠**，且**同时最多三个**——超过三份就每批三个分批发。这个上限管的是同时跑几个，不管一个步骤可以把工作切多细。
3. **主 agent 拥有集成与判断权。** 它亲自重跑每个检查，绝不轻信自报通过。委派者绝不给整体结论打分。返回里自报覆盖面的字段——读了多少节、解析了多少份评审、核了多少条目——和其他断言一样只是断言：数目低于交给它的数量，意味着差额要重新派发，而不是结果变小了。
4. **每个委派者都是只读的。** 没有任何 STAGE skill 带着"实现型委派者"的派发规范，所以**没有任何委派者改动仓库文件，就是这样**——子代理读交给它的东西（章节、评审、证据文件、论文），把交给它的表格填好返回。只有一个例外，且仅此一个：去抓取远端内容的子代理，把抓回来的原始内容写进 skill 指定的 `wkdrs/` 缓存前缀下——每个条目一个文件，此外什么都不写——因为抓回来的记录只有落了盘才可复核。并发子代理的缓存前缀互不重叠。
5. **一条委派断言在穿过确认点或引发写入之前，必须先被确认。** 委派者报出"`mates/<slug>/…#anchor` 处数字对不上"、"某一行的断言没有依据"、"某个指纹已过期"时，它根本没有跑过任何检查：在这条断言进入用户要回答的问题、进入一次台账翻转、或进入本次运行要改的任何文件之前，主 agent 亲自打开它标注的位置确认成立。站不住的就丢掉，或降格成不引发任何改动的一条备注。
6. **换个视角复核的委派者**——被派去重读主 agent 自己写出的散文或自己做完的审计——只有同时满足两点才值得派：盲区是结构性的（它看不见自己从未写下的那句话），且被复核的产物会把关下游的工作。否则主 agent 自己查自己。它是唯一一类主 agent 事后仍要自己再读一遍的委派：换来的是第二双眼睛，不是省下一次阅读。这套工作流把它制度化的形态就是 `stage-peer-reviewer`——一个 skill，而不是临时起意的委派。
7. **`SKILL.md` 里写着"不派子代理"就是不派。** 那一行把整节压平成第 1 条的本地路径，对那个 skill 而言，读多少内容都换不来委派资格。
8. **参与度档位同样管到委派**（§7.7）。`high` 档，fan-out 在派发前连同它的切分方式一起说明；`low` 档则不声张地跑。任何档位下，决策记录（§7.8）都要写明本次运行做了 fan-out、以及是怎么切分的——切分和别的裁量题一样，是一次判断。
9. **请求预算属于 host，不属于 agent。** 抓取型 skill 在 `SKILL.md` 里承诺的礼貌速率，是整个会话对该 host 一起花的，所以同时跑 N 个抓取者，真实速率就是 N 倍。分派抓取的步骤，要么把预算按委派者个数分开、在交办说明里把各自那份写成具体数字，要么一次只抓一个并说明是串行。

## 7. 对话纪律

工具中立的那一半。**怎么问**——AskUserQuestion、某个结构化用户输入工具，还是纯文本——因平台而异，留在各自的 `SKILL.md` 里。

1. **每条聊天回复控制在约 500 词以内。** 写入磁盘的文件不计入。细节属于产物；回复是摘要。
2. **一次只问一个问题，拿到明确答复再据此行动。** 绝不打包批准、绝不默认同意。headless 与脚本化运行同样适用：skill 走到确认点就停下等待，而不是径直往下走。
3. **每个问题带 2–4 个具体选项并标出推荐**，用户始终可以在选项之外自由作答。**每个选项要写清它的后果，而不是把标题再说一遍**：选它会产出或改变什么、会排除掉什么，以及——当答案并非显然可撤销时——能否回退、回退代价多大。"双栏 teaser"是标题；"teaser 只占一栏，给 §4 腾出约 0.4 页，日后换回来意味着重排 intro"才是后果。确实开放的问题（这篇论文的 pitch 是什么？）可以不带选项。
4. **如实汇报。** 缺口绝不往上凑。跳过或降级的检查绝不说成跑过——没跑过的 lint、没尝试过的构建、没有解析器却说解析过的 bib。状态写着 `drafted` 的主张绝不称作 `verified`，假设出来的数字绝不暗示成追溯过的（§9a）。
5. **结论先行**，然后是证据，最后是转交给下一个 skill 的建议——而对那十个 agent 可以自己启动的 skill 来说，"转交"就是直接把它跑起来，而不是打印一条等人来敲的命令（§11.4）。
6. **`STAGE_LANG` 决定回复和本次运行所写内容的语言。** `.env` 的 `STAGE_LANG=en|zh`（§3）同时决定两件事：聊天回复，以及一次运行新写的 Markdown——`notes/`、`tasks/`、模拟评审、`wkdrs/` 报告。未设、为空或取任何其他值 → 跟随用户的对话语言，于是中文对话得到中文回复；运行中明确提出的语言要求优先于两者，并在本次运行的余下部分持续生效。skill 在**每次运行开始时解析一次**，只是一次一行的查询（`grep -sE '^STAGE_LANG=' .env || true`），搭在开场装载调用里，绝不为它单发一次调用。它管的是一次运行**写出**什么，而不是把已经落盘的东西重新翻译一遍：已有文档保持它写成时的语言，改一份文档的语言是用户明确提出的要求，不是翻变量的副作用。

   **无论 `STAGE_LANG` 取什么值，这些一律英文。** 有两样东西会离开这个仓库、被并非作者的人读到，它们始终是英文：**`manus/` 下的一切**——正文、图表标题、`% src:` 注释、`\todo{}` 里的文字——以及**给评审的回复**（`cycls/<cycle>/response/`），那是程序委员会要读的。手稿的语言属于 venue 和用户；对话语言和 `STAGE_LANG` 都不会改写它。除此之外，**一切结构性字面量在任何语言写成的文档里都保持英文**：frontmatter 的键与取值、台账状态（`proposed` / `drafted` / `verified` / `unsourced` / `weakened` / `dropped`）、claim 与评审点的 ID、文件路径、bibkey 及 `reference.bib` 里的一切、venue 名、数据集名与指标名，以及一切被脚本 grep 的字符串。中文笔记配英文结构仍然可被机器读取；被翻译过的状态值会让 `lint.sh` 和每一个读这行的 skill 失灵。
7. **参与度档位：问多少，由用户定。** 工作流提出的每个问题只属于三类之一。**必问确认点**任何档位都要问：红线上的一切（§2——尤其是提交投稿）、每一次提交提议（§1.6）、每一个把关删除或覆盖的确认、每一个以"已确认"身份进入 `venue.yml` 的取值（§9c）、以及对用户本意的任何歧义（§5.3 是章节名的情形）。**裁量题**——第 3 条要求标出推荐项、且怎么选都安全的问题——是档位真正拨动的部分。**可推导的细节**——凡有约定默认值的——任何档位都静默决定；它们从来就不是问题。

   档位由用户设定；skill 在**每次运行开始时、问出第一个问题之前解析一次**，按优先级从三个来源取值：用户加进 `.env` 的 `INVOLVE=` 行（`low` / `medium` / `high`；缺失、未设或非法 → `medium`——这一行是可选的，`.env.example` 不出厂带它），再被调用参数里的 `involve=<level>` 覆盖，再被运行中的自然语言（"少问点""都问我"）覆盖——最后一条指令在本次运行的余下部分生效。读它只是一次一行的查询（`grep -sE '^INVOLVE=' .env || true`），解析一次，搭在 skill 的开场装载调用里，绝不为它单发一次调用。

   **这个写法不是参数。** `involve=<level>` 在解析任何其他内容之前就从调用参数里剥离——章节（§5.2）、周期、模式都在其后。**每个** skill 都如此，包括 `SKILL.md` 里从未提到档位的那些：拿第一个参数去匹配提纲标题的 skill，不得把 `involve=low` 当成章节名。完全不接受参数的 skill 同样要剥离它。

   - `medium`——默认档：本文件与每份 `SKILL.md` 原样执行。档位不增不减。
   - `low`——裁量题不再问：取你本会标为推荐的那一项，并记录在案（第 8 条）。真正的开放题没有推荐项可取，任何档位都要问——拿不准一个问题属于哪一类时，按更需交互的那一类对待。
   - `high`——skill 原文打包进一个确认点的、或在确认点之间自行决定的裁量题，逐条单独问出（第 2 条）。

   凡是问出的问题，第 2 条一字不变：档位只决定哪些裁量题要问，从不决定问出的问题可以默认已答。
8. **先决定，后披露。** 每次运行都留一份决策记录——skill 写持久报告的就写进报告，否则列进最终回复的"Decisions taken"清单——每道落定的问题一行，形如 `问题 → 所取选项 → 它定下了什么`。在 `low` 档，它收录每个未经询问就拿定的裁量题，条数非零时最终回复必须报出条数：`low` 把审查移到事后，从不取消审查。在 `medium` 与 `high` 档，它收录用户答过的选择，让长会话的决策不随滚屏消失。问题一落定就追加一行——这是一本流水账，绝不是在每个问题前重播一段越滚越长的回顾。
9. **档位在单个 skill 里只收紧，绝不放松。** `SKILL.md` 可以声明某个裁量题它永远要问，也可以折叠对它没有意义的档位（故事辅导式的对话没有真正的 `low`）。任何 skill 都不得把必问确认点当作可拨动的。
10. **把线索接住。** 用户连答一长串问题时会丢掉线索。三个便宜的习惯，且刻意不是"每个问题前重播一遍回顾"：**给问题挂上锚点**——用半句话点出它倚赖的那个早先答案（"teaser 占一栏 → §4 多出 0.4 页；现在：这 0.4 页给消融还是给定性图？"）；**在边界处回顾**——每节、每张表、每个周期阶段收尾时，用 2–3 句说清定下了什么、它产出了什么、接下来打开了什么；**点明退路**——边界合上的东西若仍可更改，就说清哪个 skill、带什么参数能重新打开它，以及重新打开的代价（"页数预算可以用 `/stage-outl-planner` 重新议；起草之后再重排，代价就是重新裁字"）。
11. **写出那件事，而不是它的名字。** 读者不该先解开某个词才知道发生了什么，所以非出现不可的名字要把意思一起带上，写在同一句里。它管到本次运行写进文件的正文，不止聊天；它止步于结构：标题、表头、字段名，以及被 skill 逐字匹配的每一个字面量，一律原样保留，需要解释就写在旁边，而不是替换它。**只用来指向别处的字面量，在聊天里必须把说明带上**：`C4`、`W2`、`§9`、一个周期名——每个都原样保留，并在本条回复第一次用到它时，用括号带 3–8 个词说明它指向什么：`C4（零样本迁移那条主张）`、`W2（评审人质疑消融覆盖面）`。是**每一条**回复的第一次，不是整场对话只带一次；同一条回复里后面再出现可以不带。
12. **先把东西摆出来，再问它。** 凡是请用户批准、挑选或修改本次运行所拟内容的问题，都要把那份草稿带进提问的那条回复——按将要写入的样子引出来，紧挨在问题前面。选项不是内容的容身处：选项写的是后果（第 3 条），读者当选择读，不会当待审的正文读。已经写进文件也不算：diff 会滚过去，路径是要用户自己去打开的东西。引出的草稿不计入第 1 条的字数预算——它是被审的产物，不是对产物的说明，长度从来不是省略它的理由；只有长到一两屏以上，问题才收窄到它真正取决的那一段，其余部分点出路径。"这四条贡献就这样写定吗？"而四条贡献在回复里根本没出现——这正是本条规则针对的失败：用户只能同意，无从审阅。

## 8. 产物登记表

每个 skill 的持久产出，汇成一张表。`stage-flow-status` 把它当作覆盖检查的约定来读：某个阶段"已覆盖"，指的是下表的产物存在、且它的状态字段是当前的。保持这张表诚实——改变了自己写什么的 skill，要在同一个提交里更新它这一行，否则状态 skill 会悄无声息地停止检查那个阶段。

| 阶段 | 生产者 | 路径 | 状态字段 |
|---|---|---|---|
| 接入 | `stage-proj-adopt` | `notes/adopt.md` | `adopted:`、`backfilled:` |
| 证据 | `execs/scpts/import.sh` + `stage-evid-curator` | `mates/<slug>/**`、`mates/manual/**`，台账 `mates/MANIFEST.md` | 每条：`source-type:`、`source-stamp:`、`imported:` |
| 故事 | `stage-stry-coach` | `notes/story.md` | `finalized:`、`venue:`、`cycle:` |
| venue 档案 | `stage-stry-coach`（或 `stage-proj-adopt`） | `cycls/<cycle>/venue.yml` | `confirmed:` |
| 主张台账 | `stage-stry-coach` 创建；`stage-sect-drafter`、`stage-tabs-builder`、`stage-clms-auditor`、`stage-resp-writer` 更新 | `notes/claims.md` | 每条主张的 `Status` 列 |
| 提纲 | `stage-outl-planner` 创建；起草 / 图 / 表 skill 更新各自的行 | `notes/outline.md` + `manus/secs/*.tex` 骨架 | `finalized:`；每行的 `Status` |
| 记号表 | `stage-outl-planner` 创建；`stage-sect-drafter` 追加；`stage-copy-editor` 执行 | `notes/notation.md` | `updated:` |
| 章节草稿 | `stage-sect-drafter` | `manus/secs/<n>_<slug>.tex` | 提纲 Sections 行的状态 |
| 表格 | `stage-tabs-builder` | `manus/tabs/<slug>.tex` | 每个数据行的 `% src:` 注释；提纲 Tables 行 |
| 图 | `stage-figs-designer` | `manus/figs/<slug>.pdf`、`manus/figs/srcs/<slug>.*` | 提纲 Figures 行 |
| 参考文献 | `stage-refs-curator` | `manus/bibs/reference.bib`、`notes/refs/refs_index.md`、`notes/refs/<ABBREV>.md` | 索引中是否在列 |
| 审计报告 | `stage-clms-auditor`、`stage-cite-auditor`、`stage-copy-editor` | `wkdrs/reports/CLAIMS_<date>.md`、`CITES_<date>.md`、`POLISH_<date>.md`（临时） | 文件名里的日期 |
| 模拟评审 | `stage-peer-reviewer` | `cycls/<cycle>/reviews/SIM_REVIEW_<date>.md`——评审组的综合评审；各视角的工作文件在 `wkdrs/reports/peer_<cycle>_<date>/` | 文件名里的日期 |
| 回复 | `stage-resp-writer` | `cycls/<cycle>/response/RESPONSE_<date>.md`，承诺在 `tasks/<cycle>_promises.md` | 承诺复选框 |
| 投稿 | `stage-subm-packer` | `cycls/<cycle>/SUBMISSION_<date>.md`、git tag `freeze/<cycle>_<date>`、`wkdrs/builds/` 下的包、注册在 `cycls/<cycle>/template/` 的 venue 模板包、`tasks/<cycle>_venue.md` 里的 venue 待办 | `frozen:`；venue 待办复选框 |
| 海报 | `stage-pstr-builder` | `cycls/<cycle>/poster/POSTER_PLAN.md`、`poster.tex`、注册在 `cycls/<cycle>/poster/template/` 的官方海报模板包、`wkdrs/builds/poster/` 下的渲染产物 | `state:`；每个分区的 Status |
| 状态 | `stage-flow-status` | ——（只读；在聊天里汇报） | —— |

来自 venue 的真实评审由用户投放到 `cycls/<cycle>/reviews/`，命名为
`received_<id>.md`（格式自由）；`stage-resp-writer` 读 `reviews/` 里的一切。

**过期靠逐字比对判定，绝不看 mtime。** 编译或导入产物会把它来源的时间戳*按读取当时的样子*记下来——对证据而言就是 MANIFEST 条目里的 `source-stamp:`，取自上游文件第一行 `generated:`/`updated:`/`finalized:`。判定过期靠把当前上游取值与记录在案的那个逐字节比对；文件 mtime 会因无关原因变动，永不参考。`import.sh --diff` 为证据实现了这一点，`stage-clms-auditor` 在信任任何指纹之前先跑它。

**每份工作流产物都记下写它的模型。** 每个生产者把 `model_id` 写进它在 `notes/`、`tasks/`、`cycls/`、`wkdrs/reports/` 下创建的文件的 frontmatter；还没有 frontmatter 块的文件——`notes/refs/refs_index.md`——为它加一个。取值是运行时为本次写入会话报出的模型 id，原样抄录；而运行时确实会报：STAGE 的 `stage_model_id.sh` 钩子把它写进会话上下文，Claude Code 还会在系统提示里写明。那行注入缺失，或带来的是一条恢复命令而不是 id 时，`model_id_spec.md` 给出各运行时的兜底——先跑它，再考虑写 `unrecorded`，那是留给"会话里任何地方都没写明模型"的取值。绝不凭行为推断，绝不去想"这大概是哪个模型"，也绝不把一份产物的取值抄到另一份上。

**而 `model_trail` 记的是跨写入者的流水。** `model_id` 只说明一次写入；这些文件多半是跨很多次会话写成的——一本被五个 skill 改到论文完稿的台账、每个周期重排一次的提纲、一篇一篇长起来的参考文献库——单个字段在那里只描述最后一次。所以凡带 `model_id` 的产物，旁边都带一份只追加的 `model_trail`：每次写入会话一条，`{ date, model, skill, scope }`，其中 `scope` 用这份文件自己的词汇说清那次会话写了什么——claim ID、章节号、评审要点、表格行。只追加，绝不改写已有条目，并让 `model_id` 始终镜像最后一条，好让一次普通的 grep 仍然有效。一次写成的产物——每份带日期的报告、模拟评审、回复、投稿记录——只有一条；重新生成的产物另起一条新流水，而不是接着它所替换的那一代往下写。形状见 §8.1，这一对字段进入 §8.4–§8.10 每个 schema 的 frontmatter，不在每处重复列出。

**有三处刻意都不带。** `manus/` 下的一切都不带：手稿是交给 venue 和 arXiv 的东西，一篇论文是否披露 AI 参与，是作者按其 venue 政策做的决定，而不是某个 skill 留在 `.tex` 里的一行注释。`mates/` 下的一切也不带：证据不可变（§9d），且它自带溯源——`source-type:`、`source:`、`source-commit:`、`source-stamp:`、`sha256:`、`imported:`——其中很大一部分由 `import.sh` 写入，那是个没有模型可报的 shell 脚本。`cycls/<cycle>/venue.yml` 同样不带：它的取值是用户确认过的事实，`confirmed:` 就是它的溯源（§9c）。不带它们，谁起草了某一节仍然可追：被它改成 `drafted` 的主张行、被它翻状态的提纲行、读过它的审计报告的流水。

有两条限制要紧，因为这些字段会被用来跨模型比较工作：

1. **它们是自报的，不是核验过的。** 记的是运行时在写入当刻的说法。会话中途换过模型的，可能仍被换之前那个字符串描述，于是取值会滞后于事实。把它当作关于溯源的证据，而不是溯源的证明。
2. **流水数的是写入事件，而写入事件不等于贡献。** 流水更长不等于工作更好：它说的是谁在什么时候动过这份文件，完全不说这次动手有没有帮上忙。

`stage-flow-status` 是唯一把它们汇到一起的读者——按产物报出最后写它的模型、它的流水有多长，并点名每一份缺流水的登记产物，那正是这些字段存在之前写成的文件的样子。没有任何东西由它们生成，所以也没有一份需要保持同步的台账文件。

下表指向的文件 schema。写这些文件的 skill 就写成这个形状；读它们的 skill 可以依赖这个形状。

### 8.1 `notes/claims.md`

```markdown
---
updated: YYYY-MM-DD
model_id: <this session's model id, verbatim | unrecorded>
model_trail:                    # append-only: one entry per write session, never rewritten
  - { date: YYYY-MM-DD, model: <id | unrecorded>, skill: stage-…, scope: <what this session wrote> }
---
# Claim ledger

| ID | Claim | Type | Stated in | Evidence | Status |
|----|-------|------|-----------|----------|--------|
| C1 | <one sentence> | contribution \| performance \| factual | `1_intro`, `abstract`, `tabs/main` | `mates/<slug>/...#<anchor>`; `—` if none | proposed \| drafted \| verified \| unsourced \| weakened \| dropped |
```

生命周期：`proposed`（故事阶段）→ `drafted`（已写进正文）→ `verified`（clms-auditor 对上了证据）/ `unsourced`（写了，但没有指纹——必须带 `\todo`）/ `weakened`（在回复里作了让步）/ `dropped`。

### 8.2 `mates/MANIFEST.md`——`mates/` 下每个文件一个 `##` 条目

```markdown
## <slug>/metds/overview.md
- source-type: star            # star | manual
- source: $STAR_HOME/metds/overview.md        # or free text for manual ("results emailed by X, 2026-08-01")
- source-commit: <sha | n/a>
- source-stamp: <first `generated:`/`updated:`/`finalized:` value in source | n/a>
- sha256: <checksum of the file as it landed>
- imported: YYYY-MM-DD
- covers: <one line: what this evidences>
```

`star` 条目由 `import.sh` 管理；`manual` 条目由 `stage-evid-curator` 写。两者都写齐这六个字段。

这两个校验字段回答的是不同的问题，谁也替不了谁。`source-stamp:` 问的是**上游**：这份东西取自的那个文件往前走了吗？它拿当前的上游取值来比对，而 `import.sh --diff` 需要一个够得着的来源才能问。`sha256:` 问的是**这里**：`mates/` 下的字节还是登记时那些吗？它除了文件本身什么都不需要，所以即使在一个没有设 `STAR_HOME` 的仓库里、在一台从未见过上游的机器上，它也能抓住 §9d 禁止的那种原地编辑。校验和绝不会被悄悄重算成与改动后的文件相符——那是把一次编辑洗成出处；它只在重新导入或重新登记时移动。

### 8.3 `cycls/<cycle>/venue.yml`——扁平的 `key: value`，可 grep 解析

```yaml
venue: CVPR
year: 2027
cycle: cvpr_2027
template: cvpr                # the class inside the kit at cycls/<cycle>/template/,
                              # so the generated copy says \documentclass{stys/cvpr};
                              # empty or arxiv = ship the preprint form, no conversion
page_limit_main: 8            # content pages
references_in_limit: false
page_limit_supp: 0            # 0 = unlimited
anonymized: true
abstract_deadline: 2026-11-06
full_deadline: 2026-11-13
response_type: rebuttal       # rebuttal | response-letter | none
response_limit: one page      # the venue's official wording
checklist: none               # none | neurips | acl-arr | custom
scale: conference             # review rubric track: conference | journal (missing = conference)
confirmed:                    # date the USER confirmed these numbers; never filled by a skill on its own
```

### 8.4 `notes/story.md`

frontmatter：`venue:`、`cycle:`、`finalized:`、`updated:`。小节：`## Pitch`（一句话）、`## Problem`、`## Key idea`、`## Contributions`（每条列出它的 claim ID）、`## Venue rationale`。

### 8.5 `notes/outline.md`

frontmatter：`finalized:`、`updated:`。三张表：
`## Sections`：`| # | File | Title | Budget (pages) | Claims | Status |`
（状态：planned | skeleton | drafted | polished | frozen）；
`## Figures`：`| ID | File | Purpose | Section | Source | Status |`
（状态：planned | sketch | draft | final）；
`## Tables`：`| ID | File | Purpose | Section | Evidence | Status |`（状态刻度同图）。

### 8.6 `notes/notation.md`

frontmatter：`updated:`。`## Symbols`：`| Symbol | Meaning | First defined |`；
`## Terminology canon`：`| Use | Never | Notes |`；`## Abbreviations`：`| Abbrev | Expansion | First use |`。

### 8.7 `notes/refs/<ABBREV>.md` 与 `refs_index.md`

笔记 frontmatter：`title:`、`venue:`、`year:`、`bibkey:`、`added:`。小节：`## What it does`、`## Relation to ours`、`## Citable facts`（事实要精确到足以让 cite-auditor 拿它核对断言）。笔记的文件名用论文自己的 `ABBREV` 代号（`CLIP.md`）；`bibkey:` 记的是 bib 里的 citekey，形如 `<Year>_<Method>_<FirstAuthorSurname>`（`2021_CLIP_Radford`）——两者是两个不同的串，这是有意的；已经被 `manus/` 引用的 citekey，以及从 `mates/` 播种来的 citekey，都不会为了迁就方案而被改写。

`refs_index.md` 是这份 bib 的审计线索，分八个小节：范围、有笔记的论文、类别、出处（每条 bib 条目一行，100% 覆盖，自拟代号标 †、只有预印本的标 ‡）、带子指标与抓取日期的影响力评分、待人工核对的细节、自查、下一步。没有出处行的条目不允许存在。确切形状放在 `stage-refs-curator` 的 `references/` 下：本文件见 `refs-index-template.md`，citekey、`% src:` 行、`%% Needs manual check` 块、规范化封闭清单与评分算式见 `source-policy.md`。

### 8.8 评审与回复

`SIM_REVIEW_<date>.md` 是评审组的综合评审，按 venue 的形状写。frontmatter：`type: peer_review`、`target:`、`cycle:`、`scale:`（conference-6 | journal）、`mode:`（panel | quick）、`generated:`、`recommendation:`。小节：`## Summary`、`## Strengths`、`## Major Weaknesses`（编号；每条带锚点，点名它攻击的 claim ID 与提出它的视角）、`## Minor Weaknesses`、`## Questions to the Authors`、`## Limitations & Ethics`、`## Concern Matrix`、`## Recommendation`（锚定的分数档或期刊档、置信度、每个触发的封顶都点名）、`## Synthesis Notes`。完整模板、五份视角简介与评分标准在 `stage-peer-reviewer` 的 `references/` 里；各视角评审与引用审计留在本次运行的 `wkdrs/reports/peer_<cycle>_<date>/` 目录。
`RESPONSE_<date>.md` frontmatter：`cycle:`、`date:`、`sources:`（读过的评审文件）。小节：`## Point ledger` `| Point | Reviewer | Attacked claims | Evidence | Response summary | Promise? |`、`## Draft response`（在 `response_limit` 之内），承诺同步到 `tasks/<cycle>_promises.md` 作为 `- [ ]` 复选框。

### 8.9 `notes/adopt.md`

frontmatter：`adopted:`、`backfilled:`。小节：配对来源（STAR 仓库 + slug）、目标 venue、既有资产清单（针对被接入的项目）、unsourced 主张待办、做过的补录动作。

`backfilled:` 是一道闸门，不是一条备注（§9a）。只要还有任何一行待办没清掉它就保持为空，而且只由 `stage-clms-auditor` 置位——设为真实日期——条件是每一行都已经变成一条 `verified` 主张、或一条带着自己 `\todo` 的 `unsourced` 主张。`stage-subm-packer` 拒绝为一个 `notes/adopt.md` 的 `backfilled:` 仍为空的仓库打包，因为那正是 `lint.sh` 会在一堆追不到任何东西的数字之上读出"干净"的状态。

### 8.10 `cycls/<cycle>/SUBMISSION_<date>.md`

frontmatter：`cycle:`、`date:`、`frozen:`（tag 名）、`package:`（`wkdrs/builds/` 下的路径）、`template:`（这个包被排成的 venue 模板，或 `arxiv`）。正文：lint 摘要、清单结论、页数——取转换出的副本的页数，两者不同时把预印本构建的页数并列在旁——转换丢掉了什么或留给了人什么，以及什么投到了哪里。

同一个产出者的另一份持久产物是 `tasks/<cycle>_venue.md`，由 `convert` 运行维护的 venue 待办清单。frontmatter：`cycle:`、`template:`、`updated:`。正文：一条发现一行 `- [ ]`，各带一个稳定的 `V<n>` 编号和拥有这个修法的 skill。它是被更新的，不是被重新生成的——已勾选的条目保持勾选、永不被重新提出，新发现以下一个空闲编号追加，不再适用的条目连同理由勾掉而不是删除。它们是发现，不是承诺：一个未勾选的框永不阻断打包，这正是它与 `tasks/<cycle>_promises.md` 的分界。

## 9. 编造边界

一篇论文是一条由可核查陈述串成的链，而写作 agent 最廉价的失败方式，就是拿看着像样的材料把链条补全。这套工作流唯一保证的性质是：**`manus/` 里没有任何东西是编出来的。** 数字不是，被引论文说了什么不是，venue 要求什么也不是。五条规则承载这个性质；审计类 skill 的存在就是为了机械地执行它们，而截稿压力——前一晚、缺的那个格子、大家都"记得"的那个数——正是它们校准过的场景。

**（a）`manus/` 里的每个数字，要么追溯到一条带指纹的 `mates/` 条目，要么写成 `\todo{...}`。没有第三种状态。**

- **什么算数字：** 任何带数位、且其真伪存在于手稿之外的取值——指标、差值、数据集规模、参数量、运行时间、epoch、成本、"快 3 倍"。文档自己的机械部分不算：章节号与公式号、图表引用、引文年份、下标索引。判据是评审人问一句"来源？"——如果诚实的回答是一次测量或一个外部事实，本条就适用。
- **"追溯"指的是整条链。** 在表格里：单元格 → 它所在行的 `% src: mates/<...>#<anchor>` 注释 → 一条带指纹的 MANIFEST 条目 → 该取值确实出现在那个证据文件里。在正文里：句子 → 陈述它的那条台账行（`Stated in` 点名本节）→ 该行的 `Evidence` 链接 → 指纹。`stage-clms-auditor` 为每个数字走完这两条链，并逐个判定 **matched / mismatched / unsourced**。
- **一条 `% src:` 注释恰好覆盖一个句子。** 在 `manus/tabs/` 里单位本来就没有歧义——每个数据行一条注释，不共用、不笼统。在正文里，单位是**这条注释所领起的那个句子**：从注释之后的第一个词开始，到该句的句末标点为止，无论这个句子在源文件里换了几行。同一句里的两个数字共用它这一条注释；下一句里的数字需要自己的。这不是抠字眼——按行划界和按句划界会对同一份手稿给出不同判定，而只有单位被钉死，审计才谈得上机械。
- **todo 纪律，具体地说：**

  ```tex
  % In manus/tabs/main_results.tex — every data row names its source;
  % a missing cell is a \todo, and the comment says what unblocks it:
  OVSeg  & 24.8 & 53.3 \\  % src: mates/xseg/wkdrs/results/results.md#tab-main
  Ours   & \todo{A-847 — import STAR results first} & 54.6 \\  % src: mates/xseg/wkdrs/results/results.md#tab-main

  % In manus/secs/4_expts.tex — prose numbers trace through the ledger,
  % so a not-yet-imported delta is a \todo, never a recalled value:
  improves mIoU by \todo{delta vs. OVSeg — awaiting results import} on ADE20K.
  ```

- **凭记忆写下的数字就是无来源的数字。** 凭对某块 wandb 面板、某次会议、或某个你并未导入的 STAR 仓库的记忆敲下 `54.6`，*即便这个数字是对的*，也是编造——被保护的性质是可核查性，不是运气。诚实的写法是上面那个 `\todo{}`，或者把这个来源登记成手工证据（见 e），让数字可以追溯。
- **伪装比编造更糟。** `XX.X`、`TBD`、`99.9`、拿 `\textbf{54.6}` 当"临时"占位——任何标记了空洞却不用 `\todo{` 宏的写法，对 `lint.sh` 的计数都是隐形的，并且会一路活到投出去的 PDF 里。一个宏、可 grep、在每次草稿构建里都是红的：这就是 `stage.sty` 出厂带上它的全部理由，而新克隆的 `main.tex` 恰好带着一个 `\todo{}` 编译通过，正是为了让这套机制在第一天就被演示一遍。
- **派生数字继承本规则。** 一个差值或均值可追溯的条件是：每个操作数都可追溯，且推导方式写在同一条 `% src:` 注释里（`% src: delta of rows 2,5 — mates/xseg/.../results.md#tab-main`）。只要有一个操作数追不到，派生数字就是无来源的。四舍五入属于呈现——有来源的 54.62 可以写成 54.6；改动任何一位数字都不是四舍五入。
- **一个 `\todo` 离开手稿只有两条路：** 被一个可追溯的取值替换（导入发生了，指纹存在了），或者把句子改写成不需要这个取值。删掉宏、留下里面的内容，是加了几步的编造。
- **这个标记是给缺失的*取值*用的，不是给单薄的章节用的。** 一段写得不够、一个谁都没记下超参的方法、一节等着散文的实验——这些都不是 `\todo`。它们是一条提纲状态和一条 `tasks/` 条目。这个区分很吃劲，因为 `lint.sh` 看不出来：一条被塞进标记里的内容备注，挡打包的力度和一个编出来的指标一模一样，而作者会因此学会把红闸门当噪声。标记给取值；其余一切给 `tasks/`。
- **被接入的草稿一开始就在本规则之外，而这个缺口是被点名的，不是被藏起来的。** `stage-proj-adopt` 把一份既有手稿已经陈述的每个数字，登记成 `notes/adopt.md` 里 unsourced 待办的一行。它不给这些数字套 `\todo{}`——它压根不知道哪些是对的，而把别人的结果改写成一堆标记不叫接入。于是在 `stage-clms-auditor` 把那份待办清掉之前，这些数字*就是*本规则禁止的第三态，而 `lint.sh`——它数的是标记——会把手稿读成干净，尽管里面没有一个数字追得到。那是机械闸门与被保护性质唯一分岔的时刻，所以这份待办自己就是一道闸门：`notes/adopt.md` 的 `backfilled:` 在每一行都清掉之前保持为空，而 `stage-subm-packer` 在它为空时拒绝为被接入的仓库打包（§8.9）。
- **执行：** `lint.sh` 统计 LaTeX 真会排版出来的那些 `\todo{`——每个候选行在判定前会先从第一个未转义的 `%` 起剥掉注释，所以一个被注释掉的标记、或一条只是提到这个宏的注释，都不算失败——非零即硬失败，`stage-subm-packer` 拒绝在其之上打包；`stage-clms-auditor` 追溯每个数字，并为每次失败开一条 `tasks/` 条目；每个"知道但没指纹"的取值都带着一条 `unsourced` 台账行，让这笔债有名字。

**（b）关于被引论文的每一条断言，都必须能对着一份阅读笔记核查**（`notes/refs/<ABBREV>.md`，或 `mates/` 下导入的 refs）。

- **可核查**意味着笔记的 `## Citable facts` 里有一条精确到足以判定这句话的事实。"ODISE 在 ADE20K 上达到 23.4 PQ"需要 ODISE 的笔记里有这个数字；"与 [X] 不同，我们不需要框标注"需要 X 的笔记写明 X 需要框监督。光有 bib 条目什么都不支持：它只证明论文存在，不证明论文说了什么。
- 成组引用同样在断言：`[A,B,C] 依赖冻结的 backbone` 是对 A、B、C 每一个都这么说，每一个都需要自己笔记里的那条事实。
- **对一条没有依据的断言，修法绝不是把它含糊化**——含糊地把相关工作摆错位置，依然是假的。诚实的路径：把论文读了并写下笔记（`/stage-refs-curator`）、标成 `\todo{verify: does X require box supervision?}`、或者把这条断言删掉。`stage-cite-auditor` 在报告里标出无法核查的断言；它绝不静默"修好"正文，因为静默的修改就是一次没人复核的主张变更。
- **评审产物把这条规则延伸到手稿之外。** 模拟评审（`stage-peer-reviewer`）要提到手稿未引用的工作，只能在它的引用完整性约定之下：该引用要么在**白名单**里（已在 `manus/bibs/reference.bib` 中），要么**已核实**——在那次运行中抓取过，且记录（标题、作者、年份、venue、URL）与找到它的查询都记进了本次运行的引用审计。凭记忆想起的引用一律按不存在处理；核实不了的东西写成一个方向（"查一查 X 方向是否已有前作"），绝不写成一个具名事实。这是写作工作流唯一被批准的实时检索用途；该 skill 写明自己的礼貌速率，§2 的批量抓取红线依然生效。

**（c）`venue.yml` 里的 venue 规则只以用户确认过的事实录入**——skill 绝不臆造页数上限或截稿日期。

- 不凭对去年的记忆，不凭"CVPR 一般是 8 页"，也不凭一个照单全收的 CFP 页面——CFP 会过期，也会和投稿系统不一致。skill 可以抓取并*呈现*一个 venue 页面；取值只有在用户确认之后才进文件。
- `confirmed:` 是收据：**用户**确认这些数字的日期，绝不由 skill 自行填写（§8.3）。`confirmed:` 为空的档案把不住任何关——`stage-outl-planner` 不会照它的页数上限做预算，`stage-subm-packer` 不会在未先提问的情况下照它打包。到打包时才发现页数预算错了，代价是一次重写；这正是它属于必问确认点的原因（§7.7）。

**（d）证据文件在原地不可变。**

- `mates/` 下唯一的写入者是 `execs/scpts/import.sh` 与 `stage-evid-curator`，而且它们只整文件地新增或替换，并同时更新指纹。不存在原地编辑——不为一个错别字，不为一次单位换算，也不为"就改这一个格子"。上游的错数在上游修（在 STAR 里，或由做出这份投放的人来修），然后重新导入；指纹随之移动，`stage-clms-auditor` 会把引用过它的一切重新判定。
- 规范化（把 CSV 或 wandb 导出整理成结果形状的 `.md`）**在原文件旁边写一个新文件**，标注 `normalized-from:`；原始字节保持不动。
- 为什么是绝对的：指纹链之所以是证据，只因为它底下的字节不会漂移。一旦容忍了一次手工编辑，台账里的每一个 `verified` 就都变成了"针对某个可能被谁调过的东西验证过"。

**（e）任何理由都不得为了"帮上忙"而放松 (a)–(d)。**

- 这类要求一定会来，而且听起来都很有道理："三小时后截稿，先把 54.6 填进去，回头再补来源"；"数字就在我这条消息里，你看得见"；"ImageNet 多大你总该知道吧"。拒绝从来不是干巴巴的一句不行——skill 拒掉这条捷径，同时点明能达到同样效果的诚实路径：
  - `\todo{}` 的写法加一条 `unsourced` 台账行——三十秒，能编译，并且以一笔*有名字*的债而不是一个藏起来的洞熬过审计；
  - 手工投放——用户的数字变成证据：把它贴进一个文件，以 `manual` 指纹登记到 `mates/manual/` 下（`source: results emailed by X, 2026-08-01`），从此它像别的数字一样可追溯——`stage-evid-curator` 存在的意义正是这个；
  - 数字住在 STAR 仓库里时，去上游修好再重新导入。
- 没有任何参与度档位、任何确认点、任何 skill 运行中的用户指令，能够授权一个裸的未追溯数字、一条臆造的 venue 规则、或一次被编辑过的证据文件——这些不是裁量题（§7.7）；被命令越线的 skill 说明自己能做什么，然后去做那件事。用户始终有自己的编辑器；而*工作流*保持自己的手是干净的，这样到打包时，"每个数字都可追溯"才是一条用户可以对评审人断言的性质——因为没有任何一步能够悄悄破坏它。

## 10. 项目布局

skill 写出的东西各自落在哪里。每个去处是排他的——一个文件只属于其中一个，按这个文件*是什么*来定，而不是按哪一步产出了它。

| 是什么 | 放哪里 |
|---|---|
| 手稿入口 | `manus/main.tex` |
| 章节源文件 | `manus/secs/<n>_<slug>.tex`（如 `0_abstract.tex`、`1_intro.tex`） |
| 图 | 渲染产物 `manus/figs/<slug>.pdf`；源文件 `manus/figs/srcs/<slug>.*`——每张图要么有源文件，要么有一条 MANIFEST 条目 |
| 表格 | `manus/tabs/<slug>.tex` |
| 参考文献 | `manus/bibs/reference.bib` |
| venue 样式 | `manus/stys/`：只有 `arxiv.cls` 与 `stage.sty`，别无他物——`manus/` 会被 `lint.sh` 扫描，只放本工作流自己拥有的文件 |
| 导入的证据（只读） | `mates/<source-slug>/**`，镜像上游路径；手工登记的投放在 `mates/manual/**`；台账 `mates/MANIFEST.md` |
| 写作元数据 | `notes/` 下的固定文件：`story.md`、`claims.md`、`outline.md`、`notation.md`、`adopt.md`；阅读笔记在 `notes/refs/` |
| 投稿周期 | `cycls/<venue>_<year>/`：`venue.yml`、`template/`（官方 venue 模板包，整份解包，逐字节，永不编辑）、`reviews/`、`response/`、`SUBMISSION_<date>.md`、`poster/`（海报计划与源文件，官方海报模板包放在 `poster/template/`） |
| 修订草稿、承诺清单 | `tasks/` |
| 构建与临时报告 | `wkdrs/builds/`、`wkdrs/reports/`（gitignore，可重新生成） |
| 早先会话学到、又没有别的文件认领的事实 | `.stage/memory/`；只对本机成立的放 `.stage/memory/local/`，git 忽略（[`memory_spec.zh-CN.md`](memory_spec.zh-CN.md)） |
| 入口脚本 | `execs/run.sh`、`execs/update.sh`——**execs/ 根目录是封闭的**；工具脚本放 `execs/scpts/`。`run.sh` 由上游管理，`execs/update.sh` 会覆盖它；每个项目自己的设置住在 `.env` 里 |
| 工作流文档（上游管理） | `docs/mds/stage-workflow/` |

光有表格带不出来的规则：
1. **`mates/` 是只读的。** `import.sh` 与 `/stage-evid-curator` 是仅有的两个写入者，且只整文件地新增/替换并附指纹。内容层面的修正发生在上游，然后重新导入。
2. **`wkdrs/` 永不提交。** 审计真正留下的东西是 `notes/claims.md` 里的状态翻转和 `tasks/` 里的条目，不是报告。
3. **`execs/` 根目录是封闭的**（沿用 STAR 的规则）：`run.sh` + `update.sh`，此外什么都没有。
4. **稿件永远编译成预印本；venue 的版式是一份生成出来的副本。** `manus/stys/` 分两层，这条分界是承重的：`arxiv.cls`
   管外观，是 venue 的 class 要**替换**掉的那一层；`stage.sty` 管 `\todo`，以及各 skill 会写进 `secs/` 和 `tabs/`
   的那些宏（`\parahead`、`\cmark`、`\tablestyle`、`\figref` …），每次换模板都**活下来**。项目自己的宏写在
   `main.tex` 里，绝不写进 `stys/`。官方 venue 模板包整份、不加编辑地解包进 `cycls/<cycle>/template/`，与该周期的
   `venue.yml` 并列——绝不放进 `manus/`：那是 `lint.sh` 扫描的命名空间，模板包自带的示例 `.tex` 会污染它的 `\todo`
   计数和身份泄漏扫描。`venue.yml` 里的 `template:` 指名模板包中的那个 class；`stage-subm-packer convert` 读它，
   在 `wkdrs/` 下重新生成一份能在该 class 下编译的独立副本。`manus/main.tex` 始终保持
   `\documentclass{stys/arxiv}`：没有就地替换，也没有第二份事实来源。
5. **四棵 harness 目录树是副本，不是备选项。** 同样的十六个 skill 每套 harness 各发一份——`.claude/skills/`、
   `.agents/skills/`、`.cursor/skills/`、`.kimi-code/skills/`——彼此只差调用前缀和工具名（`Bash` / `Shell`、
   `AskUserQuestion` / `AskQuestion` / `request_user_input`、`Read` / `ReadFile`）。装载你自己那棵树下的副本并遵循它；
   某次列目录列出了别的树里的副本，那只是告诉你文件在哪，不是告诉你哪一份约束你。

## 11. Skill 一览

十六个 skill，调用方式：Claude Code 与 Cursor 里是 `/stage-<name>`，Codex 里是 `$stage-<name>`，Kimi Code 里是 `/skill:stage-<name>`。每个 skill 的完整说明见 [writing-workflow-skills.zh-CN.md](writing-workflow-skills.zh-CN.md)（英文：[writing-workflow-skills.md](writing-workflow-skills.md)）；每个 skill 写出什么见 §8。

| Skill | 职责 |
| --- | --- |
| `stage-proj-adopt` † | 把一个新的或已有的论文仓库接进 STAGE |
| `stage-evid-curator` | 导入、登记、映射证据 |
| `stage-stry-coach` † | 打磨故事；播下论断与 venue 档案 |
| `stage-outl-planner` † | 提纲、篇幅预算、章节骨架、记号表 |
| `stage-sect-drafter` | 每次调用起草一节 |
| `stage-tabs-builder` | 只从证据生成表格 |
| `stage-figs-designer` | 图的清单、源文件、渲染出的 PDF |
| `stage-refs-curator` | 参考文献、阅读笔记、定位 |
| `stage-copy-editor` | 润色文字；不碰含义，不碰数字 |
| `stage-clms-auditor` | 把每个数字追到一枚指纹 |
| `stage-cite-auditor` | 对着阅读笔记核验引用 |
| `stage-peer-reviewer` | 模拟的五视角评审小组 |
| `stage-resp-writer` † | 评审意见 → 要点台账 → 回复 + 承诺 |
| `stage-subm-packer` † | 预检、venue 版式转换、打包、冻结 |
| `stage-pstr-builder` † | 选内容、渲染并检查本周期的海报 |
| `stage-flow-status` | 只读的状态与唯一的下一步 |

1. **标 † 的六个是 slash-only。** 只有用户点名时才跑：它们是决策点——接入、故事、提纲、回复、投稿、以及什么能上墙——而一个由 agent 自作主张走到的决策点，等于没有人做过这个决策。这张表是事实来源；执行它的守卫是 Claude、Cursor、Kimi 清单里的 `disable-model-invocation: true`，以及 Codex 的 `.agents/skills/<name>/agents/openai.yaml` 里的 `allow_implicit_invocation: false`，CI 会拿这四处与这里的标记逐一比对，所以在这里标了却没在四处都加守卫会让构建失败。
2. **两个 skill 从不碰稿件。** `stage-peer-reviewer` 只写 `cycls/<cycle>/reviews/` 下的评审；`stage-flow-status` 什么都不写。只要不知道进展到哪了，先跑状态 skill——它读提纲、台账、清单与周期状态，给出唯一的下一步和它确切的命令。
3. **一次调用一个 skill，一个 skill 一件事。** 一节、一张表、一张图、一份回复——一次运行悄悄扩大范围正是这条规则针对的失败；下一件事是下一次调用。
4. **点名了下一步动作，若落在那十个上，就去跑，而不是打印出来。** skill 收尾时都会点名接下来该做什么——状态 skill 唯一的下一步、lint 红灯点名是谁的东西坏了、审计把一条没有出处的主张退回给承载它的那一节——今天这些一律是递给读者的一条命令。当被点名的命令属于那十个、且目标已经定死时，就把它跑起来，而不是打印它：读者就是 agent 自己，打印一条命令给自己，等于转交给了没有人。那六个仍旧打印命令，因为"由作者敲下去"本身就是它们存在的意义所在的那个决定。三条限制保证这件事是安全的。**拾起发生在点名的那次运行结束之后，绝不在运行内部**——一个不许碰稿件的 skill，不会因为点名了后继者就伸得更长，因此 `stage-flow-status` 仍旧只是那个汇报者，后继者要等报告写完才开始。**目标没定死就发问，而不是猜**——哪一节、哪张表、哪张图、哪个周期（§5 负责解析）。以及**第 3 条原样有效**，一次一个 skill、一件事，而没有人敲下的那次运行，开跑前先说明自己要启动什么。
