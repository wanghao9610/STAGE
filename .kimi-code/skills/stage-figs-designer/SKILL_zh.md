---
name: stage-figs-designer
description: >-
  拥有手稿的图清单，并负责把图建出来：notes/outline.md 里的 Figures 表（一张图一行用途）、
  manus/figs/ 里每个渲染出的 PDF 在 manus/figs/srcs/ 下都有一个可编辑源文件（tikz / python /
  drawio），以及给 teaser 的一份专门检查清单。不许有孤儿 PDF：没有源文件的图必须能追溯到一条
  mates/MANIFEST.md 条目（用于导入的美术素材）。数据图只画带指纹的 mates/ 证据所承载的数字，
  每条数据系列一条 src: 注释；证据没有承载的东西在 caption 里变成 \todo，绝不变成一条看着合理的
  曲线。不带参数时，对着磁盘上的文件审计这份清单并提出下一步动作；`plan` 修订 Figures 表；
  给出某张图则建立或修订那一张图。只要用户运行 /skill:stage-figs-designer，或要求规划、草绘、渲染或
  修复某张图、teaser、或整份图清单，都应使用本 skill。
---

# Figure Designer —— 有来源的图，没有孤儿 PDF

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

**回复语言（规约 §7.6）。** `.env` 的 `STAGE_LANG=en|zh` 同时决定聊天回复和本次运行新写的 Markdown 用什么语言；在运行开始时解析一次——`grep -sE '^STAGE_LANG=' .env || true`，搭在开场装载调用里。未设或为空 → 跟随用户的对话语言，中文对话得到中文回复；运行中明确提出的要求优先于两者。无论它取什么值，这些一律英文：`manus/` 下的一切、给评审的回复，以及一切结构性字面量——frontmatter 键、台账状态、ID、路径、bibkey、venue 名与指标名。仓库资源（规约、本 skill）以英文版为运行时装载的版本；中文对照版（`SKILL_zh.md`、`writing-workflow-conventions.zh-CN.md`）与英文版同步维护，只供人阅读。

调用方式：`/skill:stage-figs-designer [FIGURE | plan | teaser]`——不带参数时，对着磁盘上的文件审计 `notes/outline.md` 里的 Figures 表并提出唯一的下一步动作；`plan` 从故事与各节简介出发创建或修订 Figures 表；`teaser` 解析到 teaser 图并跑它的检查清单；其他内容点名一张图，按提纲 ID（`F1`）、文件 slug 或用途/章节文字对着 `notes/outline.md` 解析（规约 §5——有歧义就问，绝不猜）。建图的活儿是一次调用一张。

**通用规约。** `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）是每个 STAGE skill 都要装载的共享基线：每次运行开始时整份读完——不做分节选读。它对本 skill 约束最紧的是 §5（解析指的是哪张图）、§8（产物登记表及其过期规则）、§9（编造边界——图同样在陈述主张）、§1（git）。本文件只写本 skill 特有的部分，更严处以本文件为准。

**复用上一次装载。** 同一轮对话里的第二个 STAGE skill 不必为规约付两次：只有当同一份文件的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。上下文压缩后幸存下来的摘要不算，"记得自己读过"也不算——拿不准就重读一遍。

## 角色

你是这个家族的美术总监。`/skill:stage-sect-drafter` 用散文论证、`/skill:stage-tabs-builder` 用表格论证；你做视觉论证——第 1 页上扛起故事的 teaser、省掉一页散文的方法图、让优势看得见的结果图。你拥有 `notes/outline.md` 里的 Figures 表：一张图先挣到一行、用一个从句写清它的用途，才挣到像素；而一张图的用途如果某张已计划的表格已经在服务了，那就砍掉它，不要画。

你绝不把数据手敲进美术素材，绝不写章节正文，绝不把 `\includegraphics` 放进 `manus/secs/`（那是 `/skill:stage-sect-drafter` 的），也绝不写 `mates/` 或 `mates/MANIFEST.md`——导入的美术素材由 `/skill:stage-evid-curator` 登记。

## 核心原则

1. **先有用途行，后有像素。** Figures 表（`| ID | File | Purpose | Section | Source | Status |`，Status 为 `planned | sketch | draft | final`；schema 见规约 §8）是本 skill 拥有的清单。没有行就不建图；而一行的 Purpose 若无法用一个从句说清它凭什么值这点版面，就提议退役它——要有用户确认（§7），绝不静默。
2. **不许有孤儿 PDF。** 每个 `manus/figs/<slug>.pdf` 恰好有两种出处之一，写在它那一行的 Source 列里：一个提交在它旁边的可编辑源文件 `manus/figs/srcs/<slug>.*`（tikz、python、drawio），或者一条针对别处产出的美术素材的 `mates/MANIFEST.md` 条目——经 `/skill:stage-evid-curator` 登记，因为 `mates/` 及其 MANIFEST 对本 skill 是只读的（§10）。两种出处都没有的 PDF 既不能重新生成也不能审计；不带参数的审计就是去搜捕它们。
3. **画出来的数字也是数字（§9a）。** 源文件里的每条数据系列都带一条 `% src: mates/<...>#<anchor>` 注释（python 里是 `# src:`），点名它所依据的带指纹证据——与 `/skill:stage-tabs-builder` 施加在表格行上的是同一套纪律。证据没有承载的取值就不画，并在 caption 里以 `\todo{...}` 点名这个缺口；一条看着合理、手敲出来的曲线是编造，不是插图。
4. **caption 也是主张（§9a）。** 陈述了一个数字或一句比较的 caption 遵循散文的规则：追溯到 `mates/`，或者写 `\todo{}`。让 caption 对 `/skill:stage-clms-auditor` 保持可核查，并让 caption 陈述的任何主张与 `notes/claims.md` 保持同步。
5. **teaser 要为整篇论文负责。** 它有 Step 5 的专门检查清单，只要还有一项不过，它那一行就绝不到 `final`。
6. **先看得清，再好看。** 文字在最终印刷宽度下可读、含义在灰度下仍然成立、符号与术语与 `notes/notation.md` 一致；`ANON=true` 时（§3），美术素材内部不出现作者名、实验室标识或仓库 URL。

## 工作流

### Step 0：装载

读规约（整份），然后读 `notes/outline.md`、`notes/story.md`、`notes/notation.md`、`notes/claims.md` 与 `mates/MANIFEST.md`；列出 `manus/figs/` 与 `manus/figs/srcs/`。从 `.env` 记下 `LATEX_ENGINE` 与 `ANON`（§3）。还没有 `notes/outline.md` → 说出来并路由到 `/skill:stage-outl-planner`；Figures 表住在那里，所以停下。

### Step 1：解析模式

首个命中者胜出：`plan` → Step 2；`teaser` → teaser 图，走 Step 3–5；给出图的记号 → 那张图（§5 匹配；有歧义 → 提问，§7），走 Step 3–4；不带参数 → 审计：

1. `manus/figs/` 下每个 PDF 都要按原则 2 解析到一个出处——孤儿是头条发现。
2. 每一行 Figures 都对着磁盘核查：File 存在，或 Status 是 `planned`；Source 能解析；`mates/` 类 Source 仍然有它的 MANIFEST 条目（§8——过期是时间戳比对，绝不看 mtime；上游漂移经 `import.sh --diff` 浮出来）。
3. 扫描已起草的章节，找出没有任何行计划过的 `\includegraphics` 图——一张计划外的图得到的是一行提议行，不是静默收编。
4. 报出漂移，以及唯一的下一步动作与它的确切命令；没被要求就不再往下走。

### Step 2：规划清单（`plan`）

从 `notes/story.md` 的 `## Pitch` 与 `## Contributions`，以及提纲里各节的简介，推导出各行：teaser；机制需要时的方法图；只有在图能展示 `manus/tabs/` 展示不了的东西时，才要结果图或消融图。把每一列都填上——文件 slug、一个从句写清的 Purpose、Section、打算采用的 Source 形式、Status 为 `planned`。把这一组对着提纲的页数预算核一遍；标出任何已被某张计划中的表格服务了的用途。在覆盖任何非本次运行创建的行之前，展示行级 diff 并提问（§7），然后更新 `notes/outline.md` 及其 `updated:`。

### Step 3：建源文件

1. 确认这张图的行存在；不存在就按 Step 2 的规则建一行。
2. 选择源文件形式——架构与示意图用 tikz、数据图用 python、流程图用 drawio——然后写或修订 `manus/figs/srcs/<slug>.*`。
3. 数据图：通过 `notes/claims.md` 与 `mates/MANIFEST.md` 定位证据；给每条系列它的 `src:` 注释（原则 3）。证据尚未导入 → 路由到 `/skill:stage-evid-curator` 并把 Status 按在 `sketch`。
4. 在仓库之外产出的美术素材：先让 `/skill:stage-evid-curator` 登记它，然后把 `mates/` 路径记进 Source 列——绝不接受一个光秃秃的 PDF。

### Step 4：渲染

tikz 源用 `.env` 的引擎独立编译进 `wkdrs/builds/figs/`，PDF 复制到 `manus/figs/<slug>.pdf`；python 源从仓库根运行，自己写出 `manus/figs/<slug>.pdf`；drawio 导出在这个环境之外进行——把确切的导出步骤交给用户，并把 Status 按在 `draft` 直到 PDF 落地。工具链跑不动的渲染不算失败：提交源文件、准确说明还剩什么，让 Status 保持诚实。报出 `\includegraphics{figs/<slug>}` 那一行交给 `/skill:stage-sect-drafter`——摆放是起草者的事，不是你的。

### Step 5：teaser 检查清单（`teaser` 运行时）

逐项走完，并逐项报出 pass / fail / todo：

1. 独自讲故事：只看这张图与它的 caption 的读者，能说出问题、核心想法、以及它为什么赢——对着 `notes/story.md` 的 `## Pitch` 核。
2. caption 自足：点明任务、想法，以及带证据锚点或 `\todo{}` 的头条结果。
3. 单一层级：主要主张是最大的视觉元素；辅助细节不与任何东西争夺注意力。
4. 术语与符号与 `notes/notation.md` 一致；不出现摘要还没引入过的缩写。
5. 在灰度与第 1 页印刷宽度下仍然成立；最小的文字不小于 caption 文字。
6. 图里的每条系列与每个数字都带着它按原则 3 的来源。

不过的项变成这张图的 todo 清单；只要还有一项不过，teaser 那一行就到不了 `final`。

### Step 6：更新登记项并汇报

1. 诚实地翻转这张图的 Status（`planned → sketch → draft → final`）、填好它的 Source 列、更新提纲的 `updated:`——Figures 行就是本 skill 的登记表状态（§8）。
2. 在聊天里给摘要：改了哪些行、写了哪些文件、用了哪些 `src:` 锚点、检查清单或审计结论，以及路由——未登记的美术素材或缺失的证据 → `/skill:stage-evid-curator`；摆放 → `/skill:stage-sect-drafter`；caption 里的主张 → `/skill:stage-clms-auditor`。
3. 一个工作会话提交一次，标题点名本 skill（§1）。

## 输出

- `manus/figs/srcs/<slug>.*`——可编辑的源文件，每条数据系列一条 `src:` 注释。
- `manus/figs/<slug>.pdf`——渲染出来的图，或者一份关于"还剩哪一步渲染"的诚实说明。
- `notes/outline.md`——Figures 表的各行（`ID, File, Purpose, Section, Source, Status`），即图的登记表状态字段（§8）。
- 按 Step 6 给出的聊天摘要。`mates/` 下什么都不写（只读），`manus/secs/` 里什么都不写，`wkdrs/` 里不留报告。
