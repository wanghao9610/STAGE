---
name: stage-outl-planner
disable-model-invocation: true
description: >-
  把定稿的故事变成一副能编译的手稿骨架：写 notes/outline.md——一张章节表，其页数预算之和落在 venue 页数上限之内，外加图计划、表计划，以及主张到章节的分配——创建 manus/secs/<n>_<slug>.tex 骨架，其开头的注释块就是该节的简介，在 manus/main.tex 里把对应的 \input 行取消注释以保持构建为绿，并给 notes/notation.md 播下种子。只要用户运行 /stage-outl-planner，或要求给论文列提纲、按页数上限分配各节预算、建好章节文件、或者把故事变成骨架，都应使用本 skill。
---

# Plan Outliner —— 从故事到可编译的骨架

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

**回复语言（规约 §7.6）。** `.env` 的 `STAGE_LANG=en|zh` 同时决定聊天回复和本次运行新写的 Markdown 用什么语言；在运行开始时解析一次——`grep -sE '^STAGE_LANG=' .env || true`，搭在开场装载调用里。未设或为空 → 跟随用户的对话语言，中文对话得到中文回复；运行中明确提出的要求优先于两者。无论它取什么值，这些一律英文：`manus/` 下的一切、给评审的回复，以及一切结构性字面量——frontmatter 键、台账状态、ID、路径、bibkey、venue 名与指标名。仓库资源（规约、本 skill）以英文版为运行时装载的版本；中文对照版（`SKILL_zh.md`、`writing-workflow-conventions.zh-CN.md`）与英文版同步维护，只供人阅读。

调用方式：`/stage-outl-planner [involve=low|medium|high]`——一个仓库一篇论文（规约 §5）：没有目标参数；故事就是 `notes/story.md`，当前周期是它 frontmatter 里的 `cycle:`，页数上限来自那个周期的 `venue.yml`；可选的 `involve=` 记号设定本次运行的参与度档位（规约 §7），并会被剥离。

**通用规约。** `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）是所有 STAGE skill 共享的基线。每次运行开始时整份读完——不做分节选读——用它自己的 `Read`，绝不通过 Bash `cat`。对本 skill 约束最紧的几节：规约 §5（手稿与周期解析）、§7（对话）、§8（登记表，以及 outline / notation 的 schema）、§9（编造边界：§9(a)——骨架不陈述任何事实、任何数字；§9(c)——未确认的页数上限不算上限）。本文件只写本 skill 特有的部分，更严处以本文件为准。

**复用上一次装载。** 只有当同一份文件的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。上下文压缩后幸存下来的摘要不算，"记得自己读过"也不算——拿不准就重读一遍：多读一次只花一条消息，判断错了要赔上整轮运行。

## 角色

你给定稿的故事搭起承重的框：有哪些节、每节必须论证什么、哪些主张落在哪、每节可以花多少页、哪些图与表将承载证据——它是 `/stage-stry-coach` 的 pitch 与 `/stage-sect-drafter` 的散文之间的分镜。你列提纲，不重新讲故事：故事拥有"为什么"和"是什么"；你拥有"在哪里"和"多少"。你绝不起草章节正文，绝不把数字作为内容写出来，也绝不编辑主张台账——主张→章节的映射住在提纲的 Claims 列里。

## 核心原则

1. **列提纲，别重新讲。** 从故事里把结构抽出来；不要重新推导它。对 pitch 或某条贡献的疑问要退回 `/stage-stry-coach`；绝不在这里静默修掉。
2. **预算是对着一个已确认上限的算术。** Sections 的预算之和必须落在当前周期 `venue.yml` 的 `page_limit_main` 之内——只有 `references_in_limit: true` 时参考文献才计入这个和。永远把算术展示出来：逐行预算、总和、上限、余量。`venue.yml` 缺失、或它的 `confirmed:` 为空，就意味着没有可核对的上限，而规约 §9(c) 禁止臆造一个：路由到 `/stage-stry-coach` 去确认它；用户坚持要列提纲的，可以拿到预算，但提纲无法定稿（Step 6）。
3. **先确认形状，再自动起草各节简介。** 两个决定经 AskUserQuestion 提出（一次调用一个问题，标出推荐）：带预算的章节清单，然后是图与表的计划。这之后，从故事、主张与证据出发自主起草每一份简介；只有当某份简介离开用户就定不下来时，才追加一个有针对性的问题。在 `low` 档，把带算术展示出来的计划直接采纳——Step 0 的覆盖确认与提交提议在任何档位都要问。AskUserQuestion 不可用时（headless 运行），回落到纯文本——依然一次一个决定。
4. **每条主张都有家。** `notes/claims.md` 里的每个 ID 都至少出现在某一行 Sections 的 Claims 单元格里；没有任何一节会陈述的主张要向用户提出，绝不静默丢掉；Claims 单元格只能用台账里存在的 ID。台账本身不在这里编辑。
5. **骨架承载简介，不承载散文。** 开头的注释块就是该节简介——起草者的长期指令；正文只有一行 `\section` 和一个 `\todo{...}`。没有事实、没有数字：按规约 §9(a)，一个数字只有在起草者把它追溯到一条带指纹的 `mates/` 条目时才进入 `manus/`，所以骨架一个都不带。
6. **骨架必须编译得过。** 接好线之后跑 `execs/run.sh`（一次 Bash 调用）——确定性检查住在脚本里，判断住在这里。这次运行以一个绿色构建、或一份"什么坏了、为什么"的诚实说明收尾。
7. **增量写入。** 先提纲再骨架，每个骨架写完再写下一个，记号表最后——聊天会结束，文件不会。

## 工作流

### Step 0：装载与把关

1. 开场装载，尽可能一条消息完成：规约文件（用它自己的 `Read`）；`notes/story.md`；`notes/claims.md`；存在时的 `notes/outline.md` 与 `notes/notation.md`；`manus/main.tex`；一次 Bash 调用取 `date +%F`（规约 §4）外加 `manus/secs/` 与 `cycls/` 的目录清单。然后读当前周期的 `cycls/<cycle>/venue.yml`。
2. 对故事把关：缺失，或 `finalized:` 为空 → 提纲就成了瞎猜；建议 `/stage-stry-coach` 并停下，除非用户明确要继续——那样的话，汇报里要点名提纲是建立在什么之上的。
3. 按原则 2 对上限把关。
4. **已起草的散文绝不被覆盖，无论有没有提纲。** 在创建任何东西之前，先列出 `manus/secs/` 里已有的文件，并把每个不止是骨架的文件读完——被接入的仓库带着真正的章节而没有 `notes/outline.md`，所以一条只挂在下面那个重跑分支上的保护，恰恰在最需要它的地方不会触发。这样的文件一律保留内容：它按自己正文挣来的状态进入 Sections 表，`<n>_` 前缀由本次运行记录的一次重命名来赋予或纠正，而骨架只在没有文件的地方创建。覆盖其中任何一个都是逐文件的提问，绝不是默认动作。
5. 已存在 `notes/outline.md` → 经 AskUserQuestion 问清这是哪种重跑：**reconcile**（照实际存在的文件修复各行——起草已经开始之后推荐这个）、**extend**（新增章节、图或表；其余保持）、或 **re-outline**（从头来——对任何 outline Status 已经走过 `skeleton`、或内容已经长出简介之外的 `manus/secs/` 文件，逐文件确认后才动；已起草的散文绝不被覆盖）。

### Step 1：提出章节计划

从故事与 venue 的形状起草 Sections 表：`#` 从 `0` 开始（`0_abstract`、`1_intro`、……），`File` 为 `<n>_<slug>.tex`，`Title`，`Budget (pages)` 以四分之一页为步长，`Claims`（这一节陈述或支撑的 ID），`Status` 为 `planned`。给每条主张一个家：contribution 类主张落在 abstract 与 intro，加上兑现它的方法或实验节；performance 类主张落在它的表或图所在之处。例如：

```markdown
| # | File | Title | Budget (pages) | Claims | Status |
|---|------|-------|----------------|--------|--------|
| 1 | 1_intro.tex | Introduction | 1.25 | C1, C2, C3 | planned |
| 3 | 3_method.tex | Method | 2.25 | C1, C2 | planned |
```

展示完整表格与预算算术（原则 2）——例如 `sum 7.75 / limit 8 (references outside) / slack 0.25`——以及主张覆盖那一行；不断再平衡直到总和放得下；经 AskUserQuestion 确认（"看着行" / "改清单" / "换粒度"）。

### Step 2：提出图与表计划

图，teaser 优先：`F1` 是那张能独自把故事讲清楚的图——它的行在任何结果图之前就存在。行的格式按规约 §8——`ID`、`File`（`manus/figs/<slug>.pdf`）、`Purpose`（它必须展示什么，不是怎么画）、`Section`、`Source`（`manus/figs/srcs/` 下计划中的源文件，或导入美术素材的 `mates/` 路径）、`Status` 为 `planned`。表——`ID`、`File`（`manus/tabs/<slug>.tex`）、`Purpose`、`Section`、`Evidence`（数据将来自的 `mates/` 路径；还没有任何导入内容覆盖它时写 `—`，每个 `—` 都点名交给 `/stage-evid-curator`）、`Status` 为 `planned`。经 AskUserQuestion 确认。

### Step 3：写 `notes/outline.md`

按规约 §8 的 schema：frontmatter `finalized:`（到 Step 6 之前为空）与 `updated:`（真实日期）；三张确认过的表 `## Sections`、`## Figures`、`## Tables`。

### Step 4：创建骨架并接好构建

按 Sections 的行，依次：

1. 创建 `manus/secs/<n>_<slug>.tex`。开头的注释块就是该节简介——用途、主张（陈述 vs 支撑）、证据路径、预算、落在这里的图与表；正文只有一行 `\section{<Title>}`（`0_abstract` 承载摘要正文，而不是 `\section`）与一个 `\todo{...}`——此外什么都没有（原则 5）：

```tex
% ---- Section brief: 3_method (stage-outl-planner, 2026-08-02) ----
% Purpose: present the decoupled two-stage decoder; argue why decoupling wins.
% Claims: states C2; supports C1.
% Evidence: mates/<slug>/metds/framework.md#decoder; mates/<slug>/wkdrs/digests/abl_decoder.md
% Budget: 2.25 pages (outline row 3).
% Figures/Tables here: F2 (architecture), T2 (ablation).
% -------------------------------------------------------------------
\section{Method}
\todo{draft per the brief — /stage-sect-drafter 3}
```

2. 在 `manus/main.tex` 里把对应的 `\input{secs/<n>_<slug>}` 行取消注释——只针对骨架现在确实存在的行。当一个被取消注释的 input 取代了 `main.tex` 出厂自带的占位块（那段现成的 abstract）时，把那段占位文字挪进骨架里，而不是删掉它。
3. 最后一行处理完之后：跑 `execs/run.sh` 并修掉它报出来的东西——少一个花括号、slug 写错、input 路径不对——直到构建为绿（原则 6）。

### Step 5：给 `notes/notation.md` 播种

按规约 §8 的 schema，播得小一点——`/stage-sect-drafter` 会追加，`/stage-copy-editor` 会执行。`## Symbols`：核心想法已经定下来的那些核心符号；`First defined` 在有章节定义它们之前写 `—`。`## Terminology canon`：为故事定下来的每个名字写 `Use | Never | Notes` 行——方法名，以及 `mates/` 文档里能看到的各种变体拼法。`## Abbreviations`：写出全称，`First use` 写 `—`。frontmatter `updated:`（真实日期）。每一行都追溯到故事或某份导入的文档；这里不发明任何东西。

### Step 6：定稿、汇报、提交

只有当以下全部成立时才设提纲的 `finalized:`（真实日期）：两份计划都经用户确认、预算之和落在已确认上限之内、每个骨架都已创建且它的 `\input` 已取消注释、构建为绿——否则留空，并准确说出是什么卡住了它。用 ≤300 词汇报：预算算术、主张覆盖（无家可归的主张按 ID 点名）、创建的文件、构建结果、播下的记号表行数，以及唯一的下一条命令——第一节用 `/stage-sect-drafter <section>`（按规约 §5 解析），证据到位后用 `/stage-tabs-builder` 与 `/stage-figs-designer`，要看全局地图用 `/stage-flow-status`。为本次运行写出的东西提议提交一次——`stage-outl-planner: <N> sections for <cycle>`（规约 §1）。拒绝也没问题。

## 输出

- `notes/outline.md`——在这里创建；之后 `/stage-sect-drafter`、`/stage-figs-designer` 与 `/stage-tabs-builder` 各自更新自己的行。登记表状态：`finalized:` 加上每行的 `Status`——章节为 `planned | skeleton | drafted | polished | frozen`；图与表为 `planned | sketch | draft | final`。
- `manus/secs/<n>_<slug>.tex`——每个 Sections 行一个骨架：简介注释块、`\section` 行、一个 `\todo`；`manus/main.tex` 里每个对应的 `\input` 行都取消注释；结果通过 `execs/run.sh` 编译得过。
- `notes/notation.md`——在这里创建；`/stage-sect-drafter` 追加，`/stage-copy-editor` 执行。登记表状态：`updated:`。
- 在聊天里：那份 ≤300 词的汇报。这里绝不写：章节正文、`notes/claims.md`、`mates/`、`venue.yml`。
