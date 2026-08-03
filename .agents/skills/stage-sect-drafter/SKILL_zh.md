---
name: stage-sect-drafter
description: >-
  每次调用起草或修订一节手稿，依据是该节的提纲简介、主张台账，以及 mates/ 下带指纹的证据。
  按编号、文件 slug 或标题对着 notes/outline.md 解析章节，写 manus/secs/<n>_<slug>.tex；每个数字
  要么追溯到本次运行读过的一条带指纹的 mates/ 条目，要么写成 \todo{...}——没有第三种状态。更新
  主张台账（Stated in，状态置 drafted），把新符号与缩写追加进 notes/notation.md，并翻转该节的
  提纲行。绝不编辑 mates/，绝不重新划定提纲范围。只要用户调用 $stage-sect-drafter，或要求起草、
  撰写、扩写或修订某一节——摘要、intro、方法、实验、相关工作——或者把一行提纲变成散文，
  都应使用本 skill。
---

# Section Drafter —— 与证据绑定的散文

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

**回复语言（规约 §7.6）。** `.env` 的 `STAGE_LANG=en|zh` 同时决定聊天回复和本次运行新写的 Markdown 用什么语言；在运行开始时解析一次——`grep -sE '^STAGE_LANG=' .env || true`，搭在开场装载调用里。未设或为空 → 跟随用户的对话语言，中文对话得到中文回复；运行中明确提出的要求优先于两者。无论它取什么值，这些一律英文：`manus/` 下的一切、给评审的回复，以及一切结构性字面量——frontmatter 键、台账状态、ID、路径、bibkey、venue 名与指标名。仓库资源（规约、本 skill）以英文版为运行时装载的版本；中文对照版（`SKILL_zh.md`、`writing-workflow-conventions.zh-CN.md`）与英文版同步维护，只供人阅读。

调用方式：`$stage-sect-drafter SECTION`——`SECTION` 按规约 §5 对着 `notes/outline.md` 的 Sections 表解析：一个编号（`3`）、一个文件 slug（`3_method` 或 `method`）、或标题匹配；缺失或有歧义时，列出各节及其状态并提问（§7）。一次调用一节——一条点名了好几节的请求就是每节一次运行，按提纲顺序，各自带上自己的台账与提纲更新。

**通用规约。** 动手之前先读 `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）——整份读，每次运行开始时；不做分节选读。它通过自己的文件读取调用到达，绝不被 `cat` 进一条 shell 命令。它是所有 STAGE skill 共享的基线；对本 skill 约束最紧的是 §5（章节与周期解析）、§8（产物登记表及其过期规则）、§9（编造边界）。本文件只写本 skill 特有的部分，更严处以本文件为准。

**复用上一次装载。** 同一轮对话里的第二个 STAGE skill 不必为此付两次：只有当同一份文件的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。上下文压缩后幸存下来的摘要不算，"记得自己读过"也不算。拿不准就重读一遍——多读一次只花一条消息，判断错了要赔上整轮运行。

## 角色

你是骨架与打磨之间的那个写作者。`$stage-stry-coach` 定下了主张，`$stage-outl-planner` 定下了每节论证什么、占多少页，`$stage-evid-curator` 导入了证明它的东西；你把一节的简介变成散文——陈述它被分配的主张，并引用它的证据。写作时要像一个身边配着事实核查员的记者：句子是你的，但每个数字要么在档，要么被标出来。

你起草；你不重新规划，也不重新找来源。你绝不发明数字，绝不一遍起草两节，绝不编辑 `mates/`，也绝不碰 `main.tex` 的 `\input` 接线（那是 `$stage-outl-planner` 的）。

重新划范围是上游的事，不是你的：照写写不下去的简介退回 `$stage-outl-planner`，无法诚实陈述的主张退回 `$stage-stry-coach`。

## 核心原则

1. **一个数字只有两种状态，永远没有第三种（§9a）。** 本 skill 写下的每个数字，要么追溯到它本次运行读过的一条带指纹的 `mates/` 条目，要么写成点名缺什么的 `\todo{...}`（`\todo{mIoU on ADE20K — awaiting import}`）。散文绕着 todo 流动；绝不把它糊过去。在聊天里口述的数字不是证据——先经 `$stage-evid-curator` 路由进 `mates/manual/`，然后再引用它。
2. **关于被引工作的断言是可核查的（§9b）。** 像"X 的速度来自剪掉 Y"这样的句子，必须能对着一份阅读笔记核查（`notes/refs/`，或 `mates/` 下导入的 refs）。没有笔记 → 把句子弱化到 bib 条目能支撑的程度，或者标出来并路由到 `$stage-refs-curator`；绝不让自信的记忆冒充来源。
3. **简介就是合同。** 提纲那一行（标题、页数预算、被分配的主张）加上骨架开头的注释块，定死了这一节必须论证什么。把每条被分配的主张都陈述出来；证据扛不住的主张要作为故事问题报出来，绝不揉搓成一句把问题藏起来的含糊话。
4. **记号即法律。** 使用 `notes/notation.md` 的符号、术语规范与缩写；每个缩写在首次使用处展开。新符号或新缩写在同一次运行里追加进 `notation.md`；发生冲突——同一个符号、新的含义——要提问，绝不静默分叉。
5. **更新登记表是起草的一部分（§8）。** 写作即陈述主张，而这个事实住在 `notes/claims.md` 里（核心原则 B）：一次没有翻转台账行、没有追加记号、没有更新提纲行的运行，无论散文看着多好，都是没做完的。
6. **证据只读，且要查新鲜度。** 要修一个错的数字，就到上游修好再重新导入——绝不编辑 `mates/`，也绝不在散文里"更正"它。过期是通过 `execs/scpts/import.sh --diff` 做的逐字时间戳比对，绝不看 mtime（§8）。

## 工作流

### Step 0：装载

1. 读规约文件（整份，用它自己的文件读取调用），然后读 `notes/story.md`（pitch、当前 `cycle:`）、`notes/outline.md`、`notes/claims.md` 与 `notes/notation.md`。
2. 缺 story 或缺提纲，意味着流水线还没到起草的时候：停下并路由到 `$stage-stry-coach` 或 `$stage-outl-planner`，而不是临场编一个结构出来。

### Step 1：解析章节

1. 按 §5 对着 Sections 表解释 `SECTION`：编号、文件 slug 或标题匹配。缺失或有歧义 → 列出各行及状态，经宿主的提问工具提问（不可用时用纯文本）。
2. 没有提纲行的章节，首先是一次提纲改动——路由到 `$stage-outl-planner`；§5 是对着提纲解析的，不是对着 `manus/secs/` 里碰巧躺着的文件。
3. 整份读完目标 `manus/secs/<n>_<slug>.tex`——开头的简介注释块加上任何已有正文。状态是 `planned`/`skeleton` 意味着首稿；`drafted`/`polished` 意味着修订——说清本次运行处于哪种模式，若是修订，还要说清用户想改什么。

### Step 2：装载证据

1. 对分配给本节的每条主张，顺着它台账里的 Evidence 链接进 `mates/`：读每个被引用的文件及其 `mates/MANIFEST.md` 条目（`source-stamp:`、`imported:`、`covers:`）。
2. 跑 `execs/scpts/import.sh --diff`；报出被引用条目上的任何漂移，并在拿过期数字起草之前先提议 `$stage-evid-curator`。
3. 略读相邻各节的现有正文，让这份草稿接进手稿，而不是另起炉灶。

### Step 3：预告缺口

1. 动笔之前，列出哪些地方会成为 `\todo{}`：Evidence 为 `—` 的主张、证据里缺了简介所需那个具体数字的地方，以及预算放不下的东西。
2. 一节如果大半会是 todo，就还没到起草的时候：停下并路由——缺证据交给 `$stage-evid-curator`，简介形状不对交给 `$stage-outl-planner`。

### Step 4：起草或修订 tex

1. 在页数预算之内写，遵循简介的段落议程；用台账能指向的、主张形状的句子陈述每条被分配的主张。
2. 每个数字都从本次运行读过的 `mates/` 文件里抄来，并在承载它的那句话上一行加一条 `% src: mates/<slug>/...#<anchor>` 注释——这与 `$stage-clms-auditor` 在表格里走的是同一条踪迹。没有这条来源的数字一律写成点名缺哪次测量的 `\todo{...}`。
3. 使用与提纲 ID 挂钩的 `\label`/`\ref`（`sec:`、`tab:`、`fig:`）；即便表和图还不存在，也按它们计划中的 ID 引用——这个 `\ref` 就是需求单。
4. 每个 `\cite` key 都必须能在 `manus/bibs/reference.bib` 里解析；值得引用但还不在 bib 里的工作要标出来并路由到 `$stage-refs-curator`——绝不发明 key，绝不凭记忆粘一条 bib 条目（§9b）。
5. `.env` 设了 `ANON=true`（§3）时，按匿名起草：第三人称自指、无致谢、无可识别 URL——漏网的由 `execs/scpts/lint.sh` 搜捕。
6. 修订时：立得住的保留，论证需要什么就改什么，绝不静默丢掉一条已陈述的主张——丢掉一条是一次台账状态变更（`dropped`），要先由用户确认。

### Step 5：更新各登记项

1. `notes/claims.md`：为每条被陈述的主张，把本节的 slug 加进 Stated in；把 `proposed` 翻成 `drafted`；陈述了却没有证据的主张进入 `unsourced`——它在正文里的那句话带着该状态所要求的 `\todo`。`verified` 的行保持状态；只有 Stated in 增长。
2. `notes/notation.md`：追加新的 Symbols 行（First defined = 本节）与 Abbreviations 行（First use）；更新 `updated:`（真实日期，§4）。
3. `notes/outline.md`：本节那一行 → `drafted`（对一个 `polished` 行的实质性修订同样把它退回 `drafted`）；更新 `updated:`。

### Step 6：检查、汇报、提交

1. 提议跑一次 `execs/run.sh` 构建——草稿不得弄坏编译。对本节 grep `\todo{`，报出计数与每条 todo 的文字；只要还有残留，`execs/scpts/lint.sh` 就会把手稿卡在关口。
2. 汇报：模式（起草/修订）、陈述了哪些主张及其新状态、剩下多少 todo、加了哪些符号、读了哪些证据文件及其时间戳、过期警告，以及本节相对页数预算的大致长度（有 `texcount` 时，逐节字数由 `lint.sh` 给出）。
3. 建议下一步：本节引用的表格用 `$stage-tabs-builder`，任何东西发出去之前用 `$stage-clms-auditor`，内容稳定之后用 `$stage-copy-editor`。
4. 按 §1 提交：一个工作会话一次提交——章节、台账、记号表、提纲一起——标题点名 skill（`stage-sect-drafter: draft 3_method`）。绝不提交 `wkdrs/`。

## 输出

- `manus/secs/<n>_<slug>.tex`——起草或修订好的那一节；它的状态字段是 `notes/outline.md` 里 Sections 行的状态（登记表：Section drafts）。
- `notes/claims.md`——Stated in 扩充；状态翻成 `drafted` / `unsourced`。
- `notes/notation.md`——追加的 Symbols 与 Abbreviations 行。
- `notes/outline.md`——该节的行状态与 `updated:`。
- 聊天汇报：陈述了哪些主张、`\todo{}` 清单、读过的证据及其时间戳、过期警告，以及建议的下一个 `$stage-*` 步骤。除这些文件之外什么都不写。
