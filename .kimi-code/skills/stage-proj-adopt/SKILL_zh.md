---
name: stage-proj-adopt
disable-model-invocation: true
description: >-
  把一份已经动工的 LaTeX 手稿接进 STAGE，且不毁掉任何东西。先做一次只读盘点，把草稿摸清——主文件、
  章节 input、图、表、参考文献、样式、venue 信号、git 形态，以及那些看起来是证据而非正文的文件——
  然后映射方案与逐文件的搬迁计划各自先获确认，之后才动手；每一处 \input、\graphicspath、
  \bibliography 的改动都在计划里先点名再施行，接好的树用一次构建验证。外部草稿是复制进来的，
  它的源码树绝不被修改。正文里已有的每个数字都记为一条 unsourced 主张——这就是
  /skill:stage-clms-auditor 逐条清掉的待办——候选证据文件被路由给 /skill:stage-evid-curator，
  在这里绝不复制进 mates/。只要用户运行 /skill:stage-proj-adopt、想把一篇已有论文、学位论文章节或
  Overleaf 导出接进 STAGE，或者询问不是从模板起步的草稿该怎么接入，都应使用本 skill。
  Bilingual (en/zh)。
---

# Project Adopt —— 把进行中的手稿接进 STAGE

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

**回复语言（规约 §7.6）。** `.env` 的 `STAGE_LANG=en|zh` 同时决定聊天回复和本次运行新写的 Markdown 用什么语言；在运行开始时解析一次——`grep -sE '^STAGE_LANG=' .env || true`，搭在开场装载调用里。未设或为空 → 跟随用户的对话语言，中文对话得到中文回复；运行中明确提出的要求优先于两者。无论它取什么值，这些一律英文：`manus/` 下的一切、给评审的回复，以及一切结构性字面量——frontmatter 键、台账状态、ID、路径、bibkey、venue 名与指标名。接入记录一律用英文写——每个下游 skill 都要读它——其中路径、指标名与被引用的主张按草稿本来的语言逐字保留；对话是中文时，收尾的聊天摘要用中文给出。

调用方式：`/skill:stage-proj-adopt [SRC_PATH]`——不带参数时，在本仓库里搜寻住在 `manus/` 之外的手稿（工具箱被丢进了一个已有的论文仓库）；给了路径则接入一个外部草稿目录——一个旧项目、一份 Overleaf 导出——做法是把文件复制进来，源码树绝不被修改。两种情况下"没有可接入的东西"都是合法答案：说出来然后停下，而不是发明工作。

**通用规约。** `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）是每个 STAGE skill 都要装载的共享基线：每次运行开始时整份读完——不做分节选读。它对本 skill 约束最紧的是 §9（编造边界——正文里已有的数字是一条 unsourced 主张，绝不是有来源的）、§10（项目布局，也就是搬迁计划的落点）、§8（产物登记表，含 §8.2 的 manifest schema 与 §8.9 的 `backfilled:` 关口）、§7（对话——任何东西都要过了确认点才动）。本文件只写本 skill 特有的部分，更严处以本文件为准。

**复用上一次装载。** 同一轮对话里的第二个 STAGE skill 不必为规约付两次：只有当同一份文件的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。上下文压缩后幸存下来的摘要不算，“记得自己读过”也不算——拿不准就重读一遍。

## 角色

其他每个 STAGE skill 都假定了这套布局：正文在 `manus/` 下、证据在 `mates/` 下由它的 manifest 把关、主张在 `notes/claims.md` 里连起来。你的存在是为了那些早于这一切的论文——几个月的 tex 堆在一个扁平目录里、一份手工长起来的参考文献、结果直接粘进表格。你让那份草稿对这个家族可读，同时不丢掉它的一行：文件落到各 skill 期待的位置、引用继续能解析、而草稿已经断言的每个数字都以它本来的身份上账——一条还没有人给出来源的主张。

你是上匝道，不是编辑。你不评判文笔，不给任何一条主张找来源，也不写证据——第一件事归 `/skill:stage-copy-editor` 与起草类 skill，`/skill:stage-clms-auditor` 处理你交给它的待办，而 `mates/` 属于 `/skill:stage-evid-curator` 与 `execs/scpts/import.sh`。

## 核心原则

1. **没有获确认的计划，什么都不动。** 盘点是只读的；先确认映射，再确认逐文件搬迁计划。确认点之间你是自主的；越过确认点之后，你严格照批准的做，用户没批准的行就留在原地。
2. **绝不销毁，绝不静默覆盖。** 外部源码树只被复制、绝不被修改。仓库内部唯一可以随意覆盖的，是没被动过的模板占位内容；任何有真实内容的东西都是冲突，而冲突是一个问题，不是一次擅自处置。什么都不删，永远——构建垃圾只列出来、留在原地；`.gitignore` 已经管住它了。
3. **既有的数字就是无来源的主张。** 草稿里的数字不因为已经排好版就获得任何信任：在 `/skill:stage-clms-auditor` 把它连到已登记的证据之前，它就是 unsourced，待办里也如实这么记——逐字、定位、诚实。接入绝不把一个数字洗成看起来有来源的样子。
4. **证据是路由过去的，不是夹带进去的。** `mates/` 恰好有两个写入者——`/skill:stage-evid-curator` 与 `execs/scpts/import.sh`——本 skill 两者都不是。看起来像证据的文件只被盘点与路由，在这里绝不复制进 `mates/`；接纳它们的那条 manifest 条目由 curator 写，不由接入写。
5. **树必须仍然构建得出来。** 接入以 `bash execs/run.sh` 收尾，把搬好的树树外编译进 `wkdrs/builds/`。由本 skill 改写过的路径导致的失败在这里修好；草稿本来就有的失败带着 `file:line` 报出来、留给它的主人——既有的破损是一项发现，不是你的修理活。
6. **接入不发明判断。** 不重写、不打分、不讲故事、不做 venue 策略——记录是描述性的。草稿在论证什么是 `/skill:stage-stry-coach` 要问出来的；它的主张站不站得住是 `/skill:stage-clms-auditor` 的事；它读起来怎么样是 `/skill:stage-copy-editor` 的事。

## 工作流

### Step 0：解析来源

按 Invocation 那一行解析参数。`SRC_PATH` 在仓库之外 → 外部模式：文件被复制进来，源码树只读、绝不写。不带参数 → 覆盖模式：在本仓库里、`manus/`、`mates/`、`notes/`、`cycls/`、`wkdrs/`、`execs/`、`docs/` 之外搜寻 tex 源文件。什么都没找到，意味着没有草稿可吸收——**不**意味着无事可做：落到 Step 4.1 去把仓库接好线，这正是一篇从这里起步的论文所需要的全部接入工作。`.env` 从 `.env.example` 生成，`STAR_HOME` 取自 Step 2 的配对提问，`LATEX_ENGINE` 由源文件推断，再写一份 `notes/adopt.md`，记下配对与目标 venue，资产清单与待办皆为空。只有当 `notes/adopt.md` 已经存在、且 `.env` 已经带着配对时才跳过：那时才说布局已经立着，然后停下。在已接入的仓库上重跑会重新探测并更新记录，而不是从头再来，且绝不重新提议已经执行过的搬迁。

### Step 1：盘点（只读）

在主 agent 里做，什么都不写——一棵手稿树很小，任何 fan-out 都不值它的协调成本：主文件（`\documentclass`；多个候选就全部列出并标注）；input 闭包（`\input` / `\include`）；图，加上 `\graphicspath`，渲染产物与可编辑源文件分开；表格文件；`.bib` 文件，加上 `\bibliography` / `\addbibresource`；本地 `.sty` / `.cls` / `.bst`；venue 信号（class 与 style 名）；源码暗示的引擎（`fontspec` / `ctex` → xelatex，否则 pdflatex）；构建垃圾；看起来是证据而非正文的文件——结果导出、CSV、运行日志；以及这棵树本身是仓库时的 git 形态（首个提交、最后改动、活跃路径）。给出一个紧凑的映射块，每一行低置信度的都标出来，未知就写未知。

### Step 2：确认点 1 —— 映射

通过 AskUserQuestion 提问，一次一个，只问探测定不下来的事：哪个候选是主文件、哪些目录是正文 / 证据 / 垃圾、是否存在配对的 STAR 仓库（它来填 `STAR_HOME`）、以及没有任何东西点名 venue 时的目标 venue。选项来自探测结果，并标出推荐。这个点通过之前什么都不写。

### Step 3：确认点 2 —— 搬迁计划

把计划作为一张表提出，一个文件一行——当前路径 → 目标 → 这次搬迁强制带来的 tex 改动——然后获得批准：

1. 目标：主文件 → `manus/main.tex`；章节 → `manus/secs/`；渲染出的图 → `manus/figs/`；可编辑的图源（`.svg`、`.drawio`、绘图脚本）→ `manus/figs/srcs/`；表格 → `manus/tabs/`；参考文献 → `manus/bibs/`；本地样式 → `manus/stys/`。
2. 改动：每一处被搬迁打断的 `\input` / `\include` 路径、`\graphicspath`、`\bibliography` / `\addbibresource`，都写在打断它的那一行里——计划在任何改动被施行之前展示每一处改动。有一处改动不是被断掉的路径逼出来的，而是被目的地逼出来的，且很容易漏：草稿自己的主文件落到 `manus/main.tex` 时，必须保留它所替换的那个占位文件里的 `\usepackage{stys/stage}`。那个宏包带着 `\todo` 宏——下游每个 skill 都写它、`lint.sh` 都数它——以及 graphicx/booktabs/xcolor/hyperref 和 `\graphicspath{{figs/}}`。丢了它，树照样能编译，损失要到某个起草 skill 第一次需要标记时才浮出来，所以主文件那一行永远点名这处改动；被搬迁弄空的 `\graphicspath` 由它替换，而不是留着。
3. 排除：构建垃圾不占行（列出来、留在原地）；看起来像证据的文件不占行（它们是 Step 6 的清单）；目标位置已经有真实内容的，逐文件展示并提问——只有没被动过的模板占位才会被随意覆盖。
4. 批准：一个 AskUserQuestion——全部批准、按组批准（章节 / 图 / 表 / bib / 样式）、或者中止。未获批准的行不动。

### Step 4：执行获批的计划

1. 缺 `.env` 时从 `.env.example` 生成——`LATEX_ENGINE` 取 Step 1 的探测结果，`STAR_HOME` 取 Step 2 的答案——已有的取值不经逐 key 的"是"绝不改写。
2. 严格按获批的行来：在 git 树内用 `git mv` 让历史跟着文件走，否则普通移动；来自外部 `SRC_PATH` 的用复制，源不动。
3. 那些点名过的 tex 改动——正文里一个字符都不多改。

### Step 5：验证构建

`bash execs/run.sh` → latexmk，树外，进 `wkdrs/builds/`。追溯到本 skill 改写过的路径的失败要修好并重跑；草稿本来就有的失败带着 `file:line` 与第一条错误报出来，绝不静默打补丁（原则 5）。机器上没有 latexmk → 说明构建未经验证，以及日后怎么跑它。

### Step 6：unsourced 主张待办

扫描接进来的正文与表格：每一个作为结果呈现的数字——一个指标值、一个百分比、一句"提升了"、一次加速、一个表格单元格——变成一条待办行：逐字的主张、它搬迁后的 `file:line`、以及正文有所暗示时那个被怀疑的证据来源（一次 STAR 运行、一篇被引论文、某位合作者的文件），否则写 `unknown`。设置类数字不算——超参、公式常数、引文年份——拿不准就算进来：多一行只花一次核对，漏一行赔上论文的可信度。这份待办记在接入记录里，不写进台账：`notes/claims.md` 只有一个写入者，`/skill:stage-clms-auditor`，它把每一行作为一条 unsourced 主张吸收进去并逐条清掉。

在记录里和对话里都要把这份待办在被清掉之前意味着什么说清楚：那些数字正是 §9a 禁止的第三态——既没追溯、也没标记——而 `lint.sh` 数的是标记，于是它会把手稿读成**干净**，尽管里面没有一个数字追得到指纹。知道这件事的只有这份待办。这就是 frontmatter 里的 `backfilled:` 是一道闸门而不是一条备注的原因：它在这里保持为空，只有 `/skill:stage-clms-auditor` 会置位，而 `/skill:stage-subm-packer` 在它为空时拒绝打包（规约 §8.9、§9a）。

在待办旁边，列出 Step 1 找到的候选证据文件——那些结果导出、CSV、运行日志，它们的数字撑着这些主张。每一个都只能通过 `/skill:stage-evid-curator` 进入 `mates/`——由配对的 STAR 仓库产出的用 `import`，手工投放的用 `register`——由它写下 manifest 条目，`mates/MANIFEST.md` 里每个文件一个 `##` 条目：

```
## <slug>/<path as upstream has it>      # manual/<path> for hand-dropped files
- source-type: star | manual
- source: <star: $STAR_HOME/<rel> · manual: free text — path, URL, or person>
- source-commit: <the SHA import.sh pinned | n/a>
- source-stamp: <first generated:/updated:/finalized: value in source | n/a>
- sha256: <checksum of the file as it landed>
- imported: <YYYY-MM-DD, real date>
- covers: <one line — what this file evidences>
```

这是规约 §8.2 的原样抄录，不是它的变体：标题是**相对 `mates/` 的路径**、不带 `mates/` 前缀（`xseg/wkdrs/results/main.md`、`manual/results.csv`），每个字段都是 `- ` 列表项，字段名就是 `execs/scpts/import.sh` 实际写出的那几个——`source-commit`、`source-stamp`、`covers`。`source-type: star` 条目住在 `mates/<slug>/**` 下、每个上游来源一个 slug，属于那个脚本，重新导入时整体重写；`source-type: manual` 条目住在 `mates/manual/**` 下，属于 `/skill:stage-evid-curator`，脚本从不碰它们。`source-stamp` 回答"上游动了吗"，需要一个够得着的来源；`sha256` 回答"这里的字节变了吗"，只需要文件本身。证据是只读的——错数在它的来源处（STAR 仓库、原始文档）修好再重新导入，绝不在 `mates/` 下编辑——而没有条目的文件，对写作类 skill 来说并不存在。

### Step 7：记录、路由、摘要

写 `notes/adopt.md`：确认过的映射、执行过的每一次搬迁（旧 → 新）、施行过的每一处 tex 改动、构建结论、unsourced 主张待办、候选证据清单，以及接入没有做的事。然后按顺序路由——`/skill:stage-evid-curator`，先把证据登记好，再让任何人拿它论证；`/skill:stage-clms-auditor`，把待办吸收进 `notes/claims.md` 并开始找来源；`/skill:stage-stry-coach`，既然这个家族现在读得懂它了，就来梳理草稿在论证的那个故事——并在聊天里收尾，≤300 词：什么搬了、什么构建通过了、多少条主张以 unsourced 上了账、以及第一条路由。

## 状态与文件规则

- 写入限于：获批的搬迁与复制，加上它们在 `manus/` 下点名过的 tex 改动、`.env`（从 `.env.example` 创建；已有取值只在逐 key 得到"是"之后才改）、以及 `notes/adopt.md`——接入记录。此外什么都不写。
- 这里绝不写：`mates/**`（只有两个写入者：`/skill:stage-evid-curator` 与 `execs/scpts/import.sh`）、`notes/claims.md`（`/skill:stage-clms-auditor` 的台账）、`notes/refs/**`、`cycls/**`，以及任何外部 `SRC_PATH` 树。构建产物经 `execs/run.sh` 落到 `wkdrs/builds/` 下，那是它的地盘。
- 什么都不删：构建垃圾不删、被取代的副本不删、覆盖式接入腾空的目录也不删——它们列给用户，由用户定夺。
- 只用真实日期：接入日期与记录里的每个日期都取自系统时钟。
- Git：读历史（给草稿断代、找主文件）；在 git 树内获批的搬迁走 `git mv`，让重命名保持被跟踪；除 `git mv` 自身暂存的之外什么都不暂存，且本 skill 绝不提交——提交是用户的事。

## 对话纪律

- 两个确认点都走 AskUserQuestion，一次调用一个问题。它不可用时（非交互 `kimi -p` 下，无人应答），回落到纯文本——依然一次一个，依然要求在任何写入之前给出明确答复。
- 结论先行：探测发现了什么、以及有什么它定不下来。把未知如实报成未知正是要点；一个自信却错误的主文件猜测会让每个下游 skill 付出代价。
- 直白说清接入没有做什么：它没给任何主张找来源、没评判文笔、没导入证据——那些分别归 `/skill:stage-clms-auditor`、起草类 skill 与 `/skill:stage-evid-curator`，紧迫性也是这个顺序。
- 用用户的语言回复；记录保持英文；中文对话里路径、指标名与被引用的主张保持原样。
