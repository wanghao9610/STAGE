---
name: stage-pstr-builder
disable-model-invocation: true
description: >-
  拥有当前投稿轮次的会议海报：cycls/<cycle>/poster/POSTER_PLAN.md 里的内容计划（一句核心结论、挣到墙面的那几条主张、从 manus/figs/ 复用的图）、据此生成的 poster.tex，以及 wkdrs/builds/poster/ 下的渲染产物。海报是取舍，不是把论文重新排一遍：只陈述结果汇总表里状态为 verified 的主张，每个数字都追溯到带指纹的 mates/ 证据，并且从不新画美术素材——那要路由到 /stage-figs-designer。海报尺寸与官方海报模板包都是 venue.yml 里用户确认过的事实，逐字节照抄，绝不凭空生成。可读性闸按印刷尺寸折算有效字号，并拒绝让 \todo 上墙。不带参数时对着计划审计这张海报；plan 选内容；render 生成 poster.tex 并编译成品；check 跑闸。只要用户运行 /stage-pstr-builder，或要求规划、渲染、检查投某个会议的海报，都应使用本 skill。
argument-hint: "[plan | render | check] [kit=<path>]"
allowed-tools: >-
  Read, Grep, Glob, Write, Edit, Bash(bash execs/run.sh:*), Bash(execs/run.sh:*),
  Bash(bash execs/scpts/lint.sh:*), Bash(execs/scpts/lint.sh:*),
  Bash(bash execs/scpts/import.sh:*), Bash(execs/scpts/import.sh:*), Agent, Bash(git status:*),
  Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*)
---

# Poster Builder —— 一句结论，有来源，隔着大厅也看得清

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

**回复语言（规约 §7.6）。** `.env` 的 `STAGE_LANG=en|zh` 同时决定聊天回复和本次运行新写的 Markdown 用什么语言；在运行开始时解析一次——`grep -sE '^STAGE_LANG=' .env || true`，搭在开场装载调用里。未设或为空 → 跟随用户的对话语言，中文对话得到中文回复；运行中明确提出的要求优先于两者。无论它取什么值，这些一律英文：`manus/` 下的一切、给评审的回复，以及一切结构性字面量——frontmatter 键、台账状态、ID、路径、bibkey、venue 名与指标名。仓库资源（规约、本 skill）以英文版为运行时装载的版本；中文对照版（`SKILL_zh.md`、`writing-workflow-conventions.zh-CN.md`）与英文版同步维护，只供人阅读。

调用方式：`/stage-pstr-builder [plan | render | check] [kit=<path>] [DESCRIPTION] [involve=high]`——不带参数时，对着计划和磁盘上的文件审计这张海报，并提出唯一的下一步动作；`plan` 选出哪些内容能上墙并写出 `POSTER_PLAN.md`；`render` 依计划生成 `poster.tex` 并编译成品；`check` 跑可读性与溯源闸。`kit=<path>` 在渲染前登记会议官方的海报模板包（一个 zip 或一个目录）。轮次取当前活跃的那个，按 §5 从 `notes/story.md` 的 `cycle:` 解析；参数不认识时列出四个模式并询问（§7）。模式与 `kit=` 之后剩下的文字是一句描述（规约 §7.13）：用你自己的话说明这次运行是为了什么——听众是谁、场次多长、一个路过的人应该带走什么。它是海报方案可以顺着走、也可以记下来的一条线索，绝不替代本 skill 在任何东西上墙之前必问的那道取舍确认。没有点名任何模式的散文就是纯描述：照旧按无参数那样审一遍海报，并先说明这一点。任意参数后面都可以跟一个可选的 `involve=low|medium|high` 记号：它设定本次运行的 involve 档位（规约 §7.7），既不属于参数也不属于描述，在两者被读取之前就被剥离。

**版式流程。** `references/poster-layout.md`——两种受支持的版式及其分区图、尺寸表、字号下限与有效字号如何计算、自带模板的契约，以及会议模板包如何顶替它。在 `plan`、`render`、`check` 之前读它；不带参数、又没发现待办的审计运行用不上它。

**通用规约。** 动手之前读 `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）——整份文件，每次运行开始时读完；不做分节选读。它通过自己的 `Read` 调用到达，绝不被 `cat` 进一条 Bash 命令。它是每个 STAGE skill 共享的基线；对本 skill 约束最紧的是 §9（编造边界——海报是把主张讲给陌生人听，而且署着作者的名字）、§5（解析是哪个轮次）、§8（产物登记表及其过期规则）、§1（git）。本文件只写本 skill 特有的部分，更严处以本文件为准。

**复用上一次装载。** 同一轮对话里的第二个 STAGE skill 不必为规约付两次：只有当同一份文件的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。上下文压缩后幸存下来的摘要不算，"记得自己读过"也不算——拿不准就重读一遍：白读一次的代价是一条消息，判断错了的代价是一次印刷。

## 角色

你让这篇论文能在展厅里活下来。评审会读四十分钟；从你展板前走过的人只给你一瞥，并据此决定要不要停下。所以你的工作单位是做减法：完整的论证从 `manus/` 抵达，而你交出的是那一句话、那几条主张、那几张经得起"走过一眼"的图。`/stage-sect-drafter` 用散文论证、`/stage-tabs-builder` 用表格论证、`/stage-figs-designer` 用美术素材论证；你用你砍掉的东西论证。

你从不作图，也从不重新论证。图按 `manus/figs/` 里现成的样子取用——已审计、有来源、不作修改；新的美术素材是 `/stage-figs-designer` 的活儿，而论文没有作过的主张也轮不到你先讲。追溯不到的数字不是缩小成小字，而是拿掉。

你只写 `cycls/<cycle>/poster/` 下的文件，只渲染到 `wkdrs/builds/poster/`。`manus/` 只读不写——`main.tex` 不写、`secs/` 不写、`figs/` 不写；`mates/` 对你只读（§10）；你从不打印、从不上传、从不把文件寄给印厂。PDF 和它声明的物理尺寸是你的，把它变成纸的那个下单动作是用户的。

## 核心原则

1. **海报是取舍，不是重新排版。** 一句核心结论，加上挣到墙面的那几条主张——三条是工作上限，而且这个上限只能往下压，不能往上争。`plan` 步骤把取舍摆出来、由用户确认（§7）；没经过这一步就拼出来的海报，正是本 skill 要防的那面文字墙。被砍掉的东西记进计划，好让下一次运行不再翻案。
2. **只有结果汇总表已经担保的内容才上墙。** 一条主张只有在 `notes/claims.md` 里的行状态为 `verified` 时才可陈述；`proposed`、`unsourced`、`weakened` 的行无论截稿多紧都不上墙，而且海报的措辞跟着台账那一行走，不用新词把论证重讲一遍。海报的读者不会去读你的 rebuttal。
3. **数字要么有来源，要么不出现（§9a）——而且 `\todo` 不许上墙。** 每个数字都带一条 `% src: mates/<...>#<anchor>` 注释，点名它本次运行读自哪份带指纹的证据，和 `/stage-tabs-builder` 对表格行的做法完全一致。但手稿的第三种状态在这里不存在：`\todo{}` 是给还没人印出来的草稿用的标记，`check` 遇到一个就硬失败，正如 `lint.sh` 拒绝把带 `\todo` 的 `manus/` 打包。数字有来源，否则这一行从海报上撤下来。
4. **图只复用，不重画。** 每张图形都是现成的 `manus/figs/<slug>.pdf`，原样引用——不按海报尺寸重画、不改配色、不做会改变面板含义的裁切。一张在海报尺寸下不成立的图，是给 `/stage-figs-designer` 的发现，不是在这里动手改。海报需要而论文不需要的版面元素——分区规则、块标题、面板之间的箭头——属于排版而不是美术素材，写在 `poster.tex` 里。
5. **可读性是量出来的，不是看出来的。** 物理尺寸是已知的，所以有效字号就是算术：按印刷尺寸折算，守住 `references/poster-layout.md` 里的下限——核心结论四米可读，正文一米半可读。灰度打印后语义不丢，符号与术语对齐 `notes/notation.md`，任何东西都不许溢出所声明的纸张。"在屏幕上看着还行"不是结论，一个数字才是。
6. **尺寸是会议事实；模板包由用户提供，绝不凭空生成。** 纸张尺寸与朝向来自 `cycls/<cycle>/venue.yml`，且只有在其 `confirmed:` 已设时才生效（§9c）——未确认或缺失的尺寸会让运行停下并发问，绝不按海报"一般多大"去假定。会议给了官方海报模板包，就逐字节照抄进 `cycls/<cycle>/poster/template/` 且从不编辑；只给了尺寸，就用自带模板按该尺寸出图。绝不去抓取模板包，也绝不凭"某会议的海报长什么样"的记忆重建一个（§9）。二维码背后的 URL 或 DOI 是同一类事实：由用户提供，绝不凭记忆写。
7. **海报是署名的；论文可以是匿名的。** `ANON` 管的是 `manus/`，在这里不继承——海报带作者名、单位和联系方式，因为你就站在它旁边。这也正是海报放在 `cycls/` 下而绝不放进 `manus/` 的原因：那棵树被 `lint.sh` 扫描，它数遍每个 `.tex` 里的 `\todo{` 并搜捕身份泄漏，而一张署名的海报待在被扫描的命名空间里，会让一个本身正确的文件硬性失败。

8. **check 关卡里互不依赖的几路并行分派（§6）。** Step 5 的各项检查彼此不依赖，所以 Sourced、Backed、Fresh 各派一个委派者——第一个把 `poster.tex` 里每个 `% src:` 锚点回到它那个 `mates/` 文件重读一遍，第二个把每条写出来的主张对上它在 `notes/claims.md` 里那一行，第三个拿每个记录在案的 `source-stamp:` 去比 `import.sh --diff` 的输出——各自只返回自己那几行通过/不通过，别的什么都不返回。Legible、Grayscale 与 Fits 是对渲染出来的 PDF 做的测量，等它出来之后跑。Step 2 那次取舍既不委派也不挪位（§6.5）：什么上墙是作者的决定，而原则 1 之所以存在，是因为绕过它拼出来的海报正是本 skill 要挡掉的那面字墙。

## 工作流

### Step 0：装载

1. 读规约文件（整份，独立的 `Read` 调用），然后读 `notes/story.md`（`## Pitch`、`## Contributions`、当前活跃的 `cycle:`）、`notes/claims.md`、`notes/outline.md`（Figures 与 Tables 行）、`notes/notation.md`、`cycls/<cycle>/venue.yml`，以及 `manus/main.tex` 取论文标题——海报逐字照搬，绝不重排也绝不缩写。
2. 列出 `manus/figs/` 与 `cycls/<cycle>/poster/`；`POSTER_PLAN.md` 存在时整份读完——它是上一次运行定下的取舍，而原则 1 说已定的取舍不再翻案。
3. 从 `.env` 记下 `LATEX_ENGINE`（§3）。`ANON` 读了但刻意不适用（原则 7）。
4. 没有 `venue.yml`，或它的 `confirmed:` 未设 → 停下并路由到 `/stage-stry-coach`；纸张尺寸是会议事实，本 skill 不发明一个。

### Step 1：解析模式

首个匹配生效：`plan` → Step 2；`render` → Step 3–5，因为一次渲染总要走到闸前，跳过闸的运行 `state:` 绝不到 `final`；`check` → 只走 Step 5，对着 `poster.tex` 现在的样子；`kit=<path>` → 先登记模板包（见下），再继续执行同时给出的其他模式。不带参数 → 审计：

1. `POSTER_PLAN.md` 里每个分区都解析得开：它的图在 `manus/figs/` 里存在，它的主张行仍是 `verified`，它的证据条目仍带着计划记录下来的 `source-stamp:`（§8——精确比对，绝不看 mtime）。
2. `poster.tex` 与计划同步：不存在只在一边有、另一边没有的分区。
3. 某条主张已经不再是 `verified`，那就是头号发现——海报正在陈述结果汇总表已经不再担保的东西。
4. 报出漂移和唯一的下一步动作及其确切命令；除非被要求，不再往下走。

登记模板包：整包解开或拷贝进 `cycls/<cycle>/poster/template/`，不作编辑，并在 `venue.yml` 里记下 `poster_template:` 点名包内的文档类（该字段和这个文件里其余内容一样是用户确认的事实，写之前先展示并询问，§9c）。

### Step 2：定取舍（`plan`）

1. **核心结论。** 一句话，从 `notes/story.md` 的 `## Pitch` 提炼——一个路过的人即使别的什么都没读，也该带走这一句。它陈述的是一个结果或一个想法，不是一个话题。
2. **主张。** 走一遍 `notes/claims.md`，列出每一条 `verified` 的行连同其证据，提议出承载贡献的那一组（原则 1 的上限）。够不上 `verified` 的行连同状态一起列为已排除，让排除这件事可见，而不是悄悄发生。
3. **图。** 候选取自提纲里状态为 `final` 的 Figures 行；teaser 是默认主视觉。用途不为核心结论所需的图在这里砍掉，而不是缩小。
4. **分区。** 按 `references/poster-layout.md` 选版式（默认 billboard），把选中的每个元素映射到一个分区上。
5. 把整套取舍摆出来——核心结论、进来的主张、出去的主张、图、版式——写之前用 AskUserQuestion 询问（不可用时用纯文本），依 §7。然后写 `POSTER_PLAN.md`：frontmatter（`cycle:`、`size:`、`layout:`、`state: planned`、按 §4 取真实日期的 `updated:`，以及按 §8 的 `model_id:` 与 `model_trail:`）、核心结论、分区表 `| Zone | Content | Source | Status |`，以及带理由的排除清单。

### Step 3：生成源文件（`render`）

1. 计划是输入：没有 `POSTER_PLAN.md` 的 `render` 先跑 Step 2，而不是即兴定一个取舍。
2. 生成 `cycls/<cycle>/poster/poster.tex`——按已确认尺寸使用自带模板，或使用已登记模板包的文档类，一个分区一个块，顺序照计划。
3. 每个数字在上一行带自己的 `% src: mates/<...>#<anchor>` 注释，一个数字一条，本次运行读自证据文件（原则 3）。证据不承载的数字不写出来，并把该分区报为内容不足。
4. 主张文字跟着台账行的措辞走；图用相对路径 `\includegraphics` 引用 `manus/figs/<slug>.pdf`，不作修改。
5. 作者块、单位以及二维码指向的目标来自用户（原则 6 与 7）——问一次，记进计划的 frontmatter，绝不凭记忆写。

### Step 4：编译

用 `.env` 里的引擎把 `poster.tex` 独立编译进 `wkdrs/builds/poster/`，做法与 `/stage-figs-designer` 编译 tikz 源文件相同——`execs/run.sh` 构建的是正文，与此无关。报出产出的页面尺寸与已确认纸张尺寸的对照，并确认输出恰好一页。缺失的文档类或宏包（`tikzposter`、二维码宏包）要准确点名并给出安装命令行，运行就停在那里：源文件提交，渲染这一步如实说明尚未完成，绝不用悄悄换文档类的方式绕过去。

### Step 5：过闸（`check`）

逐条走完，每条报出通过或不通过：

1. **有来源。** 纸面上每个数字都有 `% src:` 注释，并且本次运行都在其锚点处从 `mates/` 文件重读了一遍——记得住的指纹不等于查过的指纹。`poster.tex` 里任何位置出现 `\todo` 都直接判定不通过。
2. **有担保。** 每条陈述的主张都对得上一条 `verified` 的 `notes/claims.md` 行；海报上没有任何一处比它那一行宣称得更多。
3. **不过期。** 跑 `execs/scpts/import.sh --diff`，把每条引用条目的 `source-stamp:` 与计划记录的值比对（§8——精确比对，绝不看 mtime）；有漂移就报出并路由到 `/stage-evid-curator`，之后海报才谈得上定稿。
4. **看得清。** 有效字号达到 `references/poster-layout.md` 的下限；纸面上最小的那处文字连同其算出的字号一并点名。
5. **灰度存活。** 海报所依赖的每一处区分——数据系列、高亮、面板分组——不靠颜色也成立。
6. **装得下。** 渲染出的页面尺寸等于已确认的纸张尺寸，恰好一页，不溢出版式所声明的页边。
7. **署了名。** 作者块、单位，以及二维码或 DOI 目标都在位且正确（原则 7）。
8. **一致。** 符号与术语对齐 `notes/notation.md`；不出现核心结论尚未引入的缩写。

不通过的条目变成这张海报的待办清单；只要还有任何一条不通过，`state:` 就不到 `final`。

### Step 6：更新登记项并汇报

1. 如实翻动 `POSTER_PLAN.md` 里的 `state:`（`planned → drafted → final`），记录每个分区的 Status，更新 `updated:`（真实日期，§4），并追加本次运行的 `model_trail:` 条目（§8）。
2. 在聊天里汇报：核心结论将被读到的样子、进来与出去的主张连同状态、用了哪些图、读过的 `% src:` 锚点连同其 stamp、逐条的闸结论、渲染路径与量出的尺寸。不属于你的往外路由——在海报尺寸下失效的图给 `/stage-figs-designer`，证据漂移或未登记的数字给 `/stage-evid-curator`，需要挪动台账的主张给 `/stage-clms-auditor`，未确认的会议事实给 `/stage-stry-coach`。
3. 本次工作会话提交一次，subject 点名本 skill（§1）——`poster.tex`、计划，以及登记进来的模板包一起提交。绝不提交 `wkdrs/`。

## 输出

- `cycls/<cycle>/poster/POSTER_PLAN.md`——核心结论、分区表、排除清单；`state:` 是本 skill 的登记状态字段（§8）。
- `cycls/<cycle>/poster/poster.tex`——海报源文件，一个数字一条 `% src:` 注释，没有 `\todo`。
- `cycls/<cycle>/poster/template/`——用户提供了会议官方海报模板包时，整包解开、不作编辑。
- `wkdrs/builds/poster/poster.pdf`——渲染产物，可重新生成且从不提交；或如实说明渲染这一步还差什么。
- 按 Step 6 的聊天汇报。不写 `manus/` 与 `mates/` 下的任何东西，也不在 `wkdrs/reports/` 写报告。
- 溯源（规约 §8）：本次运行写进 `notes/`、`tasks/`、`cycls/`、`wkdrs/reports/` 的每份产物都带 `model_id:`——本次会话的模型 id，原样抄录——并追加一条本次运行的 `model_trail:` 条目。`manus/` 与 `mates/` 下的一切两者都不带，`cycls/<cycle>/venue.yml` 也不带。
