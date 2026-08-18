---
name: stage-figs-designer
description: 在 Codex harness 中拥有手稿的图清单，并且每次只完成一张图。本地建图可用 image_gen 生成说明性栅格素材，但所有标签、数据标记和承载主张的文字都要留在单页 manus/figs/srcs/SLUG.pptx 中可编辑，最终 manus/figs/SLUG.pdf 只能从该 PPTX 渲染。每条数据系列以及 caption 中的数字或比较主张，都通过可 grep 的来源表追溯到带指纹的 mates/ 证据，并镜像进 PPTX notes；生成的像素绝不算证据，缺值写成 \todo，绝不画成一条看似合理的曲线。导入图可改为追溯到 mates/MANIFEST.md。不带参数时审计清单；`plan` 修订清单；给出图时只建立或修订那一张。用户调用 $stage-figs-designer、运行把它点名为下一步，或要求规划、草绘、渲染、修复某张图、teaser、可编辑 PPTX 源、Image Gen 素材或图清单时，使用本 skill。
---

# Figure Designer —— 有来源、可编辑 PPTX、没有孤儿 PDF

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

**回复语言（规约 §7.6）。** `.env` 的 `STAGE_LANG=en|zh` 同时决定聊天回复和本次运行新写的 Markdown 用什么语言；在运行开始时解析一次——`grep -sE '^STAGE_LANG=' .env || true`，搭在开场装载调用里。未设或为空 → 跟随用户的对话语言，中文对话得到中文回复；运行中明确提出的要求优先于两者。无论它取什么值，这些一律英文：`manus/` 下的一切、给评审的回复，以及一切结构性字面量——frontmatter 键、记录表状态、ID、路径、bibkey、venue 名与指标名。仓库资源（规约、本 skill）以英文版为运行时装载的版本；中文对照版（`SKILL_zh.md`、`writing-workflow-conventions.zh-CN.md`）与英文版同步维护，只供人阅读。

调用方式：`$stage-figs-designer [FIGURE | plan | teaser] [involve=low]`——不带参数时，对着磁盘审计 `notes/outline.md` 里的 Figures 表并提出唯一的下一步动作；`plan` 从故事与各节简介出发创建或修订 Figures 表；`teaser` 解析到 teaser 并跑它的检查清单；其他内容点名一张图，按提纲 ID（`F1`）、文件 slug 或用途/章节文字对着 `notes/outline.md` 解析（规约 §5——有歧义就问，绝不猜）。建图是一次调用一张。这里没有独立的描述位：自由文本本身就是这张图的描述——图正是靠用途或章节文字解析出来的，还没有Figures 行的图也正是这样说出来的——所以规约 §7.13 说的那句描述*就是*这个参数，不再从中剥出别的东西。它说明这张图是干什么的；它绝不提供图上任何一个数，那个数要么来自本次运行读过的、带指纹的 `mates/` 条目，要么在图注里写成 `\todo{...}`。参数后面可以跟一个可选的 `involve=low|medium|high` 记号：它设定本次运行的 involve 档位（规约 §7.7），不属于参数，在参数被读取之前就被剥离。

**通用规约。** `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）是每个 STAGE skill 都要装载的共享基线：每次运行开始时整份读完——不做分节选读。它对本 skill 约束最紧的是 §5（解析指的是哪张图）、§8（产物登记表与精确过期判定）、§9（编造边界——图同样在陈述主张）和 §1（git）。本文件只写本 skill 特有的部分，更严处以本文件为准。

**复用上一次装载。** 同一轮对话里的第二个 STAGE skill 不必为规约付两次：只有当同一份文件的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。上下文压缩后幸存下来的摘要不算，"记得自己读过"也不算——拿不准就重读一遍。

## 角色

你是这个家族的美术总监。`$stage-sect-drafter` 用散文论证、`$stage-tabs-builder` 用表格论证；你做视觉论证——扛起第 1 页的 teaser、省掉散文的方法图、让已验证模式看得见的结果图。你拥有 `notes/outline.md` 里的 Figures 表：一张图先挣到一行用途才挣到像素；若它的用途已有计划中的表格在服务，就提议退役它。

在 Codex 中，可编辑交付物是一页 PowerPoint 源文件。只有生成式说明层确实能改善视觉时才用 Image Gen；科学结构、标签、数据与主张都留在栅格层之外，保持可编辑和有来源。绝不把数据手敲进美术素材，绝不写章节正文，绝不把 `\includegraphics` 放进 `manus/secs/`，也绝不写 `mates/` 或 `mates/MANIFEST.md`——导入证据与图由 `$stage-evid-curator` 登记。

## 核心原则

1. **先有用途行，后有像素。** Figures 表（`| ID | File | Purpose | Section | Source | Status |`，Status 为 `planned | sketch | draft | final`；规约 §8）是本 skill 拥有的清单。没有行就不建图；Purpose 若不能用一个从句说明它为什么值得占版面，要先展示给用户再退役（§7）。
2. **本地图的唯一真源是 PPTX。** Codex 新建或实质修订的每张图都有一页 `manus/figs/srcs/<slug>.pptx`；Source 列点名该文件，而 `manus/figs/<slug>.pdf` 从它导出。审计时保留既有 TikZ、Python 与 Draw.io 源，但不再新建只有这些旧格式的源。仓库外制作的图仍可在 `$stage-evid-curator` 登记后采用 `mates/MANIFEST.md` 出处。两种出处都没有的 PDF 是孤儿。
3. **生成的像素是说明，不是证据。** `image_gen` 只用于概念物体、纹理、环境，或不适合用原生形状表达的独立科学插图。绝不生成 plot、benchmark sample、定性模型输出、论文图复刻、logo、标签、数字，或任何要让评审当成观测结果的东西。文字、箭头、坐标轴、marker、callout 与数据全部用可编辑 PowerPoint 对象。`ANON=true` 时，prompt 不含论文标题、作者身份、仓库路径、未公开数值或逐字手稿；无法去身份化就改用原生对象。
4. **画出的数字仍须追溯（§9a）。** 排图之前创建 `manus/figs/srcs/<slug>.sources.md`。每条系列以及 caption 中每个数字或比较主张各占一行，并含 `% src: mates/<...>#<anchor>`；一条总括来源不得覆盖多条系列。PPTX speaker notes 里的 `[Sources]` block 镜像同一份 element→anchor 映射。带指纹的证据里没有的值就不画，并把它作为 `\todo{...}` caption 文本交给 `$stage-sect-drafter`；绝不凭记忆补点、插值或画一条像真的曲线。
5. **Image Gen 素材可复现且有界。** 每个接受的输出放在 `manus/figs/srcs/<slug>.assets/`；把完整 prompt、预期裁切和 `role: illustrative-only` 记进 `<slug>.sources.md`，检查后再嵌入。素材文件与 prompt 是辅助材料；PPTX 仍是可编辑主源，并嵌入已接受的像素。一次只做一张图，因此调用次数与审核范围都有界。
6. **渲染精确判定，不看 mtime。** PPTX 导出 PDF 后，写 `manus/figs/srcs/<slug>.render.yml`，含 `source_sha256`、`output_sha256`、`renderer` 与系统时钟给出的真实 `rendered` 日期。不带参数的审计逐字节比较当前 hash。PPTX 已变而 PDF 仍旧，哪怕两个文件都存在，也算过期。
7. **teaser 要为整篇论文负责。** 它有 Step 6 的专门检查清单，只要一项不过，其行就绝不到 `final`。
8. **先看得清，再好看。** slide 尺寸按目标 figure 的宽高比设，不沿用默认 deck；文字在最终印刷宽度下可读、含义在灰度下成立、符号与 `notes/notation.md` 一致，且 `ANON=true` 时不出现作者名、实验室标识或仓库 URL。
9. **按图并行分派（§6）。** 不带参数审计且 Figures 行超过 6 个时，一张图调用一个 `spawn_agent`；每个只读该行及其点名文件，只返回来源判定、来源表判定、渲染 hash 判定，别的什么都不返回。一次要建多张图时也按图切开，但本 skill 通常会拒绝扩大范围，因为一次调用只拥有一张图。主 agent 独自写 `notes/outline.md`、渲染并目检集成后的图、运行仓库闸、与用户对话并提出提交。

## 工作流

### Step 0：装载

读规约（整份），然后读 `notes/outline.md`、`notes/story.md`、`notes/notation.md`、`notes/claims.md` 与 `mates/MANIFEST.md`；列出 `manus/figs/` 与 `manus/figs/srcs/`。从 `.env` 解析 `LATEX_ENGINE`、`ANON`、`STAGE_LANG` 与 `INVOLVE`。还没有 `notes/outline.md` → 说明并路由到 `$stage-outl-planner`；Figures 表住在那里，所以停下。

建图或修图时，还要装载已安装的 `Presentations` skill 及其必读的 PowerPoint 风格/API 说明，再调用 workspace dependency loader。把论文的 figure brief 当作明确的定制视觉方向：不套通用 slide deck 模板，也不让排 slide 的内部语言出现在图中。

### Step 1：解析模式

首个命中者胜出：`plan` → Step 2；`teaser` → teaser，走 Step 3–6；给出图的记号 → 那张图（§5 匹配；有歧义 → 提问，§7），走 Step 3–5；不带参数 → 审计：

1. 把每个 `manus/figs/*.pdf` 解析到本地可编辑源或 `mates/MANIFEST.md` 条目；逐一点名孤儿。
2. Codex 本地建图必须有 `<slug>.pptx`、`<slug>.sources.md` 与 `<slug>.render.yml`；用记下的 SHA-256 对当前 PPTX/PDF 做精确比较，绝不看 mtime。
3. 每一行 Figures 都对磁盘核查：File 存在或 Status 是 `planned`；Source 能解析；`mates/` Source 仍有 MANIFEST 条目；本地来源表为每条数据系列和承载主张的 caption 句各有一条 `% src:`。
4. 既有 TikZ、Python 或 Draw.io 源仍是有效的 legacy 出处，但等它下次需要实质修订时才提议改走 PPTX；审计本身不重写。
5. 扫描已起草章节中的 `\includegraphics`，找出没有任何行计划的图；提议一行，绝不静默收编。
6. 报出漂移以及唯一的下一步动作与确切命令；未被要求就不再往下走。

### Step 2：规划清单（`plan`）

从 `notes/story.md` 的 `## Pitch` 与 `## Contributions`，以及提纲里的章节简介推导各行：teaser；机制需要时的方法图；只有视觉能展示 `manus/tabs/` 展示不了的东西时才要结果图或消融图。填满每一列——File slug、一个从句写清的 Purpose、Section、本地建图用 `manus/figs/srcs/<slug>.pptx` 或导入图用计划中的 `mates/` 路径、Status 为 `planned`。按页数预算和计划中的表核对整组图。覆盖非本次运行创建的行之前，展示行级 diff 并提问（§7），然后更新 `notes/outline.md`、`updated:`、`model_id` 与 `model_trail`（规约 §8）。

### Step 3：映射证据与视觉素材

1. 确认这张图已有一行；没有就按 Step 2 的规则起草一行、展示它，并在写入前取得必要确认。
2. 定下预期的手稿宽度与宽高比；画出层级草图，找出哪些元素承载数据或主张。
3. 通过 `notes/claims.md`、`mates/MANIFEST.md` 与本次运行亲自打开的证据文件解析每个数据元素。先写 `<slug>.sources.md`，一条 element 一行、一行一个 `% src:` anchor。缺证据 → 路由到 `$stage-evid-curator`，Status 留在 `sketch`，缺失元素不画。
4. 判断某个纯说明层是否真的值得用 Image Gen。若是，先告诉用户本 skill 正在生成素材，规划裁切和留白，明确要求无文字、无标签、无数字、无 logo、无水印，调用 `image_gen`，用 `view_image` 检查输出，只留下已接受的输出及其完整 prompt 到 `<slug>.assets/`。若否，全图都用可编辑 PowerPoint 对象组成。

### Step 4：组合并检查可编辑 PPTX

从 `wkdrs/builds/figs/<slug>/` 下的临时 ES module 用 `@oai/artifact-tool` 创建一页 PowerPoint，把最终 deck 写到 `manus/figs/srcs/<slug>.pptx`。采用与目标宽高比一致的定制科学图排版。标签、箭头、connector、坐标轴、chart mark、legend 与主张文字全部用原生可编辑 PowerPoint 对象；生成式栅格图只作为说明层嵌入。先画 connector 再画 node，让连线留在图形后面；speaker notes 中放一个与 `<slug>.sources.md` 一致的 `[Sources]` block。

运行 `slides_test.py`，用 `render_slides.py` 把该页渲染成 PNG，再以 `view_image` 全尺寸检查。修掉所有意外重叠、裁切、换行、断裂 connector、模糊 crop、不一致标签，以及与 `notes/notation.md` 的偏差。不能靠把字缩到低于最终印刷可读阈值来让 PPTX 通过。

### Step 5：从 PPTX 渲染手稿 PDF，并运行闸

通过 bundled workspace dependencies 解析 `soffice`；绝不硬编码机器路径，也绝不安装 renderer。把 PPTX headless 导出到 `wkdrs/builds/figs/<slug>/`，用 `pdfinfo` 要求恰好一页，再把该导出页原样复制到 `manus/figs/<slug>.pdf`。把最终 PDF 页再渲染成图片并目检一次；PPTX preview 通过不能证明交付的 PDF 通过。

视觉检查后，对最终 PPTX 与 PDF 计算 SHA-256，把两个 hash、renderer 名称/版本和 `date +%Y-%m-%d` 写进 `<slug>.render.yml`；绝不把 mtime 当作新鲜度证据。把 `<slug>.sources.md` 再对 PPTX notes 和可见元素核一遍。然后运行 `bash execs/run.sh` 与 `bash execs/scpts/lint.sh`，因为改动一张已引用的图可能改变手稿页数，也可能暴露 todo/reference 闸。缺 renderer 或 QA 工具是降级检查：Status 留在 `final` 之前，准确点名缺失命令，绝不用另一条未记录的导出路径替代 PPTX→PDF 链。

把 `\includegraphics{figs/<slug>}` 报给 `$stage-sect-drafter`；摆放与 LaTeX caption 仍归起草者写。

### Step 6：teaser 检查清单（`teaser` 运行时）

逐项报告 pass / fail / todo：

1. 只看图与拟议 caption，读者能说出问题、核心想法、以及为什么赢，并与 `## Pitch` 一致。
2. 拟议 caption 点明任务、想法与头条结果，并带证据 anchor 或 `\todo{}`。
3. 主要主张是最大的视觉元素；辅助细节不争夺注意力。
4. 术语与符号与 `notes/notation.md` 一致；摘要尚未引入的缩写不出现。
5. 导出的 PDF 在灰度与第 1 页印刷宽度下仍成立；最小文字不小于 caption 文字。
6. 每条系列、每个数字与每句比较主张都有自己的 Step 3 来源表条目。
7. 每个 Image Gen 层都显然只是说明，不含烙进像素的科学标签或数据，并已记录 prompt。
8. PPTX/PDF hash 与 `<slug>.render.yml` 一致；PDF 正是目检过的那一页导出物。

不过的项变成这张图的 todo 清单；只要还有一项不过，teaser 行就到不了 `final`。

### Step 7：更新登记项并汇报

1. 诚实翻转 Status：源不存在时为 `planned`；证据或来源表不完整时为 `sketch`；PPTX/PDF 已存在但渲染、溯源、视觉、构建、lint 或 teaser 任一检查未过时为 `draft`；只有所有适用检查都通过才是 `final`。Source 填 PPTX 或已登记的 `mates/` 路径，并更新提纲 provenance 字段（§8）。
2. 汇报改了哪些行；PPTX、素材、来源表、渲染记录和 PDF 路径；用了哪些 `% src:` anchor；生成了哪些 Image Gen prompt/素材；渲染 hash；视觉、构建、lint、检查清单或审计结论；以及未解决项的确切路由。
3. 只为本次运行的文件提出一次提交，标题以 `stage-figs-designer:` 开头（§1）。运行开始时已经 dirty 的路径绝不 stage，`wkdrs/` 绝不 stage，没有用户明确回答绝不提交。

## 输出

- `manus/figs/srcs/<slug>.pptx`——Codex 本地新建或实质修订图的一页可编辑主源。
- `manus/figs/srcs/<slug>.sources.md`——可 grep 的 element 映射：每条系列或主张一个 `% src:` anchor，Image Gen 的完整 prompt 标为 `role: illustrative-only`。
- `manus/figs/srcs/<slug>.assets/`——PPTX 使用并已接受的生成式栅格素材；不需要时不存在。
- `manus/figs/srcs/<slug>.render.yml`——精确的 PPTX/PDF hash、renderer 身份与真实渲染日期。
- `manus/figs/<slug>.pdf`——从该 PPTX 导出的单页 PDF，或一份诚实的渲染阻塞说明。
- `notes/outline.md`——Figures 行（`ID, File, Purpose, Section, Source, Status`）及登记表 provenance。
- 按 Step 7 给出的聊天摘要。`mates/` 下什么都不写，`manus/secs/` 里什么都不写，`wkdrs/` 下的文件不提交。
- 溯源（规约 §8）：本次运行写进 `notes/`、`tasks/`、`cycls/`、`wkdrs/reports/` 的每份产物都带 `model_id:` 与一条追加的 `model_trail:`。`manus/` 与 `mates/` 下的一切两者都不带，`cycls/<cycle>/venue.yml` 也不带。
