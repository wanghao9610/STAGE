---
name: stage-tabs-builder
description: >-
  只从带指纹的 mates/ 证据出发，在 manus/tabs/ 下生成或更新一张 booktabs 表格——绝不来自记忆、聊天或回想起来的论文。每个数据行都带一条 % src: mates/<...>#<anchor> 注释，好让每个数字都能追溯到它的指纹；缺失的数字变成一个 \todo{...} 单元格，并在 notes/claims.md 里开出一条 unsourced 主张——手敲进去的数字正是本 skill 存在要杀掉的失败模式。每个被引用的数字在发出去之前都重读一遍，把证据过期问题浮出来，并更新提纲的 Tables 行与主张台账。只要用户运行 /stage-tabs-builder、一次运行点名它是下一步动作，或要求建立、填充、扩展或修复一张结果表、消融表或对比表，或者把导入的结果变成 LaTeX，都应使用本 skill。
argument-hint: "[TABLE]"
allowed-tools: >-
  Read, Grep, Glob, Write, Edit, Bash(bash execs/run.sh:*), Bash(execs/run.sh:*),
  Bash(bash execs/scpts/lint.sh:*), Bash(execs/scpts/lint.sh:*),
  Bash(bash execs/scpts/import.sh:*), Bash(execs/scpts/import.sh:*), Agent, Bash(git status:*),
  Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*)
---

# Table Builder —— 从证据到 booktabs 的编译器

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

**回复语言（规约 §7.6）。** `.env` 的 `STAGE_LANG=en|zh` 同时决定聊天回复和本次运行新写的 Markdown 用什么语言；在运行开始时解析一次——`grep -sE '^STAGE_LANG=' .env || true`，搭在开场装载调用里。未设或为空 → 跟随用户的对话语言，中文对话得到中文回复；运行中明确提出的要求优先于两者。无论它取什么值，这些一律英文：`manus/` 下的一切、给评审的回复，以及一切结构性字面量——frontmatter 键、台账状态、ID、路径、bibkey、venue 名与指标名。仓库资源（规约、本 skill）以英文版为运行时装载的版本；中文对照版（`SKILL_zh.md`、`writing-workflow-conventions.zh-CN.md`）与英文版同步维护，只供人阅读。

调用方式：`/stage-tabs-builder [TABLE] [involve=low]`——`TABLE` 按 ID（`T2`）、文件 slug（`main_results`）或用途短语，对着 `notes/outline.md` 的 Tables 表匹配，§5 的匹配方式套用到 Tables 行上；缺失或有歧义时，列出各行及其状态并提问（§7）。还不在提纲里的表格，在参数里描述它，先给它一行提纲行。一次调用一张表。这里没有独立的描述位：自由文本本身就是这张表的描述——用途短语正是这样解析出 Tables 行的，还没有行的表也正是这样说出来的——所以规约 §7.13 说的那句描述*就是*这个参数，不再从中剥出别的东西。它说明这张表是干什么的；它绝不提供任何一格里的内容，那些要么来自本次运行读过的、带指纹的 `mates/` 条目，要么写成 `\todo{...}`。参数后面可以跟一个可选的 `involve=low|medium|high` 记号：它设定本次运行的 involve 档位（规约 §7.7），不属于参数，在参数被读取之前就被剥离。

**通用规约。** 动手之前先读 `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）——整份读，每次运行开始时；不做分节选读。它通过自己的 `Read` 调用到达，绝不被 `cat` 进一条 Bash 命令。它是所有 STAGE skill 共享的基线；对本 skill 约束最紧的是 §9（编造边界——本 skill 就是它在表格层面的执行者）、§8（产物登记表及其过期规则）、§5（解析）。本文件只写本 skill 特有的部分，更严处以本文件为准。

**复用上一次装载。** 同一轮对话里的第二个 STAGE skill 不必为此付两次：只有当同一份文件的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。上下文压缩后幸存下来的摘要不算，"记得自己读过"也不算。拿不准就重读一遍——多读一次只花一条消息，判断错了要赔上整轮运行。

## 角色

你是一个编译器，不是打字员：`mates/` 证据进去，一张 booktabs 表格出来，而每个数据行都带着那条 `% src:` 注释，让 `/stage-clms-auditor` 在你不在场的情况下也能从单元格走到指纹。上游，`/stage-evid-curator` 导入并登记 STAR 产出的或手工投放的东西；你只读它。把一个数字手敲进表格——从聊天里、从记忆里、从你想起来的一篇论文里——正是本 skill 存在要杀掉的失败模式。

你建表格；你不去找证据来源、不去论证散文、也不从零设计对比：没有 `mates/` 条目的数字是一个 `\todo{}` 单元格加一次路由，不是一次敲键。

表格比较哪些方法与哪些指标，归提纲那一行以及它宿主章节的论证所有——超出这个范围的重塑要退回 `/stage-outl-planner`。你绝不编辑 `mates/`，并且只写 `manus/tabs/` 下的东西，外加下面那两个登记项。

## 核心原则

1. **每个单元格要么可追溯、要么是 todo——没有第三种状态（§9a）。** 一个数据单元格，要么带着本次运行从它所在行 `% src:` 注释点名的那个 `mates/` 文件里读到的数字，要么是点名缺哪次测量的 `\todo{...}`。不适用的单元格写 `—`，理由写在该行注释里。数据单元格里不得出现别的东西。
2. **`mates/` 是唯一的数字来源。** 聊天不是证据，记忆不是证据，而一篇已发表论文的数字在被登记之前也不是证据：来自文献的 baseline 行要经 `mates/manual/` 加一条 MANIFEST 条目进来（路由到 `/stage-evid-curator`），这样连"众所周知"的数字也有指纹可审。用户口述一个数字时，给他这条登记路径，绝不直接落进单元格。
3. **一个 todo 单元格开出一条主张。** 每个 `\todo{}` 单元格都会在 `notes/claims.md` 里新增（或翻转）一行到 `unsourced`，Evidence 为 `—`——这个缺口从此对 `/stage-flow-status` 与 `/stage-clms-auditor` 是可见的工作，而只要还有 `\todo` 残留，`execs/scpts/lint.sh` 就把手稿卡在关口。这个 todo 单元格就是 `unsourced` 状态所要求的那个"带着的 `\todo`"。
4. **加粗是一种主张。** 把最好的数字高亮出来，就是在陈述一条性能主张：只有在被引用的证据支撑这个对比时才加粗或加下划线，并确保有一条台账行以 `tabs/<slug>` 出现在 Stated in 里覆盖它。在一列 `\todo{}` 之上标最优，是用排版做的编造。
5. **排版之前先查过期（§8）。** 通过 `execs/scpts/import.sh --diff` 把被引用条目的 `source-stamp:` 与上游比对——逐字比对，绝不看 mtime。过期的证据要报出来、并在它的数字发出去之前（经用户批准）重新导入；要修一个错的数字，就到上游修好再重新导入——不在 `mates/` 里修，也不只在表格里修。
6. **booktabs，可 grep。** `\toprule`/`\midrule`/`\bottomrule`，不要竖线；一个源码行一个数据行，好让每条 `% src:` 注释正好挨着一行；caption 与列头陈述设置类事实——数据集、划分、指标——只按证据所述来写，并用 `notes/notation.md` 的术语。

7. **证据采集并行分派（§6）。** Step 2 要从留了指纹的 `mates/` 文件里给每个单元格取一个数：一张表背后不同的文件超过 6 个 → 一个文件一个委派者，各自返回自己那些锚点处的值与锚点原文的引文，别的什么都不返回。表在这里生成，因为一个 `.tex` 文件只有一个写入者（§6.2），而一行的 `% src:` 注释与它那个数字是由写这一行的人一起写下的（§6.4）。过期比对是一次 `import.sh --diff` 调用，Step 5 出货前那次重读是关卡——两样都在这里跑（§6.3）。

## 工作流

### Step 0：装载

1. 读规约文件（整份，用它自己的 `Read` 调用），然后读 `notes/outline.md`（Tables 与 Sections）、`notes/claims.md`、`notes/notation.md`、`notes/story.md`（当前 `cycle:`）与 `mates/MANIFEST.md`。
2. `mates/` 为空意味着没有可以据以建表的东西：停下并路由到 `/stage-evid-curator`（有配对 STAR 仓库时是 `execs/scpts/import.sh`）——本 skill 不靠承诺开表。

### Step 1：解析表格

1. 把 `TABLE` 依次按 ID、文件 slug、用途短语对着 Tables 行匹配；缺失或有歧义 → 列出各行及状态并经 AskUserQuestion 提问（不可用时用纯文本）。
2. 尚未计划的表格，用一个问题把 {ID、文件 slug、用途、宿主章节、证据} 一次定下来，并在动手之前追加提纲 Tables 行（`planned`）。
3. 修订时，整份读完已有的 `manus/tabs/<slug>.tex`，包括它当前的 `% src:` 注释——那是上一次运行的证据地图。

### Step 2：收集证据

1. 顺着提纲行的 Evidence 列与台账的 Evidence 链接进 `mates/`；读每个被引用的文件及其 MANIFEST 条目（`source-type:`、`source-stamp:`、`imported:`、`covers:`）。
2. 跑 `execs/scpts/import.sh --diff`；报出被引用条目上的漂移，并在它们的数字被排版之前提议重新导入。
3. 把每一个打算要的行与列都映射到一个带锚点的具体数字——证据文件里最近的标题或行键，精确到足以让 `/stage-clms-auditor` 不用猜就能找到这个数字。能被诚实展示出来的表，取决于这张地图，而不是提纲的愿望。

### Step 3：设计并预告缺口

1. 定死布局：列来自宿主章节所论证的那个对比、指标名与缩写按 `notes/notation.md`、分组规则（方法族之间加 `\midrule`）、以及按原则 4 判断最优标记用在哪。
2. 在输出之前先说清哪些单元格会是 `\todo{}`，每一个都说明缺什么、它该从哪来。一张大半会是 todo 的表要改走路由：上游已经有的证据交给 `/stage-evid-curator`，从来没跑过的测量交给配对 STAR 仓库自己的工作流——本 skill 交付的是表格，不是 todo 格栅。

### Step 4：输出 `manus/tabs/<slug>.tex`

1. 一个 `table` 浮动体：booktabs 骨架、`\centering`、说明这张表展示什么以及它取自证据的设置事实的 caption、`\label{tab:<slug>}`。
2. 一行一个数据行；每行正上方是它的 `% src: mates/<slug>/...#<anchor>` 注释——一个数据行一条注释，不许共用、不许笼统。`\todo{...}` 单元格按 Step 3 点名；`—` 单元格在该行注释里说明理由。
3. 精度：单元格可以把证据取值四舍五入到全表统一的精度——`% src:` 锚点仍能取回原值——但绝不展示超出证据所带的精度；求平均或以其他方式派生新数字，属于 `/stage-evid-curator` 的规范化（在证据旁边做，并带指纹），绝不是单元格这一侧的编辑。
4. 表头行可以用 `\multicolumn`；数据行绝不合并——一条 `% src:` 注释正好覆盖一行，而一个合并的数据行会把这条踪迹弄糊。
5. 表格要从它的宿主章节被引用（`\input{tabs/<slug>}` 或 `\ref{tab:<slug>}`）；这个挂钩缺失时，报出来交给 `/stage-sect-drafter`——本 skill 不在 `manus/secs/` 里写字。

### Step 5：发出去之前先核验

1. 把每个被引用的 `mates/` 文件在它的锚点处重新打开，与输出的单元格逐个数字比对——表格里一个错的数字会被引进评审与 rebuttal 里。对不上 → 照文件修好，或把该单元格降级为 `\todo{}`。绝不在不重读的情况下信任 Step 2 的地图。
2. 检查输出的 tex 在上下文里编译得过：提议跑一次 `execs/run.sh` 构建。

### Step 6：更新各登记项

1. `notes/claims.md`：表格陈述的 performance 主张在 Stated in 里加上 `tabs/<slug>`，并把 `proposed` → `drafted`；每个 `\todo{}` 单元格一行 `unsourced`（Evidence 为 `—`）；更新 `updated:`（真实日期，§4）。
2. `notes/outline.md`：Tables 那一行 → `draft`（todo 占多数时为 `sketch`）；更新 `updated:`。

### Step 7：汇报与提交

1. 汇报：有来源的单元格 vs `\todo{}`（计数与文字）、读过的证据文件及其时间戳、过期发现、动过的台账行、施加的最优标记及覆盖它们的主张。建议下一步：用 `/stage-clms-auditor` 验证这些数字、用 `/stage-sect-drafter` 写表格周围的散文、用 `/stage-evid-curator` 补还缺的东西。
2. 按 §1 提交：一个工作会话一次提交——表格、台账、提纲一起——标题点名 skill（`stage-tabs-builder: main_results`）。绝不提交 `wkdrs/`。

## 输出

- `manus/tabs/<slug>.tex`——那张 booktabs 表格；它的状态字段是每个数据行的 `% src:` 注释与 `notes/outline.md` 里的 Tables 行（登记表：Tables）。
- `notes/claims.md`——被陈述的 performance 主张（`drafted`）；每个 `\todo{}` 单元格一行 `unsourced`。
- `notes/outline.md`——Tables 行的状态与 `updated:`。
- 聊天汇报：有来源/todo 的单元格计数、读到的时间戳、过期发现、台账增减，以及建议的下一个 `/stage-*` 步骤。除这些文件之外什么都不写。
- 溯源（规约 §8）：本次运行写进 `notes/`、`tasks/`、`cycls/`、`wkdrs/reports/` 的每份产物都带 `model_id:`——本次会话的模型 id，原样抄录——并追加一条本次运行的 `model_trail:` 条目。`manus/` 与 `mates/` 下的一切两者都不带，`cycls/<cycle>/venue.yml` 也不带。
