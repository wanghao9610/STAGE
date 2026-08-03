<div align="center">
  <img src="docs/srcs/stage-project-icon.png" alt="STAGE 项目图标" width="128">
  <h1>STAGE</h1>
  <p><strong>Systematic Toolchain for Authoring, Guiding, and Editing</strong></p>
  <p><em>STAR 的学术写作伴侣 —— every STAR needs a STAGE。</em></p>
  <p><a href="https://wanghao9610.github.io/STAGE/"><strong>文档站点</strong></a></p>
</div>

**语言：** [English](README.md) | 简体中文

STAGE 把一个研究项目变成一篇提交的论文，并保证全程证据链不断。它把稿件、导入的实验证据、写作元数据和投稿周期分别放在约定好的目录中，给研究者和 AI 写作助手同一个构建入口、同一份共享规范，并提供一条完整的写作工作流——证据导入、故事、提纲、起草、图表制作、审计、模拟评审、回复、投稿打包。稿件中的每一个数字要么可追溯到一份带指纹的证据文件，要么被显式标记为缺失；每一条论断（claim）都在同一本台账中从提出一路跟踪到验证。

STAGE 是 [STAR](https://github.com/wanghao9610/STAR)（*Systematic Toolchain for AI Research*，系统化 AI 研究工具链）在写作侧的伴侣仓库：STAR 负责推进研究、产出方法文档、实验结果和阶段小结；STAGE 把它们快照为只读证据，在其上写出论文。配对是可选的——STAGE 也可以完全独立使用，证据由人工登记。

STAGE 采用双层模型：本仓库是**模板**；一篇论文 = 一个**实例**，通过克隆模板创建，或用 `execs/update.sh --adopt` 把骨架装进一个已有的论文仓库。实例之后可以通过 `update.sh` 从上游同步 STAGE 管理的 skill 和工作流文档，而不会碰你的稿件。

## 目录

- [目录](#目录)
- [STAGE 提供什么](#stage-提供什么)
- [项目结构](#项目结构)
- [论文模板](#论文模板)
- [快速开始](#快速开始)
  - [1. 创建论文仓库](#1-创建论文仓库)
  - [1b. 或者：接入一个已有的论文仓库](#1b-或者接入一个已有的论文仓库)
  - [2. 配置 `.env`](#2-配置-env)
  - [3. 路径 A：与 STAR 仓库配对](#3-路径-a与-star-仓库配对)
  - [4. 路径 B：独立使用](#4-路径-b独立使用)
  - [5. 构建与检查](#5-构建与检查)
  - [6. 启动写作工作流](#6-启动写作工作流)
- [写作工作流](#写作工作流)
- [通往投稿的十步路径](#通往投稿的十步路径)
- [证据、指纹与论断台账](#证据指纹与论断台账)
- [更新 STAGE 的 skill 与工作流文档](#更新-stage-的-skill-与工作流文档)
- [路线图](#路线图)
- [引用](#引用)
- [许可证](#许可证)

## STAGE 提供什么

- **统一的稿件结构**：章节、图（含源文件）、表、参考文献、venue 样式，各归其位，都在 `manus/` 下。
- **只读的证据层**：STAR 产物（或人工登记的文件）被快照进 `mates/`，每个文件带一枚指纹，记录在 `mates/MANIFEST.md`。证据单向流动——要改一个数字，去上游改好再重新导入；绝不直接编辑 `mates/`。
- **作为枢纽的论断台账**：`notes/claims.md` 把每条论断的陈述位置 ⇄ 证据 ⇄ 状态连在一起。写作提出论断，审计验证论断，回复捍卫论断。
- **统一的构建入口**：`execs/run.sh` 用 latexmk 把 `manus/main.tex` 编译到树外的 `wkdrs/builds/`，并打印 PDF 路径和页数。
- **确定性检查放在脚本里，判断放在 skill 里**：`execs/scpts/lint.sh` 机械地抓未定义引用、`\todo` 标记、超页和匿名泄漏；十五个 skill 处理一切需要判断的事。
- **完整的写作生命周期**：十五个相互配合的 skill，按运行顺序依次是——接线仓库、整理证据、打磨故事、规划提纲、逐节起草、由证据生成表格、设计图、维护参考文献、润色文字、审计每个数字、审计每条引用、模拟评审、撰写回复、打包投稿、汇报状态。
- **投稿周期即数据**：每次投稿尝试都住在 `cycls/<venue>_<year>/` 里：经用户确认的 `venue.yml` 档案、真实与模拟评审、回复，以及冻结的投稿记录。
- **一套工作流，四份 agent 目录**：同样的十五个 skill 分别供 Claude Code（`.claude/skills/`）、Codex（`.agents/skills/`）、Cursor（`.cursor/skills/`）和 Kimi Code（`.kimi-code/skills/`）使用，彼此只差调用前缀与工具名；外加一份共享的 `AGENTS.md`，其正文被镜像进 `.cursor/rules/`，成为 Cursor 的常驻规则。
- **供人阅读的中文镜像**：每个 `SKILL.md` 旁边一份 `SKILL_zh.md`、peer-reviewer 的 references 旁边一份 `*_zh.md`、规范与 skills 指南旁边一份 `*.zh-CN.md`——与英文版同步维护，运行时不装载，英文版始终是权威版本。

每个 skill 做什么、如何调用，见[写作工作流](#写作工作流)；逐 skill 的说明和流水线图，见[写作工作流 Skills 指南](docs/mds/stage-workflow/writing-workflow-skills.md)；所有 skill 共享的规则在[写作工作流规范](docs/mds/stage-workflow/writing-workflow-conventions.md)中。

## 项目结构

```text
STAGE/
├── manus/                  # 稿件
│   ├── main.tex            # 入口文件；开箱即可独立编译
│   ├── secs/               # 章节源文件：<n>_<slug>.tex（0_abstract.tex、1_intro.tex …）
│   ├── figs/               # 渲染好的图（PDF）；figs/srcs/ 存放每张图的源文件
│   ├── tabs/               # 表格，由证据生成
│   ├── bibs/               # reference.bib
│   └── stys/               # arxiv.cls（版式）+ stage.sty（\todo 与写作宏）
├── mates/                  # 导入的证据——只读
│   ├── <source-slug>/      # 按上游 STAR 路径镜像的快照
│   ├── manual/             # 人工登记的证据文件
│   └── MANIFEST.md         # 指纹台账：每个证据文件一条记录
├── notes/                  # 写作元数据
│   ├── story.md            # 另有：claims.md、outline.md、notation.md、adopt.md
│   └── refs/               # 逐篇阅读笔记 + refs_index.md
├── cycls/                  # 投稿周期
│   └── <venue>_<year>/     # venue.yml、reviews/、response/、SUBMISSION_<date>.md
├── tasks/                  # 修改暂存与承诺清单
├── wkdrs/                  # 构建产物与临时报告（gitignore，可再生）
├── execs/
│   ├── run.sh              # 构建入口（latexmk，树外构建）
│   ├── update.sh           # 同步上游 STAGE skill 与文档；--adopt 安装骨架
│   └── scpts/              # import.sh（证据导入）、lint.sh（确定性检查）
├── docs/                   # 项目文档
│   ├── index.html          # GitHub Pages 文档入口（→ htmls/stage.html）
│   ├── htmls/              # 落地页：stage.html + stage_zh.html
│   ├── mds/stage-workflow/ # 规范 + skills 指南（由上游管理）
│   └── srcs/               # 文档图片及其他静态资源
├── .claude/skills/         # Claude Code 使用的写作工作流 skill
├── .agents/skills/         # Codex 使用的写作工作流 skill（各带一份 agents/openai.yaml）
├── .cursor/
│   ├── skills/             # Cursor 使用的写作工作流 skill
│   └── rules/              # 常驻规则：AGENTS.md 正文 + skill 目录归属
├── .kimi-code/skills/      # Kimi Code 使用的写作工作流 skill
├── .cursorignore           # 把构建产物与 LaTeX 垃圾挡在 Cursor 索引之外
├── .env.example            # 本地配置示例
├── AGENTS.md               # AI 写作助手共享的协作规范
├── CLAUDE.md               # 指向 AGENTS.md 的符号链接，供 Claude Code 加载同一份规范
└── README.md
```

目录名的缩写沿用 STAR 的惯例：

| 目录 | 英文含义 | 存放内容 |
| --- | --- | --- |
| `manus/` | Manuscripts | 论文的 LaTeX 源文件 |
| `secs/` | Sections | 每个章节一个 `.tex` 文件 |
| `figs/` | Figures | 渲染好的 PDF；`srcs/` 存放可编辑的源文件 |
| `tabs/` | Tables | 表格 `.tex` 文件，由证据生成 |
| `bibs/` | Bibliographies | `reference.bib` |
| `stys/` | Styles | `arxiv.cls`、`stage.sty`，以及 venue 的 class/style 文件 |
| `mates/` | Materials | 导入的证据快照——只读 |
| `cycls/` | Cycles | 每次投稿尝试一个目录 |
| `execs/` | Executions | 入口脚本；工具脚本放在 `scpts/` |
| `wkdrs/` | Work directories | 构建产物与临时报告，永不提交 |
| `mds/` | Markdowns | 按主题分组的 Markdown 文档 |
| `srcs/` | Static sources | 文档引用的图片及其他静态资源 |

三条目录树本身写不下的规则：`mates/` 只读（只有 `import.sh` 和 `/stage-evid-curator` 可以写入，且只做带指纹的整文件新增或替换）；`wkdrs/` 永不提交（可留存的审计结论以 `notes/claims.md` 的状态翻转和 `tasks/` 条目落盘，而不是报告文件）；`execs/` 根目录封闭（只有 `run.sh` + `update.sh`——工具脚本一律放 `execs/scpts/`）。

## 论文模板

`manus/` 自带一套紧凑的 arXiv 风格预印本模板，拆成两层，因为换 venue 模板时，一层必须被替换，另一层必须活下来：

| 分层 | 文件 | 负责 | 换 venue 模板时 |
| --- | --- | --- | --- |
| 版式层 | `manus/stys/arxiv.cls` | 页面尺寸、字体、标题面板、标题层级、图表标题、浮动体、参考文献样式 | **被替换**——把 venue 的 class 放进 `manus/stys/`，改一行：`\documentclass{stys/cvpr}` |
| 写作层 | `manus/stys/stage.sty` | `\todo{...}`，以及写作 skill 会写进 `secs/`、`tabs/` 的那些宏 | **保留**——不论 class 换成什么，`\usepackage{stys/stage}` 这一行都留着 |

扩展这两个文件时请守住这条分界：章节或表格文件里会出现的东西放进 package，只有页面外观需要的东西放进 class。项目自己的宏（`\newcommand{\method}{...}`）写在 `main.tex` 里，不要写进 `stys/`——模板文件会被替换或更新。

**class 选项**——`\documentclass[twocolumn]{stys/arxiv}`：`onecolumn` | `twocolumn`，外加 `anon`，以及 `article` 支持的其他选项。导言区中，`\paperstyle{fancy|simple}` 选择带框或平铺的标题面板，`\papercolor{green|blue|black}` 选择配色。

**标题面板**——在导言区收集，由 `\maketitle` 一次排版：

| 命令 | 说明 |
| --- | --- |
| `\title{...}` | 过长的标题会自动降一号字，而不是把整个面板往下挤 |
| `\author[1,\ast]{Name}` | 可重复，按顺序；可选参数对应上标 |
| `\affiliation[1]{...}`、`\contribution[\ast]{...}` | 可重复 |
| `\abstract{...}` | 是**命令而非环境**——所以 `secs/0_abstract.tex` 在导言区 `\input`，不在正文里 |
| `\keywords{...}` | 排在摘要下方 |
| `\code{}` `\project{}` `\dataset{}` `\demo{}` `\correspondence{}` `\paperdate{}` | 链接行；`\metadata[label]{value}` 可自定义任意一条 |

**写作宏**来自 `stage.sty`，在任何 class 下都可用：`\todo{...}`（`lint.sh` 统计的未溯源标记）、`\parahead{...}` 与 `\headbf{...}`、`\cmark` / `\xmark`、`\tablestyle{sep}{stretch}`、定宽列 `x{}` `y{}` `z{}` `P{}` 与 `tabularx` 的 `Y` 列、`Light*` 行底色，以及 `\figref` `\tabref` `\eqnref` `\algref`——让每类浮动体在全文只有一种写法。

**匿名有两半，两半都要。** class 的 `anon` 选项负责 PDF 那一半：面板只印 "Anonymous Authors"，并隐去单位、贡献说明和链接行。`.env` 里的 `ANON=true` 负责源文件那一半：`lint.sh` 会对 `manus/` 下任何身份信息报错——包括注释，因为上传源码时注释会一起交上去。仓库自带的 `main.tex` 连占位符都是匿名的，所以新仓库第一天就能通过源文件这一半。

**环境要求**——较完整的 TeX Live（2022+）：class 使用 `tcolorbox`、`titlesec`、`cleveref`、`natbib`、`nicematrix`、`siunitx`。`fontawesome5` 可选，缺失时链接行退回纯文字标签。

## 快速开始

### 1. 创建论文仓库

把本仓库用作 GitHub 模板，或直接克隆/复制——一篇论文，一个仓库：

```bash
git clone https://github.com/wanghao9610/STAGE
cd STAGE
rm -rf .git
cd ..
mv STAGE YOUR_PAPER_NAME
cd YOUR_PAPER_NAME
git init
git add .
git commit -m "First commit."
```

### 1b. 或者：接入一个已有的论文仓库

如果草稿已经开工——一棵 tex 目录树、几个月的提交、正文里已经写着数字——就把骨架装进去，而不是把它搬进 STAGE。在那个仓库的根目录运行：

```bash
curl -fsSL https://raw.githubusercontent.com/wanghao9610/STAGE/main/execs/update.sh -o /tmp/stage-update.sh
bash /tmp/stage-update.sh --adopt
```

已有的内容一律不覆盖：接入只复制缺失的文件，然后引导你运行 `/stage-proj-adopt`。它会询问配对的 STAR 仓库和目标 venue，盘点已有文件，提出映射进标准布局的方案（动任何东西之前都先确认），并把这一切记进 `notes/adopt.md`。草稿里已有的数字会成为 `unsourced`（无出处）论断——它们是审计的待办清单，而不是无声的欠账。

### 2. 配置 `.env`

```bash
cp .env.example .env
```

```dotenv
# 配对的 STAR 项目仓库（可选——独立写作时留空）
STAR_HOME=
# 构建引擎：pdflatex | xelatex | lualatex
LATEX_ENGINE=pdflatex
# 投稿匿名模式：为 true 时 lint.sh 排查身份泄漏
ANON=false
# execs/update.sh 使用的上游 STAGE 仓库
STAGE_REPOSITORY=https://github.com/wanghao9610/STAGE.git
# 可选。回复与文档语言：en | zh；留空 = 跟随对话
STAGE_LANG=
```

`STAR_HOME` 决定你走哪条快速开始路径。本地 `.env` 已被 Git 忽略。

`STAGE_LANG`（可选，`en` | `zh`）决定聊天回复以及工作流所写 Markdown 的语言——`notes/`、`tasks/`、模拟评审、`wkdrs/` 报告。留空则一切跟随对话本身的语言。无论它取什么值，有两样东西始终是英文，因为读它们的是仓库之外的人：`manus/` 下的手稿，以及给评审的回复。任何语言的文档里，结构性字面量同样保持英文——frontmatter 键、台账状态、ID、路径、bibkey、venue 名与指标名——这正是中文笔记仍然可被机器读取的原因。完整规则见[规约 §7.6](docs/mds/stage-workflow/writing-workflow-conventions.zh-CN.md)。

### 3. 路径 A：与 STAR 仓库配对

把 `STAR_HOME` 指向你的 STAR 项目，然后导入：

```bash
bash execs/scpts/import.sh
```

导入会把 STAR 中与写作相关的产物——方法文档（`metds/overview.md`、`framework.md`、`dataset.md`、`training.md`、`evaluation.md`，加上 `adopt.md` 和 `codearc.md`）、选题陈述、参考文献笔记与 `reference.bib`、结果表、实验小结——按相同的相对路径快照进 `mates/<slug>/`，并在 `mates/MANIFEST.md` 里为每个文件记录来源、来源 commit 和内容指纹。当稿件还没有参考文献库时，STAR 的 `reference.bib` 会被播种到 `manus/bibs/`。新实验落地后重新运行即可；先用下面的命令检查漂移：

```bash
bash execs/scpts/import.sh --diff   # 只读的过期检查报告；任何漂移都以退出码 1 结束
```

多个 STAR 仓库可以喂同一篇论文：`import.sh --source PATH --slug NAME` 可以用独立的 slug 导入任何一个符合 STAR 布局的本地检出。

### 4. 路径 B：独立使用

让 `STAR_HOME` 保持为空。把证据文件——结果导出、合作者发来的数字、一份 wandb CSV——放到 `mates/manual/` 下的任意位置，然后运行 `/stage-evid-curator`，把每个文件登记进 `mates/MANIFEST.md`，登记为 `manual` 条目，来源用自由文本写明（如 "results emailed by X, 2026-08-01"）。它还会规整杂乱的文件（一份 CSV 会在旁边生成一份结果格式的 `.md`，标注 `normalized-from:`），并提出论断⇄证据的映射建议。下游的一切——起草、表格、审计——完全相同：登记过的手工文件和导入的 STAR 文件同样可以被引用，而未登记的文件对写作 skill 来说等于不存在。

### 5. 构建与检查

```bash
bash execs/run.sh          # latexmk 树外构建 → wkdrs/builds/ + PDF 路径和页数
bash execs/scpts/lint.sh   # 未定义引用、\todo 计数、页数上限、匿名泄漏
```

新检出的仓库用普通 pdflatex 开箱即可编译，而且自带的稿件里故意留了一个 `\todo{}`——第一次运行 lint 就能直观看到这道闸门，日后它拦住的就是你真正缺失的数字。`lint.sh` 在以下情况硬性失败：未定义引用、超出页数上限、残留 `\todo` 标记、以及（`ANON=true` 时）身份泄漏；其余都是警告。

### 6. 启动写作工作流

骨架本身就能独立使用——目录布局、`.env`、`run.sh`、`import.sh` 不装任何 skill 也有用。要接上工作流，从下面最符合你现状的一行开始：

| 你的现状 | 从这里开始 |
| --- | --- |
| 新仓库，证据刚导入 | `/stage-stry-coach` |
| 用步骤 1b 接入的已有草稿 | `/stage-proj-adopt` |
| 故事已定稿，可以搭骨架 | `/stage-outl-planner` |
| 回到一篇写作中的论文 | `/stage-flow-status` |

`/stage-flow-status` 是最值得记住的一个：它读取盘上的提纲、台账、manifest 和周期状态，给出唯一的下一步行动及其准确命令，你永远不必回忆上次写到哪里。

## 写作工作流

STAGE 包含十五个相互配合的 skill，把导入的证据和一个故事变成一篇论断链可审计的投稿论文。

**如何调用。** 前缀因工具而异：

| 工具 | 调用方式 | 示例 |
| --- | --- | --- |
| Claude Code | `/stage-<name>` | `/stage-sect-drafter 1_intro` |
| Codex | `$stage-<name>` | `$stage-sect-drafter 1_intro` |
| Cursor | `/stage-<name>` | `/stage-sect-drafter 1_intro` |
| Kimi Code | `/skill:stage-<name>` | `/skill:stage-sect-drafter 1_intro` |

五个 skill（下表以 † 标注）仅限显式调用（slash-only）：只有你点名它们才会运行，agent 绝不会自作主张启动它们。它们是对话密集的决策点——接入、故事、提纲、回复、投稿——不请自来的一次运行会替你做本该由你做的决定。每套 harness 各按自己的方式强制这一条——Claude、Cursor、Kimi 三份 manifest 里的 `disable-model-invocation: true`，Codex 的 `agents/openai.yaml` 里的 `allow_implicit_invocation: false`——四者在 CI 里都要对着这张表核对，所以不会出现"三套挡住了、第四套敞着"的情况。

<div align="center">
  <img src="docs/srcs/stage-writing-workflow.png" alt="STAGE 写作工作流：十五个 skill 分成五条相位带——建仓、规划、写作、润色与审计、投稿周期——各自写出什么，以及起草循环与拒稿回流如何闭合" width="100%">
</div>

| Skill | 用途 | 主要产出 |
| --- | --- | --- |
| `stage-proj-adopt` † | 把新的或已有的论文仓库接进 STAGE：把配对 STAR 仓库写进 `.env`、确定目标 venue、盘点并映射已有 tex 树，把草稿里已有的数字转为 `unsourced` 论断进入审计待办 | `notes/adopt.md` |
| `stage-evid-curator` | 证据接收与映射：运行 `import.sh`、登记 `mates/manual/` 下的手工文件、规整杂乱导出、提出论断⇄证据映射、暴露过期——绝不就地修改证据 | `mates/` 及 `mates/MANIFEST.md` 条目 |
| `stage-stry-coach` † | 对话优先的故事打磨：pitch、问题、核心想法、带论断编号的贡献列表、venue 理由；播种论断台账和经用户确认的 venue 档案 | `notes/story.md`、播种的 `notes/claims.md`、`cycls/<cycle>/venue.yml` |
| `stage-outl-planner` † | 故事 → 骨架：页数预算合计不超 venue 上限的章节表、图和表的计划、论断→章节分配、骨架 `.tex` 文件、记号表种子 | `notes/outline.md`、`manus/secs/*.tex` 骨架、`notes/notation.md` |
| `stage-sect-drafter` | 每次调用起草或修改一个章节，依据章节简报、映射的证据、论断和记号规范；没有指纹的数字一律写成 `\todo{}` | `manus/secs/<n>_<slug>.tex` |
| `stage-tabs-builder` | 只从 `mates/` 证据生成表格——booktabs 风格，每个数据行一条 `% src:` 指纹注释，缺数据的格写 `\todo`。手敲数字正是这个 skill 要杀死的失败模式 | `manus/tabs/<slug>.tex` |
| `stage-figs-designer` | 负责图清单和每张图的端到端：用途、`figs/srcs/` 下的可编辑源文件、渲染的 PDF；首图（teaser）有专属检查单 | `manus/figs/<slug>.pdf` + 源文件 |
| `stage-refs-curator` | 文献库卫生、新读论文的笔记录入、相关工作定位；存在导入的 STAR 参考文献时以其为种子 | `manus/bibs/reference.bib`、`notes/refs/` |
| `stage-copy-editor` | 对一个章节或全稿做润色：清晰、流畅、记号一致、按预算删减——绝不改技术含义和任何数字 | `wkdrs/reports/POLISH_<date>.md` |
| `stage-clms-auditor` | 机械化的心脏：提取稿件里的每一个数字，逐一追溯到带指纹的证据条目，逐数判定 matched / mismatched / unsourced，翻转台账状态，检查证据过期 | `wkdrs/reports/CLAIMS_<date>.md` + `tasks/` 条目 |
| `stage-cite-auditor` | 每个 `\cite` key 都能解析；关于被引论文的每个断言都能对上一份阅读笔记——对不上的断言被标记，绝不悄悄改掉 | `wkdrs/reports/CITES_<date>.md` |
| `stage-peer-reviewer` | 模拟程序委员会：五视角评审团（新颖性与相关工作、技术正确性、实验严谨性、清晰度、魔鬼代言人），引用只认 whitelist/verified，按锚定评分带 + 封顶规则打分；`quick` 为单遍精简模式；绝不修改稿件 | `cycls/<cycle>/reviews/SIM_REVIEW_<date>.md` |
| `stage-resp-writer` † | 把真实与模拟评审解析成逐点台账，把每个攻击映射到论断和证据，在 venue 限制内起草回复，把每个承诺的修改记为复选框 | `cycls/<cycle>/response/RESPONSE_<date>.md`、`tasks/<cycle>_promises.md` |
| `stage-subm-packer` † | 投稿前检查与打包：build + lint 必须通过、走查检查单、完整性扫描、camera/补充材料/arXiv 包、投稿记录、冻结标签——camera-ready 模式在承诺未清空前拒绝打包 | `cycls/<cycle>/SUBMISSION_<date>.md`、标签 `freeze/<cycle>_<date>` |
| `stage-flow-status` | 全流程的只读地图：章节/图/表状态、按状态统计的论断覆盖、证据新鲜度、周期状态、最近一次构建——以及唯一的下一步行动和它的准确命令 | 聊天内报告；从不写文件 |

## 通往投稿的十步路径

这些 skill 串成一条从证据到冻结投稿的路径。第 5–7 步逐章节循环；第 8 步成本低，可随时重复；`/stage-flow-status` 在任何时点通读全局。

1. **接线仓库** —— `/stage-proj-adopt`（新克隆的模板也可以只填 `.env`）：STAR 配对、目标 venue、已有内容盘点 → `notes/adopt.md`。
2. **引入证据** —— STAR 来源用 `bash execs/scpts/import.sh`，手工文件用 `/stage-evid-curator`：`mates/` 下的带指纹快照，每个文件一条 `MANIFEST.md` 记录。
3. **打磨故事** —— `/stage-stry-coach`：pitch、贡献、venue 理由写进 `notes/story.md`；每条贡献成为台账里一条 `proposed` 论断；venue 的页数上限和截稿日期以用户确认的事实写进 `cycls/<cycle>/venue.yml`。
4. **搭论文骨架** —— `/stage-outl-planner`：带页数预算的章节表、图表计划、论断→章节分配写进 `notes/outline.md`；骨架 `.tex` 文件出现在 `manus/secs/` 下，`main.tex` 中对应的 `\input` 行被取消注释；`notes/notation.md` 被播种。
5. **建参考文献基座** —— `/stage-refs-curator`：`notes/refs/` 里带可引用事实的阅读笔记、干净的 `reference.bib`、相关工作定位。
6. **起草** —— `/stage-sect-drafter` 每次一个章节，依据简报、证据和论断；`/stage-tabs-builder` 从证据生成表格；`/stage-figs-designer` 把每张图从源文件做到渲染 PDF。台账状态翻到 `drafted`。
7. **润色** —— `/stage-copy-editor`：清晰、流畅、记号一致；含义和数字碰不得。
8. **审计** —— `/stage-clms-auditor` 把每个数字追溯到指纹；`/stage-cite-auditor` 核查每条引用和断言；每个失败都变成一条 `tasks/` 条目和一个台账状态，而不是埋在报告里的一行。
9. **评审与回复** —— `/stage-peer-reviewer` 召集五视角模拟评审团（或用 `quick` 单遍模式），把 meta-review 写进 `cycls/<cycle>/reviews/`；真实评审以 `received_<id>.md` 放进同一目录；`/stage-resp-writer` 把它们全部整理成逐点台账、一份不超 venue 限制的回复，以及 `tasks/` 里的承诺复选框。
10. **打包冻结** —— `/stage-subm-packer`：build 和 lint 必须通过、走查检查单、包放到 `wkdrs/builds/` 下、写出 `SUBMISSION_<date>.md`、打出标签 `freeze/<cycle>_<date>`。camera-ready 模式在 `tasks/<cycle>_promises.md` 还有未勾选项时拒绝打包。

## 证据、指纹与论断台账

三条原则承载整个设计：

**A. 证据单向流动。** STAR 产物（或人工登记的文件）被快照进只读的 `mates/`，稿件只引用它们。数字住在上游：要改一个数字，去 STAR 改好再重新导入——绝不编辑 `mates/`。每个证据文件在 `mates/MANIFEST.md` 里都有一条记录：

```markdown
## xsam/wkdrs/results/results.md
- source-type: star
- source: $STAR_HOME/wkdrs/results/results.md
- source-commit: 3f2a91c
- source-stamp: updated: 2026-07-28
- imported: 2026-08-02
- covers: main COCO and LVIS results for Tables 1–2
```

`source-stamp` 就是指纹：上游文件自己的 `generated:`/`updated:`/`finalized:` 日期。过期检测靠与上游当前值的精确比对（`import.sh --diff`），从不看文件 mtime——于是"论文脚下的数字变了"是一次机械检查，而不是一段记忆。

**B. 论断台账是枢纽。** `notes/claims.md` 把每条论断的陈述位置 ⇄ 证据 ⇄ 状态连在一起：

```markdown
| ID | Claim | Type | Stated in | Evidence | Status |
|----|-------|------|-----------|----------|--------|
| C3 | +2.1 mask AP over X on LVIS | performance | `4_expts`, `tabs/main` | `mates/xsam/wkdrs/results/results.md#lvis` | verified |
```

生命周期：`proposed`（故事提出）→ `drafted`（写进正文）→ `verified`（审计对上了证据）/ `unsourced`（写了但没有指纹——必须带 `\todo`）/ `weakened`（回复中让步）/ `dropped`（放弃）。故事播种论断，起草陈述论断，审计验证论断，回复捍卫论断：同一批行，一路走到投稿。

**C. 确定性检查放在脚本里，判断放在 skill 里。** grep 能抓的——未定义引用、`\todo` 标记、页数上限、匿名泄漏、过期的 stamp——由 `lint.sh` 和 `import.sh --diff` 抓，并可作为投稿闸门。需要判断的——这条论断真的成立吗、这张表是不是说明这个点的最佳方式——住在 skill 里。

编造红线（规范 §9）把环闭上：`manus/` 里的每一个数字，要么可追溯到一条带指纹的 `mates/` 记录，要么写成 `\todo{...}`——没有第三种状态；关于被引论文的每个断言都必须能对上一份阅读笔记；venue 规则只以用户确认的事实录入；任何 skill 都不得"为了帮忙"而放松这些规则。

## 更新 STAGE 的 skill 与工作流文档

从 STAGE 创建论文之后，可以随时同步 STAGE 的后续版本，而不碰你的稿件：

```bash
bash execs/update.sh
```

默认从 `STAGE_REPOSITORY` 更新四份 skill 目录——`.claude/skills/`、`.agents/skills/`、`.cursor/skills/`、`.kimi-code/skills/`——以及 `docs/mds/stage-workflow/`。完整形式是 `bash execs/update.sh [--diff] [ref] [--skill NAME] [--adopt]`：

- `--diff` 只预览、不改任何文件，有更新会改动文件时以退出码 `1` 结束——便于脚本化。
- `ref` 把更新钉在某个 tag 或分支上。
- `--skill NAME` 只更新一个 skill，四份目录同步。
- `--adopt` 把骨架装进一个已有仓库，只复制缺失的文件（见[步骤 1b](#1b-或者接入一个已有的论文仓库)）。

如果你改的是 STAGE 本身而不是某篇论文：`bash .github/scripts/check_consistency.sh` 守着四份手工维护的 skill 目录自己守不住的那些不变量——各处 skill 集合与文件清单一致、slash-only 守卫在四套 harness 上互相吻合、调用 token 与工具名各归其树、Cursor 规则仍与 `AGENTS.md` 逐行对齐、description 不超 `SKILL.md` 的 1024 字符上限、开场装载完整、每条 `规约 §n` 引用都还解析得到。它在每次 push 与 PR 时跑 CI，属于上游维护工具——`.github/` 不会同步进论文仓库。

`docs/mds/stage-workflow/` 由上游管理：不要在实例里编辑它，`update.sh` 会覆盖。harness 配置反过来——`AGENTS.md`、`.cursor/rules/` 与 `.cursorignore` 只在缺失时由 `--adopt` 安装，更新永远不覆盖它们，所以项目可以改自己的副本。`.cursor/rules/agent-instructions.mdc` 就是 `AGENTS.md` 的正文加一段规则头；改了其中一份，就把另一份同步。

## 路线图

v1 未含、计划推进：

- **远程 git 导入源** —— `import.sh` 直接从 git URL 按钉住的 ref 拉取证据，不再要求本地检出。
- **`.cursor/`、`.codex/`、`.kimi-code/` 目录** —— 对齐 STAR 的其余工具 skill 镜像。
- **skill 级资产** —— venue 评分标准、回复模板、问题清单，作为 `references/` 放在使用它们的 skill 旁边。
- **一致性 CI** —— 用 GitHub 检查保持 `.claude`/`.agents` 双目录与文档同步，如同 STAR 对它的四份镜像所做的。
- **溯源钩子** —— STAR 式的 model-id 记录，覆盖每个 skill 写出的产物。

## 引用

如果 STAGE 对你的研究写作有帮助，请引用：

```bibtex
@misc{stage2026,
  title = {{STAGE}: Systematic Toolchain for Authoring, Guiding, and Editing},
  author = {Hao Wang},
  howpublished = {\url{https://github.com/wanghao9610/STAGE}},
  year = {2026}
}
```

## 许可证

STAGE 基于 [MIT 许可证](LICENSE)发布。
