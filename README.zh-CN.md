<div align="center">
  <img src="docs/srcs/stage-project-icon.png" alt="STAGE 项目图标" width="128">
  <h1>STAGE</h1>
  <p><strong>Systematic Toolchain for Authoring, Guiding, and Editing</strong></p>
  <p><em>STAR 的学术写作伴侣 —— every STAR needs a STAGE。</em></p>
  <p><a href="https://wanghao9610.github.io/STAGE/"><strong>文档站点</strong></a></p>
</div>

**语言：** [English](README.md) | 简体中文

STAGE 把一个研究项目变成一篇提交的论文，并保证全程证据链不断。它把稿件、导入的实验证据、写作元数据和投稿周期分别放在约定好的目录中，给研究者和 AI 写作助手同一个构建入口、同一份共享规范，并提供一条完整的写作工作流——证据导入、故事、提纲、起草、图表制作、审计、模拟评审、回复、投稿打包。稿件中的每一个数字要么可追溯到一份带指纹的证据文件，要么被显式标记为缺失；每一条论断（claim）都在同一本记录表中从提出一路跟踪到验证。

STAGE 是 [STAR](https://github.com/wanghao9610/STAR)（*Systematic Toolchain for AI Research*，系统化 AI 研究工具链，[文档站点](https://wanghao9610.github.io/STAR/)）在写作侧的伴侣仓库：STAR 负责推进研究、产出方法文档、实验结果和阶段小结；STAGE 把它们快照为只读证据，在其上写出论文。配对是可选的——STAGE 也可以完全独立使用，证据由人工登记。

STAGE 采用双层模型：本仓库是**模板**；一篇论文 = 一个**实例**，通过克隆模板创建，或用 `execs/update.sh --adopt` 把骨架装进一个已有的论文仓库。实例之后可以通过 `update.sh` 从上游同步 STAGE 管理的 skill 和工作流文档，而不会碰你的稿件。

## 目录

- [目录](#目录)
- [STAR · STAGE · STORY](#star--stage--story)
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
- [证据、指纹与论断记录表](#证据指纹与论断记录表)
- [项目记忆](#项目记忆)
- [更新 STAGE 的 skill 与工作流文档](#更新-stage-的-skill-与工作流文档)
- [项目约定](#项目约定)
- [将 STAGE 用于新论文](#将-stage-用于新论文)
- [引用](#引用)
- [许可证](#许可证)

## STAR · STAGE · STORY

三个项目覆盖研究者工作的不同尺度。它们可以各自独立使用，也可以通过带指纹的证据彼此衔接。

| 项目 | 范围 | 链接 |
| --- | --- | --- |
| **STAR** — Systematic Toolchain for AI Research | 推进一个研究项目：从想法出发，经可复现实验，产出可直接用于论文的证据。 | [官网](https://wanghao9610.github.io/STAR/) · [GitHub](https://github.com/wanghao9610/STAR) |
| **STAGE** — Systematic Toolchain for Authoring, Guiding, and Editing | 把一项研究贡献写成可追溯的论文，贯穿评审、回复与投稿打包。 | **当前项目** · [官网](https://wanghao9610.github.io/STAGE/) · [GitHub](https://github.com/wanghao9610/STAGE) |
| **STORY** — Systematic Toolchain for Organizing Research over Years | 把研究生阶段的研究组织成可答辩、可归档的硕士或博士学位论文。 | [官网](https://wanghao9610.github.io/STORY/) · [GitHub](https://github.com/wanghao9610/STORY) |

## STAGE 提供什么

- **统一的稿件结构**：章节、图（含源文件）、表、参考文献、venue 样式，各归其位，都在 `manus/` 下。
- **只读的证据层**：STAR 产物（或人工登记的文件）被快照进 `mates/`，每个文件带一枚指纹，记录在 `mates/MANIFEST.md`。证据单向流动——要改一个数字，去上游改好再重新导入；绝不直接编辑 `mates/`。
- **作为枢纽的论断记录表**：`notes/claims.md` 把每条论断的陈述位置 ⇄ 证据 ⇄ 状态连在一起。写作提出论断，审计验证论断，回复捍卫论断。
- **统一的构建入口**：`execs/run.sh` 用 latexmk 把 `manus/main.tex` 编译到树外的 `wkdrs/builds/`，并打印 PDF 路径和页数。
- **确定性检查放在脚本里，判断放在 skill 里**：`execs/scpts/lint.sh` 机械地抓未定义引用、`\todo` 标记、超页和匿名泄漏；它还会对高置信度聊天机器人残留和集中出现的公式化表达给出建议性警告。这些警告只请求人工复核，不判断作者身份，也不会单独阻塞投稿。
- **完整的写作生命周期**：十六个相互配合的 skill，按运行顺序依次是——接线仓库、整理证据、打磨故事、规划提纲、逐节起草、由证据生成表格、设计图、维护参考文献、润色文字、审计每个数字、审计每条引用、模拟评审、撰写回复、打包投稿、做海报、汇报状态。
- **投稿周期即数据**：每次投稿尝试都住在 `cycls/<venue>_<year>/` 里：经用户确认的 `venue.yml` 档案、真实与模拟评审、回复，以及冻结的投稿记录。
- **一套工作流，七套 harness**：同样的十六个 skill 供 Claude Code、Codex、Cursor、DSH、Kimi Code、Pi 和 Qwen Code 使用。工具无关的 skill 文件只在 `.agents/skills/` 保存一份，完整的 `/stage` 请求路由器只在 `.agents/commands/` 保存一份；各原生树只保留 harness 专属措辞和参数适配层。
- **属于论文自己的记忆**：一次会话学到、而仓库里没有任何文件认领的东西——某个 TeX 工具链的坑、你的一项长期偏好、一个试过又被否掉的框架——记在 `.stage/memory/` 下，并由一个钩子在下一次会话开头摆到 agent 面前；不管你用哪个工具驱动 STAGE 都一样。
- **供人阅读的中文镜像**：各 skill 的 `references/` 文件旁边一份 `*_zh.md`、skill 指南旁边一份 `writing-workflow-skills.zh-CN.md`，以及 `docs/` 下的中文落地页——与英文版同步维护，运行时不装载，英文版始终是权威版本。

每个 skill 做什么、如何调用，见[写作工作流](#写作工作流)；逐 skill 的说明和流水线图，见[写作工作流 Skills 指南](docs/mds/stage-workflow/writing-workflow-skills.zh-CN.md)；所有 skill 共享的规则在[写作工作流规范](docs/mds/stage-workflow/writing-workflow-conventions.md)中，守住证据边界的文字处理流程见其中的[自然写作契约](docs/mds/stage-workflow/writing-workflow-conventions.md#human-writing-contract)。

## 项目结构

```text
STAGE/
├── manus/                  # 稿件
│   ├── main.tex            # 入口文件；开箱即可独立编译
│   ├── secs/               # 章节源文件：<n>_<slug>.tex（0_abstract.tex、1_intro.tex …）
│   ├── figs/               # 渲染好的图（PDF）；figs/srcs/ 存放每张图的源文件
│   ├── tabs/               # 表格，由证据生成
│   ├── bibs/               # reference.bib
│   └── stys/               # stage.cls（版式）+ stage.sty（\todo 与写作宏）
├── mates/                  # 导入的证据——只读
│   ├── <source-slug>/      # 按上游 STAR 路径镜像的快照
│   ├── manual/             # 人工登记的证据文件
│   └── MANIFEST.md         # 指纹记录表：每个证据文件一条记录
├── notes/                  # 写作元数据
│   ├── story.md            # 另有：claims.md、outline.md、notation.md、style.md、adopt.md
│   └── refs/               # 逐篇阅读笔记 + refs_index.md
├── cycls/                  # 投稿周期
│   └── <venue>_<year>/     # venue.yml、template/（venue 模板包）、reviews/、response/、SUBMISSION_<date>.md
├── tasks/                  # 修改暂存与承诺清单
├── wkdrs/                  # 构建产物与临时报告（gitignore，可再生）
├── execs/
│   ├── run.sh              # 构建入口（latexmk，树外构建）
│   ├── update.sh           # 同步上游 STAGE skill 与文档；--adopt 安装骨架
│   └── scpts/              # import.sh（证据导入）、lint.sh（确定性检查）、fmt.sh（一句一行）
├── docs/                   # 项目文档
│   ├── index.html          # GitHub Pages 文档入口（→ htmls/stage.html）
│   ├── htmls/              # 落地页：stage.html + stage_zh.html
│   ├── mds/stage-workflow/ # 规范 + skills 指南（由上游管理）
│   └── srcs/               # 文档图片及其他静态资源
├── .stage/memory/          # 项目记忆：早先会话学到的东西（local/ 被 git 忽略）
├── .agents/
│   ├── skills/             # 工具无关的共用 skill；其他技能树链接到这里
│   ├── commands/           # 共用 /stage 路由器与 /stage-auto 目标运行流程
│   └── plugins/            # Codex marketplace 发现入口：仅一个指向 .codex/plugins/ 的文件链接
├── .claude/
│   ├── skills/             # Claude Code 使用的写作工作流 skill
│   ├── hooks/              # 钩子：项目记忆索引、本次会话的模型 id、参与度放行与 shell 放行、提交守卫
│   └── settings.json       # 注册这五个钩子
├── .codex/                 # Codex 的钩子、逐 skill manifest 与 $stage / $stage-auto 插件
├── .cursor/
│   ├── skills/             # Cursor 使用的写作工作流 skill
│   ├── rules/              # 常驻规则：AGENTS.md 正文 + skill 目录归属
│   ├── hooks/              # 钩子，注册在 hooks.json 里
│   └── hooks.json
├── .dsh/                   # DSH 原生 skill、钩子与 /stage、/stage-auto 命令 bundle
├── .kimi-code/
│   ├── skills/             # Kimi Code 使用的写作工作流 skill
│   ├── plugins/            # 用户安装的 /stage、/stage-auto 插件与 marketplace
│   ├── hooks/              # 钩子 + install.sh（Kimi 只认全局注册）
│   └── hooks.example.toml  # install.sh 替你写进配置的那段注册片段
├── .pi/                    # Pi 原生 skill、prompt、agent 与能力扩展
├── .qwen/                  # Qwen 原生 skill、command、钩子与设置
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
| `stys/` | Styles | `stage.cls` 与 `stage.sty`——venue 模板包放在 `cycls/<cycle>/template/`，不在这里 |
| `mates/` | Materials | 导入的证据快照——只读 |
| `cycls/` | Cycles | 每次投稿尝试一个目录 |
| `execs/` | Executions | 入口脚本；工具脚本放在 `scpts/` |
| `wkdrs/` | Work directories | 构建产物与临时报告，永不提交 |
| `mds/` | Markdowns | 按主题分组的 Markdown 文档 |
| `srcs/` | Static sources | 文档引用的图片及其他静态资源 |

三条目录树本身写不下的规则：`mates/` 只读（只有 `import.sh` 和 `/stage-evid-curator` 可以写入，且只做带指纹的整文件新增或替换）；`wkdrs/` 永不提交（可留存的审计结论以 `notes/claims.md` 的状态翻转和 `tasks/` 条目写进文件，而不是报告文件）；`execs/` 根目录封闭（只有 `run.sh` + `update.sh`——工具脚本一律放 `execs/scpts/`）。

## 论文模板

`manus/` 自带一套紧凑的 arXiv 风格预印本模板，按"换 venue 模板时会遭遇什么"拆成三个文件——两个是被替换掉的那部分，一个必须活下来：

| 分层 | 文件 | 负责 | 在 venue 版式里 |
| --- | --- | --- | --- |
| 版式层 | `manus/stys/stage.cls` | 页面尺寸、字体、标题面板、标题层级、图表标题、浮动体、引用宏包 | 被 venue 自己的 class **替换** |
| 参考文献层 | `manus/stys/stage.bst` | 条目怎么排：按作者排序、`[3]` 式编号，且不打印 DOI、URL、ISBN、ISSN | 被模板包自带的 `.bst` **替换** |
| 写作层 | `manus/stys/stage.sty` | `\todo{...}`，以及写作 skill 会写进 `secs/`、`tabs/` 的那些宏 | **逐字带过去**——不论 class 换成什么，`\usepackage{stys/stage}` 这一行都留着 |

`stage.bst` 是 `plainnat` 掐掉了四个字段，CVPR 自己的样式就是这么做的：DOI 或 URL 仍留在 `reference.bib` 里——那是该条目的来源凭据，也是 `/stage-refs-curator` 重新取记录的依据——只是不排版出来，于是参考文献表读起来像一篇会议论文，而不像一份数据库导出。

扩展 class 或 package 时请守住这条分界：章节或表格文件里会出现的东西放进 package，只有页面外观需要的东西放进 class。项目自己的宏（`\newcommand{\method}{...}`）写在 `main.tex` 里，不要写进 `stys/`——这三个模板文件都会被替换或更新。

**怎么转成会议模板。** 不是就地换 class。`manus/main.tex` 永远编译成预印本；venue 版式是一份**生成出来的副本**：

1. 下载 venue 的官方作者模板包（CVPR、NeurIPS、ACL、某个 IEEE 期刊——它以什么形式发布就是什么）。
2. `/stage-subm-packer convert kit=<zip 或目录的路径>`——模板包整份、不加编辑地解包进 `cycls/<cycle>/template/`，与该周期的 `venue.yml` 并列。它刻意不放进 `manus/`：那棵树会被 `lint.sh` 扫描，而模板包自带的示例 `.tex` 会触发 `\todo` 计数和身份泄漏扫描。`venue.yml` 的 `template:` 指名的是模板包里那个 class。
3. 这次运行会读模板包自带的示例 `.tex` 以取得它要的宏，在 `wkdrs/` 下写出一份独立副本——venue 的 class、逐字带过去的 `stage.sty`、一个为"`stage.cls` 提供过而 venue class 没有"的部分生成的精简 `compat.sty`、一份用 venue 的宏重新发射你的标题/作者/abstract 的 `main.tex`，以及原封不动的 `secs/`、`tabs/`、`figs/`、`bibs/`——然后构建它，并报出**该版式下**的页数，那才是 `page_limit_main` 真正指的那个数。

`manus/` 永不被编辑，副本每次运行都从头重新生成，模板也绝不去抓、绝不凭记忆写：官方模板包是唯一来源。转换替你做不了的事，会落成 `tasks/<cycle>_venue.md` 里的一行 `- [ ]`，点名由哪个 skill 来修——是一份被跟踪的清单，而不是聊天窗口里的一句话。压页数期间想跑多少次 `convert` 就跑多少次——它跳过所有冻结关口，所以在手稿里还有 `\todo` 时照样能用。

**class 选项**——`\documentclass[twocolumn]{stys/stage}`：`onecolumn` | `twocolumn`，外加 `anon`，以及 `article` 支持的其他选项。导言区中，`\paperstyle{fancy|simple}` 选择带框或平铺的标题面板，`\papercolor{green|blue|black}` 选择配色。

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
# 持续更新的 harness 树：逗号分隔的名称 | all | none
STAGE_HARNESSES=
# 可选。skill 决定之前问多少：low | medium | high
INVOLVE=medium
# 可选。回复与文档语言：en | zh；留空 = 跟随对话
STAGE_LANG=
# 可选。每一档的模型：PLAN | EXEC | READ；留空 = 什么都不变
STAGE_PLAN_MODEL=
STAGE_EXEC_MODEL=
STAGE_READ_MODEL=
```

`STAR_HOME` 决定你走哪条快速开始路径。本地 `.env` 已被 Git 忽略。

`INVOLVE`（可选，`low` | `medium` | `high`）决定 skill 在拿定主意之前问多少。在 `low` 档，裁量题一律取推荐项并记录在案，本次运行写出的东西不问就提交、并在回复里点名每一次提交；在 Claude Code、Codex 与 Qwen Code 里，文件编辑前的权限提示也会被跳过；在 Claude Code 里，shell 命令前的权限提示同样跳过，除非该命令删除、覆盖已跟踪文件、安装、推送，或写入 `mates/`、venue 模板包或 `.env`。`medium`（默认）按文档所写发问，`high` 逐条确认。任何档位都不会收回你已经给出的批准，也不会替你给出你没给的批准：你已经批准过的事——之前的一次回答，或调用时一句明确的请求，比如 `and commit it`——在其范围内不会再问第二次。硬门槛任何档位都要问，之前的批准也替代不了它：红线、删除与覆盖、每一个以"已确认"身份进入 `venue.yml` 的取值、登记证据时它的来源，以及六个 slash-only skill 各自的决定点。只想改一次运行的档位，就在调用 skill 时带上同样的写法：`/stage-sect-drafter 3_method involve=low`——在 Claude Code 里这个 token 连权限提示一并作数：钩子从会话里最近一条 STAGE 命令读它，一直有效到下一条命令为止；别的宿主的权限提示只认 `.env`。完整规则见[规约 §7.7](docs/mds/stage-workflow/writing-workflow-conventions.md)。

`STAGE_LANG`（可选，`en` | `zh`）决定聊天回复以及工作流所写 Markdown 的语言——`notes/`、`tasks/`、模拟评审、`wkdrs/` 报告。留空则一切跟随对话本身的语言。无论它取什么值，有两样东西始终是英文，因为读它们的是仓库之外的人：`manus/` 下的手稿，以及给评审的回复。任何语言的文档里，结构性字面量同样保持英文——frontmatter 键、记录表状态、ID、路径、bibkey、venue 名与指标名——这正是中文笔记仍然可被机器读取的原因。完整规则见[规约 §7.6](docs/mds/stage-workflow/writing-workflow-conventions.md)。

`STAGE_PLAN_MODEL`、`STAGE_EXEC_MODEL` 与 `STAGE_READ_MODEL`（可选）分别指定论文判断——故事、提纲、起草、模拟评审、回复——所用的模型，产出与核查所用的模型，以及只读状态报告、检查模式与只做收集的委派所用的模型；规约 §11 的 skill 名单写明每个 skill 属于哪一档。每个键写一个模型名，或逗号分隔、按 `STAGE_HARNESSES` 标签写的 `<harness>:<model>` 条目：运行先取本树的条目，再取无标签的条目，两者都没有就沿用 harness 的默认模型。只有派发工具能逐次指定模型的 harness 才读取这三个键——Claude Code，以及子代理接口接受模型参数时的 Codex；Cursor、DSH、Kimi Code、Pi 与 Qwen Code 忽略它们。你敲下的 skill 留在你会话的模型上，它那一档指定了别的模型时会用一行说明；拿到那个模型的唯一办法是切换会话的模型。留空时它们什么都不改变。完整规则见[规约 §11.6](docs/mds/stage-workflow/writing-workflow-conventions.md)。

### 3. 路径 A：与 STAR 仓库配对

把 `STAR_HOME` 指向你的 STAR 项目，然后导入：

```bash
bash execs/scpts/import.sh
```

导入会把 STAR 中与写作相关的产物——方法文档（`metds/overview.md`、`framework.md`、`dataset.md`、`training.md`、`evaluation.md`，加上 `adopt.md` 和 `codearc.md`）、选题陈述、参考文献笔记与 `reference.bib`、结果表、实验小结——按相同的相对路径快照进 `mates/<slug>/`，并在 `mates/MANIFEST.md` 里为每个文件记录来源、来源 commit 和内容指纹。当稿件还没有参考文献库时，STAR 的 `reference.bib` 会被播种到 `manus/bibs/`。新实验落地后重新运行即可；先用下面的命令检查漂移：

```bash
bash execs/scpts/import.sh --diff   # 只读的过期检查报告；有漂移以退出码 2 结束，硬错误为 1
```

多个 STAR 仓库可以喂同一篇论文：`import.sh --source PATH --slug NAME` 可以用独立的 slug 导入任何一个符合 STAR 布局的本地检出。

### 4. 路径 B：独立使用

让 `STAR_HOME` 保持为空。把证据文件——结果导出、合作者发来的数字、一份 wandb CSV——放到 `mates/manual/` 下的任意位置，然后运行 `/stage-evid-curator`，把每个文件登记进 `mates/MANIFEST.md`，登记为 `manual` 条目，来源用自由文本写明（如 "results emailed by X, 2026-08-01"）。它还会规整杂乱的文件（一份 CSV 会在旁边生成一份结果格式的 `.md`，标注 `normalized-from:`），并提出论断⇄证据的映射建议。下游的一切——起草、表格、审计——完全相同：登记过的手工文件和导入的 STAR 文件同样可以被引用，而未登记的文件对写作 skill 来说等于不存在。

### 5. 构建与检查

```bash
bash execs/run.sh          # latexmk 树外构建 → wkdrs/builds/ + PDF 路径和页数
bash execs/scpts/lint.sh   # 硬门禁 + 建议性的集中套话复核
bash execs/scpts/fmt.sh    # 一句一行；--check 只报告偏离，不写入
```

新检出的仓库用普通 pdflatex 开箱即可编译，而且自带的稿件里故意留了一个 `\todo{}`——第一次运行 lint 就能直观看到这道闸门，日后它拦住的就是你真正缺失的数字。`lint.sh` 在以下情况硬性失败：未定义引用、超出页数上限、残留 `\todo` 标记、以及（`ANON=true` 时）身份泄漏；其余都是警告。其中一条警告来自 `fmt.sh --check`：LaTeX 把换行读成一个空格，所以稿件保持一句一行——diff 显示的是你改动的那一句而不是它所在的整段，`% src:` 注释也永远就在它所溯源的那句上面一行。

### 6. 启动写作工作流

骨架本身就能独立使用——目录布局、`.env`、`run.sh`、`import.sh` 不装任何 skill 也有用。要接上工作流，从下面最符合你现状的一行开始：

| 你的现状 | 从这里开始 |
| --- | --- |
| 新仓库，证据刚导入 | `/stage-stry-coach` |
| 用步骤 1b 接入的已有草稿 | `/stage-proj-adopt` |
| 故事已定稿，可以搭骨架 | `/stage-outl-planner` |
| 回到一篇写作中的论文 | `/stage-flow-status` |

`/stage-flow-status` 是最值得记住的一个：它读取盘上的提纲、记录表、manifest 和周期状态，给出唯一的下一步行动及其准确命令，你永远不必回忆上次写到哪里。

**两个会话钩子。** 一个在每次会话开头提供[项目记忆](#项目记忆)索引；另一个报出运行时模型 id，让产物记录 `model_id` 与追加的 `model_trail`（工作流规约 §8）。在 Claude Code 里，子代理启动时这两个钩子会再跑一次，因为会话钩子不会为子代理触发：溯源钩子把解析该子代理自己转录的命令交给它，于是子代理写出的产物记录的是真正写下它的模型，而不是会话的模型；记忆钩子也为它再给一遍索引。Claude、Codex、Cursor、Pi 和 Qwen 从项目内注册；Kimi 与 DSH 因为把钩子注册放在项目外，需要各运行一次 `.kimi-code/hooks/install.sh` 与 `.dsh/hooks/install.sh`。Codex 项目钩子仍需通过 `/hooks` 批准。

**另外三个钩子做决定而非注入。** Claude、Codex 与 Qwen 带 `INVOLVE=low` 的编辑权限放行钩子。Claude 还带它在 shell 一侧的对应物 `stage_bash_gate.sh`：在 `low` 档，它放行普通的本地命令——构建、lint、grep、脚本、按名暂存与提交——而删除、覆盖已跟踪文件、除经 `execs/scpts/import.sh` 之外对 `mates/` 的任何写入、对 venue 模板包或 `.env` 除读取之外的任何操作、安装（`sudo`、`tlmgr`、包管理器）、`git push` 及其他外发、`git pull`、作业提交、历史改写与清理、切换分支、除列出之外的 tag 操作以及进程或系统控制，仍走宿主的常规权限提示；提交守卫的拒绝仍优先于它的放行。七套 harness 都带 `stage_commit_guard.sh`，用于拒绝[规约 §1](docs/mds/stage-workflow/writing-workflow-conventions.md) 禁止的 git 命令；Pi 从项目扩展注册，DSH 与 Kimi 通过各自的钩子桥接注册。

## 写作工作流

STAGE 包含十六个相互配合的 skill，把导入的证据和一个故事变成一篇论断链可审计的投稿论文。

**如何调用。** 前缀因工具而异：

| 工具 | 调用方式 | 示例 |
| --- | --- | --- |
| Claude Code | `/stage-<name>` | `/stage-sect-drafter 1_intro` |
| Codex | `$stage-<name>` | `$stage-sect-drafter 1_intro` |
| Cursor | `/stage-<name>` | `/stage-sect-drafter 1_intro` |
| DSH | `/skill:stage-<name>` | `/skill:stage-sect-drafter 1_intro` |
| Kimi Code | `/skill:stage-<name>` | `/skill:stage-sect-drafter 1_intro` |
| Pi | `/stage-<name>` | `/stage-sect-drafter 1_intro` |
| Qwen Code | `/stage-<name>` | `/stage-sect-drafter 1_intro` |

Claude Code、Cursor、Pi 与 Qwen Code 直接从项目文件提供 `/stage [你想做什么]`。命令把请求交给 `.agents/commands/stage.md`；空请求选择 `stage-flow-status`，匹配到六个只能显式调用的 skill 之一时，则返回准确的 `/stage-<name> <argument>` 命令并等待。

Codex 把共享分流器打包成仓库内的 `stage` 插件。在仓库根目录注册并安装一次，然后新开会话：

```bash
codex plugin marketplace add .
codex plugin add stage@stage
```

不带参数的 `$stage` 显示当前论文状态，也可以传入描述，例如 `$stage 审计实验章节中的每个数字`。插件读取的仍是其他宿主 `/stage` 薄包装共用的 `.agents/commands/stage.md` 名册，不会再维护第二份分流表。

Kimi Code 把同一个分流器作为用户级插件打包在 `.kimi-code/plugins/stage/`。请从仓库根目录启动 Kimi Code，在输入框依次运行下面两条命令；也可以用 `/new` 代替 `/reload`：

```text
/plugins install ./.kimi-code/plugins/stage
/reload
```

不带参数的 `/stage` 显示当前论文状态，也可以传入描述；`/skill:stage` 是同一个外部 skill 的完整写法。Kimi 会把本地插件复制进用户级托管目录，所以 STAGE 更新了该插件后，需要重新执行安装命令。

DSH 把同一个分流器放在 `.dsh/commands/stage/`；安装时要求 `PATH` 上有 `pnpm`。在仓库根目录为每个将运行 STAGE 的 profile 安装一次，检查组合后的配置，再重启该 profile：

```bash
dsh plugin --profile YOUR_PROFILE add ./.dsh/commands/stage
dsh --profile YOUR_PROFILE --dump-config
```

不带参数的 `/stage` 显示当前论文状态，也可以传入描述，例如 `/stage 审计实验章节中的每个数字`。命令会从共享的 `.agents/commands/stage.md` 名册发起一个后续轮次，因此 DSH 与其他宿主始终从同一来源分流。

每次运行都以同样的方式结束：给出报告和下一条要运行的准确命令；除非你要求它接着做，它不会再启动别的运行。`/stage-auto <目标> [involve=<level>]` 追求一个写明的目标，而不是处理单个请求——Codex 里写作 `$stage-auto`；Kimi Code 与 DSH 里它随 `/stage` 所在的同一个插件或 bundle 一起提供。例如 `/stage-auto 方法章节起草完成且其中数字审计完毕` 会先运行 `stage-flow-status`，再逐个启动目标需要的下一个未标记 skill，每次只做一个工作单元。目标的检查通过时它就停下；遇到任何标 † 的 skill 时也停下（打印准确命令，由你来敲）；遇到专为留给你做选择的模式（`stage-refs-curator discover` 或 `position`、`stage-copy-editor style`、`stage-peer-reviewer extern=`）、红线动作、只有你能回答的问题、尚未经你确认的 venue 数值、只剩等你处理的工作（待导入的证据、待勾选的承诺框）、同一次启动的重复、一整轮没有任何改动，或一个失败动作的修复也失败时同样停下。它从不导入证据、不录入 venue 事实，自己也不提交；它启动的每个 skill 保留各自的提交步骤。流程只在 `.agents/commands/stage-auto.md` 保存一份，各宿主的入口都委托给它（[规约 §11](docs/mds/stage-workflow/writing-workflow-conventions.md) 第 5 条）。

六个 skill（下表以 † 标注）仅限显式调用（slash-only）：接入、故事、提纲、回复、投稿与海报选择。六套具名 harness 的 manifest 使用 `disable-model-invocation: true`；Codex 在 `.codex/skills/` 中使用 `allow_implicit_invocation: false`，再链接到共用根。CI 会把七套实现都与[规约 §11](docs/mds/stage-workflow/writing-workflow-conventions.md) 核对。

<div align="center">
  <img src="docs/srcs/stage-writing-workflow.png" alt="STAGE 写作工作流：十五个 skill 的调用顺序与一个横向通读的 skill、各自写出什么，以及起草循环与拒稿回流如何闭合" width="100%">
</div>

| Skill | 用途 | 主要产出 |
| --- | --- | --- |
| `stage-proj-adopt` † | 把新的或已有的论文仓库接进 STAGE：把配对 STAR 仓库写进 `.env`、确定目标 venue、盘点并映射已有 tex 树，把草稿里已有的数字转为 `unsourced` 论断进入审计待办 | `notes/adopt.md` |
| `stage-evid-curator` | 证据接收与映射：运行 `import.sh`、登记 `mates/manual/` 下的手工文件、规整杂乱导出、提出论断⇄证据映射、暴露过期——绝不就地修改证据 | `mates/<slug>/**`、`mates/manual/**`、`mates/MANIFEST.md` 条目 |
| `stage-stry-coach` † | 对话优先的故事打磨：pitch、问题、核心想法、带论断编号的贡献列表、venue 理由；播种论断记录表和经用户确认的 venue 档案 | `notes/story.md`、播种的 `notes/claims.md`、`cycls/<cycle>/venue.yml` |
| `stage-outl-planner` † | 故事 → 骨架：页数预算合计不超 venue 上限的章节表、图和表的计划、论断→章节分配、骨架 `.tex` 文件、记号表种子 | `notes/outline.md`、`manus/secs/*.tex` 骨架、`notes/notation.md` |
| `stage-sect-drafter` | 每次调用起草或修改一个章节，依据章节简报、映射的证据、论断和记号规范；没有指纹的数字一律写成 `\todo{}` | `manus/secs/<n>_<slug>.tex` |
| `stage-tabs-builder` | 只从 `mates/` 证据生成表格——booktabs 风格，每个数据行一条 `% src:` 指纹注释，缺数据的格写 `\todo`。手敲数字正是这个 skill 要杀死的失败模式 | `manus/tabs/<slug>.tex` |
| `stage-figs-designer` | 负责图清单和每张图的端到端：用途、`figs/srcs/` 下的可编辑源文件、渲染的 PDF；首图（teaser）有专属检查单 | `manus/figs/<slug>.pdf` + 源文件 |
| `stage-refs-curator` | 文献库卫生、新读论文的笔记录入、相关工作定位；存在导入的 STAR 参考文献时以其为种子，没有时用 `discover` 按主题检索并提议候选 | `manus/bibs/reference.bib`、`notes/refs/<ABBREV>.md`、`notes/refs/refs_index.md` |
| `stage-copy-editor` | 打磨一节或整篇手稿：清晰度、流畅度、自然的学术表达、记号一致性与篇幅收紧——段落级改写不改变技术含义、数字、引用、归属或主张强度；`style` 模式改为记录作者的散文档位 | `manus/` 中编辑后的散文、`wkdrs/reports/POLISH_<date>.md`、`tasks/` 条目、`notes/style.md` |
| `stage-clms-auditor` | 机械化的心脏：提取稿件里的每一个数字，逐一追溯到带指纹的证据条目，逐数判定 matched / mismatched / unsourced，翻转记录表状态，检查证据过期 | `notes/claims.md` 的状态翻转、`wkdrs/reports/CLAIMS_<date>.md`、`tasks/` 条目 |
| `stage-cite-auditor` | 每个 `\cite` key 都能解析；关于被引论文的每个断言都能对上一份阅读笔记——对不上的断言被标记，绝不悄悄改掉 | `wkdrs/reports/CITES_<date>.md`、`tasks/` 条目 |
| `stage-peer-reviewer` | 模拟程序委员会：五视角评审团（新颖性与相关工作、技术正确性、实验严谨性、清晰度、魔鬼代言人），引用只认 whitelist/verified，按锚定评分带 + 封顶规则打分；`quick` 为单遍精简模式；绝不修改稿件 | `cycls/<cycle>/reviews/SIM_REVIEW_<date>.md` |
| `stage-resp-writer` † | 把真实与模拟评审解析成逐点记录表，把每个攻击映射到论断和证据，在 venue 限制内起草回复，把每个承诺的修改记为复选框 | `cycls/<cycle>/response/RESPONSE_<date>.md`、`tasks/<cycle>_promises.md`、`notes/claims.md` 里降级为 `weakened` 的行 |
| `stage-subm-packer` † | 投稿前检查与打包：build + lint 必须通过、走查检查单、完整性扫描、依官方模板包转成 venue 自己的版式、打包、投稿记录、冻结标签——camera-ready 模式在承诺未清空前拒绝打包 | `cycls/<cycle>/SUBMISSION_<date>.md`、标签 `freeze/<cycle>_<date>`、`cycls/<cycle>/template/` 下的模板包、`tasks/<cycle>_venue.md` 里的 venue 待办 |
| `stage-pstr-builder` † | 把录用的论文压成一张纸：一句核心结论、论断记录表里状态为 `verified` 的论断、从 `manus/figs/` 原样复用的图——外加一道按印刷尺寸折算有效字号的可读性闸，且不许 `\todo` 上墙 | `cycls/<cycle>/poster/POSTER_PLAN.md` + `poster.tex`，渲染产物在 `wkdrs/builds/poster/` |
| `stage-flow-status` | 全流程的只读地图：章节/图/表状态、按状态统计的论断覆盖、证据新鲜度、周期状态、最近一次构建——以及唯一的下一步行动和它的准确命令 | 聊天内报告；从不写文件 |

**投给多个会议。** 一个 venue 就是一个 cycle。`cycls/<venue>_<year>/` 拥有这次尝试的 `venue.yml`、`template/` 下的官方模板包、评审、回复、`SUBMISSION_<date>.md` 和冻结 tag；稿件、证据和论断记录表则由所有尝试共享。

- **顺序投**——被拒之后改投别家——是原生路径。`/stage-stry-coach` 用那个 venue 经确认的档案建出下一个 cycle，`/stage-subm-packer convert kit=<path>` 把新模板包注册进去。旧 cycle 里的东西一样不动，所以"当时投的是哪个版式"永远能从它的冻结 tag 复现；共享记录表里 `weakened` 和 `unsourced` 的论断，就是下一轮最先要修的东西。
- **并行投**——同时要一份 CVPR 版和一份 NeurIPS 版，或者只是想比页数——做法一样，仍然一个 venue 一个 cycle：把 `notes/story.md` 的 `cycle:` 指向你要的那个，再转换。副本落在 `wkdrs/builds/<cycle>_<template>_<date>/`，目录名带 cycle 和 template，所以彼此不会覆盖。
- **同一个 cycle 里挂两套模板包**不支持，而且是刻意的。`cycls/<cycle>/template/` 是单数目录，`venue.yml` 的 `template:` 指名的是包里的某一个 class；往一个正在用的 cycle 上换模板包，会先给你看差异再询问，因为它会改变此前每个决定所依据的页数预算。

并行时有两件事要知道。`notes/outline.md` 只有一套页数预算，所以只能照着某一个 venue 的限制来规划——另一个靠 `convert` 报出来的页数来判断，这正是转换跳过所有关口、可以随便重跑的原因。另外 `.env` 的 `ANON` 是一个全局开关，而 `anonymized:` 是每个 cycle 各自的，切换时记得翻；忘了不会产出版式错误的包——运行会停下来，并告诉你该改哪一行。

## 通往投稿的十步路径

这些 skill 串成一条从证据到冻结投稿的路径。第 5–7 步逐章节循环；第 8 步成本低，可随时重复；`/stage-flow-status` 在任何时点通读全局。

1. **接线仓库** —— `/stage-proj-adopt`（新克隆的模板也可以只填 `.env`）：STAR 配对、目标 venue、已有内容盘点 → `notes/adopt.md`。
2. **引入证据** —— STAR 来源用 `bash execs/scpts/import.sh`，手工文件用 `/stage-evid-curator`：`mates/` 下的带指纹快照，每个文件一条 `MANIFEST.md` 记录。
3. **打磨故事** —— `/stage-stry-coach`：pitch、贡献、venue 理由写进 `notes/story.md`；每条贡献成为记录表里一条 `proposed` 论断；venue 的页数上限和截稿日期以用户确认的事实写进 `cycls/<cycle>/venue.yml`。
4. **搭论文骨架** —— `/stage-outl-planner`：带页数预算的章节表、图表计划、论断→章节分配写进 `notes/outline.md`；骨架 `.tex` 文件出现在 `manus/secs/` 下，`main.tex` 中对应的 `\input` 行被取消注释；`notes/notation.md` 被播种。
5. **建参考文献基座** —— `/stage-refs-curator`：`notes/refs/` 里带可引用事实的阅读笔记、干净的 `reference.bib`、相关工作定位。
6. **起草** —— `/stage-sect-drafter` 每次一个章节，依据简报、证据和论断；`/stage-tabs-builder` 从证据生成表格；`/stage-figs-designer` 把每张图从源文件做到渲染 PDF。记录表状态翻到 `drafted`。
7. **润色** —— `/stage-copy-editor`：清晰度、流畅度、自然的学术表达与记号一致性，含义、证据、数字、引用和归属不可触碰。它判断共同出现的模式并在段落尺度重写，不靠禁词表机械换词。需要时先用 `/stage-copy-editor style` 把论文文风记成 `notes/style.md` 里的可量档位。
8. **审计** —— `/stage-clms-auditor` 把每个数字追溯到指纹；`/stage-cite-auditor` 核查每条引用和断言；每个失败都变成一条 `tasks/` 条目和一个记录表状态，而不是埋在报告里的一行。
9. **评审与回复** —— `/stage-peer-reviewer` 召集五视角模拟评审团（或用 `quick` 单遍模式），把 meta-review 写进 `cycls/<cycle>/reviews/`；真实评审以 `received_<id>.md` 放进同一目录；`/stage-resp-writer` 把它们全部整理成逐点记录表、一份不超 venue 限制的回复，以及 `tasks/` 里的承诺复选框。
10. **打包冻结** —— `/stage-subm-packer`：build 和 lint 必须通过、走查检查单、依已注册的模板包把论文转成 venue 自己的版式、包放到 `wkdrs/builds/` 下、写出 `SUBMISSION_<date>.md`、打出标签 `freeze/<cycle>_<date>`。camera-ready 模式在 `tasks/<cycle>_promises.md` 还有未勾选项时拒绝打包。先跑 `/stage-subm-packer convert kit=<path>`，并按需要跑很多次——单独的转换跳过所有冻结关口，所以在论文还在压页数时照样能用。
11. **做海报** —— `/stage-pstr-builder`，录用之后：`plan` 挑出那一句核心结论和挣到墙面的 `verified` 论断，并记下砍掉了什么；`render` 生成 `cycls/<cycle>/poster/poster.tex` 并编译；闸按纸张已确认的物理尺寸核对有效字号，并拒绝 `\todo`。图从 `manus/figs/` 原样取用——要新图就退回 `/stage-figs-designer`。


## 证据、指纹与论断记录表

三条原则承载整个设计：

**A. 证据单向流动。** STAR 产物（或人工登记的文件）被快照进只读的 `mates/`，稿件只引用它们。数字住在上游：要改一个数字，去 STAR 改好再重新导入——绝不编辑 `mates/`。每个证据文件在 `mates/MANIFEST.md` 里都有一条记录：

```markdown
## proj/wkdrs/results/results.md
- source-type: star
- source: $STAR_HOME/wkdrs/results/results.md
- source-commit: 3f2a91c
- source-stamp: updated: 2026-07-28
- imported: 2026-08-02
- covers: main COCO and LVIS results for Tables 1–2
```

`source-stamp` 就是指纹：上游文件自己的 `generated:`/`updated:`/`finalized:` 日期。过期检测靠与上游当前值的精确比对（`import.sh --diff`），从不看文件 mtime——于是"论文脚下的数字变了"是一次机械检查，而不是一段记忆。

**B. 论断记录表是枢纽。** `notes/claims.md` 把每条论断的陈述位置 ⇄ 证据 ⇄ 状态连在一起：

```markdown
| ID | Claim | Type | Stated in | Evidence | Status |
|----|-------|------|-----------|----------|--------|
| C3 | +2.1 mask AP over X on LVIS | performance | `4_expts`, `tabs/main` | `mates/proj/wkdrs/results/results.md#lvis` | verified |
```

生命周期：`proposed`（故事提出）→ `drafted`（写进正文）→ `verified`（审计对上了证据）/ `unsourced`（写了但没有指纹——必须带 `\todo`）/ `weakened`（回复中让步）/ `dropped`（放弃）。故事播种论断，起草陈述论断，审计验证论断，回复捍卫论断：同一批行，一路走到投稿。

**C. 确定性检查放在脚本里，判断放在 skill 里。** grep 能抓的——未定义引用、`\todo` 标记、页数上限、匿名泄漏、过期的 stamp——由 `lint.sh` 和 `import.sh --diff` 抓，并可作为投稿闸门。散文模式扫描在约束力上是明确的例外：它用确定性规则定位高置信度残留或集中信号，但只给建议性警告，必须由人判断。需要判断的——这条论断真的成立吗、这张表是不是说明这个点的最佳方式、一个段落在上下文里是否公式化——住在 skill 里。

编造红线（规范 §9）把环闭上：`manus/` 里的每一个数字，要么可追溯到一条带指纹的 `mates/` 记录，要么写成 `\todo{...}`——没有第三种状态；关于被引论文的每个断言都必须能对上一份阅读笔记；venue 规则只以用户确认的事实录入；任何 skill 都不得"为了帮忙"而放松这些规则。

## 项目记忆

一次会话学到、又没有任何仓库文件认领的事实——某种构建引擎只在这台机器上能工作、你的某项长期偏好、模拟评审已经否决过的一种论述方式——记在论文的 `.stage/memory/`，而不是你当时在用的那个工具里。一事一文件；会话钩子从这些文件生成每条一行的索引，在每个受支持宿主的会话开头交给 agent。

记忆分四类：`env`（通常从失败中得知的机器或 TeX 工具链事实）、`pref`（你希望怎样写作）、`insight`（产生它的那次运行结束后仍然有效的判断）和 `deadend`（已经尝试、否决、不值得重试的路径——跨投稿周期尤其重要）。两条规则防止记忆库变成仓库事实的第二份漂移副本：

- **只有当没有任何文件已经认领这条事实时，才把它记进记忆。** 数字属于带指纹的 `mates/` 条目，论断属于 `notes/claims.md`，页数限制属于对应周期的 `venue.yml`，论文内容属于 `notes/refs/`，承诺属于 `tasks/`。记忆只装剩余信息。
- **记忆永远不是来源。** 它不能支撑 `manus/` 里的数字、venue 规则或关于被引工作的断言；记忆记得某个值，并不会放松禁止编造的边界。记忆与仓库文件冲突时，以文件为准。

只在本机成立的事实，以及你不想入库的记忆，放进 `.stage/memory/local/`，git 像忽略 `.env` 一样忽略它；其余记忆都受版本管理，随克隆一起走。`env` 条目超过 180 天未重新确认时，会在会话里标为过期。任何内容都先由 agent 提议、再由你决定是否记录；`.env` 设为 `INVOLVE=low` 时改为先记下再说明。文件格式、钩子生成的索引行以及记忆如何退场，见[项目记忆](docs/mds/stage-workflow/writing-workflow-conventions.md#12-project-memory)。

## 更新 STAGE 的 skill 与工作流文档

基于 STAGE 创建论文后，可以只同步 STAGE 后续发布的 skill 与写作工作流文档，而不改动你的稿件、证据、笔记或 Git remote：

```bash
bash execs/update.sh
```

该命令默认从 STAGE 的 `main` 分支更新以下路径：

- `AGENTS.md` 始终更新，选择 Cursor 时再更新 `.cursor/rules/`——它们分别是共享 agent 指令与 Cursor 的运行时镜像；所选路径中的本地改动会被替换，而包含 Cursor 的运行会让两份运行时副本一起移动
- `.agents/skills/` 与 `.agents/commands/` 优先，随后是 `.claude/skills/`、`.cursor/skills/`、`.dsh/skills/`、`.kimi-code/skills/`、`.pi/skills/` 与 `.qwen/skills/`——共用技能根和路由器，加六套原生技能树；安装进论文实例时会解引用链接
- `.codex/plugins/`——Codex 专属的 `$stage` 分流与 `$stage-auto` 目标运行插件，以及 marketplace 实体；`.agents/plugins/marketplace.json` 只是一条指向该 marketplace 的文件链接，绝不链接整个目录
- `.dsh/commands/` 与 `.kimi-code/plugins/`——DSH 和 Kimi 的 `/stage` 与 `/stage-auto` 包，各自只在选中对应宿主时更新
- 对应的钩子、command、prompt、agent 与 extension 目录，以及保存 Codex 逐 skill UI manifest 的 `.codex/skills/`；`.stage/memory/` 下的记忆库属于论文自己，从不同步
- `docs/mds/stage-workflow/`——工作流规约（项目记忆是其 §12，宿主钩子与模型溯源是其 §13）、skill 指南及其中文版
- `execs/run.sh`——构建入口；你对它的改动会被替换，而 skill 会按名字、按参数调用它，所以一个同步了 skill 却留着旧 `run.sh` 的仓库，会在构建那一步失败
- `execs/scpts/import.sh`、`execs/scpts/lint.sh`、`execs/scpts/fmt.sh`——三个工具脚本，理由同上：skill 按名字和参数调用 `import.sh --diff` 与 `lint.sh --no-build`，而读退出码的调用方，认的是它自己那一版写明的那套码。比某个工具脚本更老的 ref 会打印一行跳过它
- `execs/update.sh`——更新脚本自己，为的是不让任何仓库卡在一个老到取不回后继版本的更新机制上。它用重命名装上：执行更新的那一次仍读旧文件跑完，下一次调用才用上新的

拉取来源由 `STAGE_REPOSITORY` 指定，取值顺序为：环境变量、`.env`、内置默认值 `https://github.com/wanghao9610/STAGE.git`。想长期跟随某个 fork，就写进 `.env`；只想临时改一次，在命令前加变量即可——`STAGE_REPOSITORY=… bash execs/update.sh`。`.env` 里的其余内容从不同步——这也正是 `execs/` 下每个脚本都可以放心替换的原因：实例的配置不住在它们里面。`.env.example` 本身只在 `--adopt` 时进入项目，更新时从不带过去；所以模型键出现之前创建的项目，想用时要手工把 `STAGE_PLAN_MODEL`、`STAGE_EXEC_MODEL` 与 `STAGE_READ_MODEL` 加进自己的 `.env`——[上游的 `.env.example`](.env.example) 里有解释它们的注释；不加，它们什么都不改变。

要更新哪些 harness 树由 `STAGE_HARNESSES` 指定，取值顺序为环境变量、`.env`、默认 `all`。写 `STAGE_HARNESSES=codex` 就只维护 Codex 的 `.codex/`，也可从 `claude`、`codex`、`cursor`、`dsh`、`kimi`、`pi`、`qwen` 中任选多个并用逗号分隔；`none` 表示只更新共享骨架。未选中的树既不安装、不更新，也不删除；共享的 `.agents/skills/` 与 `.agents/commands/`、agent 指令、工作流文档和 `execs/` 脚本始终更新。

harness 配置——`.cursorignore`、`.claude/settings.json`、`.codex/hooks.json`、`.cursor/hooks.json`、`.pi/settings.json` 与 `.qwen/settings.json`——仅在缺失时安装，除非加 `--force`，否则绝不覆盖：论文仓库可能往这些文件里加过自己的设置。若保留下来的文件与上游有差异，命令会打印提示；若保留下来的钩子注册没有某个 STAGE 钩子，也会点名说明。

早于子代理钩子保留下来的 `.claude/settings.json` 缺两处，命令会逐一提示：一是 `SubagentStart` 块，提示里点名为缺失的 `SubagentStart delegate context` 钩子；二是模型 id 解析命令的放行规则，缺了它，子代理因为没法回答权限弹窗，`model_id` 只能记成 `unrecorded`。把两处都从上游文件抄进你自己的配置：那个块里的两条钩子命令，以及 `permissions.allow` 下的 `"Bash(bash .claude/hooks/stage_model_id.sh --resolve:*)"`。

更新脚本若仍点名某个上游已删除的路径，会在替换自己之前以 `Upstream ref is missing <path>` 中止。用下面这行手动取回当前版本并提交，再运行一次 `bash execs/update.sh`：

```bash
curl -fsSL https://raw.githubusercontent.com/wanghao9610/STAGE/main/execs/update.sh -o execs/update.sh
```

命令的两种通用形式为 `bash execs/update.sh [--diff] [ref] [--harnesses LIST] [--skill NAME] [--force]` 与 `bash execs/update.sh [ref] [--harnesses LIST] --adopt`：

```bash
bash execs/update.sh --diff
bash execs/update.sh TAG_OR_BRANCH
bash execs/update.sh --harnesses claude
bash execs/update.sh --skill stage-flow-status
```

- `--diff` 在不改动任何文件的情况下预览更新，有可更新内容时以 `2` 退出，完全一致时以 `0` 退出，出错时以 `1` 退出——脚本因此能区分“有更新”与“检查本身失败”。有差异的 harness 配置只列为保留、不计入数量，除非 `--force` 把它重新纳入范围。
- `ref` 把更新固定到某个 tag 或分支。
- 如果固定的 ref 早于 `.dsh/commands/` 或 `.kimi-code/plugins/`，普通更新与 `--adopt` 都会报告并跳过这个尚不存在的可选包；缺少其他必需路径仍会中止。
- `--harnesses LIST` 以逗号分隔的 harness 名称、`all` 或 `none` 覆盖本次运行的 `STAGE_HARNESSES`。未选中的树不在写入范围，也不纳入未提交改动检查。
- `--skill NAME` 只更新共用根与所选 harness 树中的这个 skill，不动 agent 指令、工作流文档和入口脚本。名称无效、或上游所选技能树缺少它，命令会停止且不覆盖任何文件。
- `--force` 更新同样这批路径，但解除两处拦截：这些路径下的未提交改动直接被覆盖而不再中止命令，harness 配置也改为覆盖而不再保留。它不扩大范围——你自己的、上游没有的文件依旧原样保留，你放在这些目录下的 skill 和文档不会丢。
- `--adopt` 把骨架装进一个已经存在的论文仓库，只复制缺失的文件（见[步骤 1b](#1b-或者接入一个已有的论文仓库)）；`--harnesses` 可限制安装哪些原生树。它不能与 `--force` 同用：绝不碰已有文件正是它的全部契约。

`bash execs/update.sh --help` 里有完整的用法摘要——选项变了它也跟着变，不会过期。

上游同路径文件会直接覆盖本地版本，上游新增文件也会被加入；更新范围内，仅存在于当前项目的自定义文件会保留。上游已不再提供的 STAGE 文件——上游 skill 旁的每个 `SKILL_zh.md`，以及 `execs/update.sh` 中 `RETIRED_FILES` 列出的已退役文件——会被删除（`--diff` 中显示为 `removes`）；其余只存在于本地的文件，包括你自己的，都会保留。STAGE 不再提供 `AGENTS.zh-CN.md` 与 `CLAUDE.zh-CN.md`：更新会保留你手上的这两个文件，若它们来自 STAGE，可自行删除。记忆钩子改为从每条记忆的 frontmatter 生成索引之前就建好的论文仓库，会留着它的 `.stage/memory/MEMORY.md` 与 `MEMORY.zh-CN.md`：已没有钩子读取它们，可以删除。更新不会修改其他目录、当前分支、Git remote 或暂存区——稿件、`mates/`、`notes/` 与 `cycls/` 从不在范围内。建议更新前提交当前工作，更新后使用 `git status` 和 `git diff` 检查并提交结果。

如果你改的是 STAGE 本身而不是某篇论文：只编辑 `.agents/skills/` 下工具中立的作者源，再用 `bash .github/scripts/port.sh --write` 重新生成六套 harness 技能树。仅属于某个 harness 的行为写进该树的 rules 或带锚点的 overrides。随后用 `bash .github/scripts/port.sh` 证明所有生成目录和共享链接仍然匹配，最后运行 `bash .github/scripts/check_consistency.sh` 核对七个根目录的语义约束。后两项检查都在 CI 中运行；这些命令只属于上游维护工具，`.github/` 不会同步进论文仓库。STAGE 自己的记忆无论作用域，一律放 git 忽略的 `.stage/memory/local/`：克隆或 GitHub 模板会原样复制受版本管理的 `.stage/memory/`，关于开发 STAGE 的记忆就会作为论文自己的事实出现在每个论文仓库里。`check_consistency.sh` 发现那里有模板所带 `.gitkeep` 之外的被跟踪文件就会失败。

## 项目约定

1. 稿件放在 `manus/`：入口是 `main.tex`，章节是 `secs/<n>_<slug>.tex`，图放 `figs/`（可编辑源在 `figs/srcs/`），表放 `tabs/`，参考文献是 `bibs/reference.bib`，模板层在 `stys/`。
2. 证据放在 `mates/`，且只读——`execs/scpts/import.sh` 与 `/stage-evid-curator` 是仅有的两个写入者。数字错了，去它的源头改再重新导入，绝不就地编辑证据文件。
3. 写作元数据放在 `notes/`：固定文件 `story.md`、`claims.md`、`outline.md`、`notation.md`、`style.md`、`adopt.md`，阅读笔记放 `notes/refs/`。
4. 投稿周期放在 `cycls/<venue>_<year>/`，venue 官方模板包整包解压进该周期的 `template/`；修订便签、承诺清单与 venue 跟进项放 `tasks/`。
5. 构建产物与临时报告放在 `wkdrs/`，永不提交；可留存的结论以 `notes/claims.md` 的状态翻转和 `tasks/` 条目写进文件，而不是报告文件。
6. 用 `execs/run.sh` 作为唯一构建入口，工具脚本放 `execs/scpts/`；运行环境路径从 `.env` 读取，不要在脚本里硬编码本机路径。
7. `manus/` 里的每个数字，要么可追溯到一条带指纹的 `mates/` 记录，要么写成 `\todo{...}`——没有第三种状态；写进文档的日期一律取自系统时钟。
8. 一次会话学到、而上面这些文件都不认领的东西，记进 `.stage/memory/`——先提议再写入，只对本机成立的和你不想入库的放 git 忽略的 `.stage/memory/local/`；记忆永远不为某个数字、某条会场规则、某句关于被引论文的断言充当来源。

完整的协作与写作规范见 [`AGENTS.md`](AGENTS.md) 与 [`docs/mds/stage-workflow/writing-workflow-conventions.md`](docs/mds/stage-workflow/writing-workflow-conventions.md)。

## 将 STAGE 用于新论文

基于 STAGE 开始写一篇新论文时，建议完成以下调整：

- 把 `manus/main.tex` 里的标题、作者、机构换成真实信息。双盲周期内保持匿名占位——`.env` 里 `ANON=true` 会让 `lint.sh` 在 `manus/` 下搜身份泄漏，注释也算。
- 复制 `.env.example` 为 `.env`，设好 `STAR_HOME`（不与 STAR 配对就留空）、`LATEX_ENGINE`、`ANON` 与可选的 `INVOLVE`、`STAGE_LANG` 以及模型键 `STAGE_PLAN_MODEL`、`STAGE_EXEC_MODEL`、`STAGE_READ_MODEL`。
- 用 `/stage-stry-coach` 建立第一个投稿周期和它的 `venue.yml`；页数上限、截止日期与检查单只以你确认的事实录入，绝不臆造。
- venue 官方模板包整包解压到 `cycls/<cycle>/template/`，不要放进 `manus/`——那是 `lint.sh` 扫描的目录树，模板包自带的示例 `.tex` 会污染 `\todo` 计数和身份扫描。
- 更新 `LICENSE` 中的年份和版权所有者。
- 替换 `docs/htmls/stage.html`、`docs/htmls/stage_zh.html` 与 `docs/srcs/`——它们是 STAGE 自己的落地页和图片，不属于你的论文。`docs/index.html` 和 `docs/index_zh.html` 是把这两个页面挂到站点根目录的软链接。两个页面之间的中英切换用的是绝对链接（`/STAGE/index_zh.html`），要把其中的 `/STAGE` 前缀改成你自己的仓库名，否则语言切换会失效。`docs/mds/stage-workflow/` 保持不动，`execs/update.sh` 会负责更新它。
- 安装进论文实例后，每个所选宿主都是自包含的。直接检出模板时，具名目录可能把共用文件链接到 `.agents/skills/`，所以删除共享根目录前要先把准备保留的目录实体化；使用 Codex 时必须同时保留 `.agents/`，每个宿主自己的钩子和配置文件也要随它的 skill 一起保留。`execs/update.sh` 安装时会自动写成实体文件。

骨架本身可独立使用：目录布局、`.env`、`execs/run.sh` 与 `execs/scpts/lint.sh` 在完全不装任何 skill 的情况下也能工作，因此删掉全部工具目录同样是受支持的用法。一篇论文一个仓库——第二篇论文是模板的第二个实例，而不是这里的第二棵目录树。

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
