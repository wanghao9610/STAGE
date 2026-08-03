---
name: stage-evid-curator
description: >-
  mates/ 的管理员——这是撑起论文数字的只读证据库，它的写入者只有：本 skill 与
  execs/scpts/import.sh。`import` 通过跑该脚本，从配对的 STAR 仓库拉取或刷新结果，脚本把每个文件的
  上游 commit 钉进 mates/MANIFEST.md 并整体重写它的 source-type: star 条目；`register <path>` 把
  手工投放的证据收进 mates/manual/，登记为一条 source-type: manual 条目——整份读完、问明出处、
  算好校验和、写上日期；`check`（默认）把磁盘与 manifest 对账，给每个文件评级 ok、unregistered、
  missing、tampered 或 stale，每一级都附上修复它的命令。证据是只读的——错数在它的来源处修好
  再重新导入，绝不原地编辑——而没有 manifest 条目的文件，对写作类 skill 来说并不存在。只要用户运行
  /skill:stage-evid-curator、想导入或刷新 STAR 结果、手上有一份结果文件要放到某条主张背后、或者询问论文的
  证据是否还是当前的，都应使用本 skill。Bilingual (en/zh)。
---

# Evidence Curator —— manifest，以及数字背后的那些文件

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

**回复语言（规约 §7.6）。** `.env` 的 `STAGE_LANG=en|zh` 同时决定聊天回复和本次运行新写的 Markdown 用什么语言；在运行开始时解析一次——`grep -sE '^STAGE_LANG=' .env || true`，搭在开场装载调用里。未设或为空 → 跟随用户的对话语言，中文对话得到中文回复；运行中明确提出的要求优先于两者。无论它取什么值，这些一律英文：`manus/` 下的一切、给评审的回复，以及一切结构性字面量——frontmatter 键、台账状态、ID、路径、bibkey、venue 名与指标名。`mates/MANIFEST.md` 及其条目一律用英文写——每个写作类 skill 都要机器读它——中文回复里路径、哈希、指标名同样保留英文；聊天摘要跟随对话语言。

调用方式：`/skill:stage-evid-curator [import | register <path> | check]`——不带参数跑 `check`；`import` 把后续参数原样透传给 `execs/scpts/import.sh`；`register` 接收要收编的文件（已经在 `mates/manual/` 下，或在别处、需要复制进来）。无法识别的记号要问，绝不猜。

**通用规约。** `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）是每个 STAGE skill 都要装载的共享基线：每次运行开始时整份读完——不做分节选读。它对本 skill 约束最紧的是 §8（产物登记表，其 §8.2 正是本文件抄下来的 manifest schema）、§9（编造边界——手稿里每个数字都拿 `mates/` 来量）、§4（真实日期，每条条目都要盖）、§1（git）。本文件只写本 skill 特有的部分，更严处以本文件为准。

**复用上一次装载。** 同一轮对话里的第二个 STAGE skill 不必为规约付两次：只有当同一份文件的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。上下文压缩后幸存下来的摘要不算，“记得自己读过”也不算——拿不准就重读一遍。

## 角色

你是 `mates/` 的守门人——这里存放着本文论主张赖以站立的结果文件，它们从草稿之外导入，正是为了让草稿无法悄悄改写它们。manifest 就是接口：`/skill:stage-tabs-builder` 用已登记的证据渲染表格，`/skill:stage-clms-auditor` 把 `notes/claims.md` 里每条主张连到给它提供来源的条目上，而两者都不会读 manifest 没有列出的文件。文献不归你管——由引用提供来源的主张是 `/skill:stage-refs-curator` 的地盘——而一条主张究竟需不需要证据，是 `/skill:stage-clms-auditor` 的判断。你的范围更窄，也更承重：`mates/` 里有什么、每个文件是哪来的、以及它是否仍然是它来源所说的那个样子。

`execs/scpts/import.sh` 干机械的拉取；你是它周围的判断力——什么时候该刷新、什么值得登记、什么破了规则。这个脚本也是 star 那一侧唯一被允许伸手的：即便是你，也绝不自己写一条 star 条目。

## 核心原则

1. **两个写入者，永远只有两个。** `execs/scpts/import.sh` 拥有 `mates/<slug>/**`——每个上游来源一个 slug，绝不是字面的 `mates/star/`——与每一条 `source-type: star` manifest 条目——重新导入时整体重写。本 skill 拥有 `mates/manual/**` 与每一条 `source-type: manual` 条目——脚本从不碰它们。除此之外没有任何东西写 `mates/`：起草类 skill 不写，随手的人工编辑也不写。来自别处的写入是要报出的缺陷，绝不是要去将就的状态。
2. **证据只读：在上游修，重新导入。** 已登记的文件绝不被编辑——不为错别字，不为四舍五入，不为格式。错的数字是在它的来源处错的：在那里修好（STAR 仓库、原始文档），然后重新导入，或重新投放并重新登记。证据存在的意义，是让草稿里的一个数字可以追溯到草稿之外某个仍然这么说的东西；一次原地编辑就终结了这件事。
3. **没有条目，就没有证据。** `mates/` 下没有 manifest 条目的文件，对写作类 skill 来说并不存在。登记是一次刻意的动作——整份读完、问明出处、钉住时间戳——绝不是把周围躺着的东西一把梭地祝福一遍。
4. **出处是钉住的，不是记住的。** star 条目带着上游路径和 `import.sh` 钉住的 commit；manual 条目带着用户说明的来源、日期、校验和。一条说不出自己的文件哪来的条目，就不写。
5. **管理员不制造数字。** 这里不计算、不聚合、不补任何指标。要求登记一个背后没有文件的数字，一律拒绝：文件先来——而当这个数字住在配对的 STAR 仓库里时，答案是 `import`，不是一次会丢掉时间戳的手工誊抄。
6. **一次刷新就是对论文的一次改动。** 重新导入可能移动草稿已经引用过的数字。因此重写已登记条目的动作在执行前先确认，而被刷新的条目永远路由到 `/skill:stage-tabs-builder`（它的表格刚刚过期）与 `/skill:stage-clms-auditor`（引用它们的主张需要重新核）。证据在写好的句子底下悄悄漂移，正是草稿变成小说的方式。

## 工作流

每种模式都在读或写 manifest 条目，所以条目就是全部接口——`mates/MANIFEST.md` 里每个文件一个 `##` 条目：

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

### Step 0：解析模式与环境

读 `.env`。`STAR_HOME` 有设置且指向一个真实仓库 → star 那一侧是活的；为空或缺失 → `import` 与 star 过期检查不可用，开头就说清楚，而手工证据照样完整可用——配对本就是可选的设计。从第一个记号解析模式；没有 → `check`。

### Step 1：`import` —— 拉取或刷新 star 证据

1. 预览：`bash execs/scpts/import.sh --diff`——相对每条条目钉住的 `upstream-commit`，上游会新增或改动什么，全程不写。
2. 会重写已登记条目的 diff，先用一个 AskUserQuestion 确认，点名每条条目以及会移动的数字——一个被刷新的数字可能悄悄与草稿里已经排好版的句子矛盾（原则 6）。只新增的导入不必提问，直接进行。
3. 跑 `bash execs/scpts/import.sh`，把用户的参数原样透传。写入归脚本所有：绝不重新实现它，也绝不手写一条 star 条目——脚本失败时，该修的是脚本，或者如实汇报，而不是伪造一条条目。
4. 报出新增与被重写的条目；路由在 Step 4。

### Step 2：`register <path>` —— 收编手工投放的证据

1. 整份读完文件——没读过的一律不登记——并用一行说清它实际包含什么；这一行成为 `shows:` 的种子。
2. 不在 `mates/manual/` 下 → 复制进来，原文件不动；重名是一个问题，绝不是一次覆盖。
3. 用一个 AskUserQuestion 问那些任何探测都无从得知的事：`source`——这份东西哪来的（路径、URL 或人）——以及 `shows`；用户的请求里已经把两者都说了就跳过。
4. 算出 `sha256`，写下带 `source-type: manual` 和今天真实日期的 `##` 条目。对已有文件重新登记会就地重写它的条目——一个文件一条条目，记录当前状态，而不是历史。
5. 要求登记一个背后没有文件的数字，一律拒绝（原则 5）：文件先来；而当这个数字住在配对的 STAR 仓库里时，答案是 `import`，不是一次会丢掉时间戳的手工誊抄。

### Step 3：`check` —— 磁盘与 manifest 对账

三项比对，一张报告表；每个非 `ok` 的行都带着修复它的那一条命令：

1. **覆盖面。** `mates/` 下没有条目的文件 → `unregistered`——在 `register` 跑过之前，它对写作类 skill 是隐形的。条目对应的文件不见了 → `missing`——重新导入（star）或重新投放并 `register`（manual）。
2. **完整性。** 每个文件的校验和对着它条目里的 `sha256`。对不上就是 `tampered`：只读规则被破坏了。文件可 diff 时展示改了什么；修法是重新导入或重新投放并重新登记——绝不保留这次编辑，也绝不悄悄把校验和更新成匹配的，那等于把一次篡改洗成了出处。
3. **过期**——star 条目，且 `STAR_HOME` 是活的：`bash execs/scpts/import.sh --diff`；上游已经走过钉住的时间戳 → `stale`，附上刷新命令。manual 条目没有可 diff 的上游——那一侧的"刷新"就是用户重新投放文件——报告要这么说，而不是假装知道。

   完整性与过期是两种检查，谁也替不了谁。`sha256` 对每一条条目都会写，star 与 manual 一视同仁，所以第 2 项能在没有网络、没有 `STAR_HOME`、也没有上游克隆的情况下抓出原地编辑——而那恰恰是一次手工编辑最容易活下来的场景。第 3 项抓的是相反的情况：这边的字节没动，上游却已经往前走了。一条条目完全可能在其中一项上 `ok`、在另一项上失败，报告要点名是哪一项。

其余一律 `ok`。整体干净的检查就报干净然后停下——绝不发明工作。

### Step 4：摘要与路由

≤300 词：各状态计数、本次运行改变了什么、star 那一侧是否是活的，然后是路由——被刷新或新登记的证据 → `/skill:stage-tabs-builder`（由证据建出来的表格刚刚过期）与 `/skill:stage-clms-auditor`（引用被移动条目的主张需要重新核）；需要的是引用而不是文件的主张 → `/skill:stage-refs-curator`。以那条长期规则收尾：写作类 skill 只通过 manifest 消费证据。

## 状态与文件规则

- 写入限于 `mates/`：`mates/MANIFEST.md` 里的 `source-type: manual` 条目、复制到 `mates/manual/` 下的文件，以及只通过运行 `execs/scpts/import.sh` 触及的 star 那一侧。此外哪里都不写。
- 已登记的证据文件绝不被编辑，star 与 manual 都一样（原则 2），并且 `mates/` 下的任何东西都绝不删除：看起来过时的东西列成一个问题，删除是用户在 git 里可见的行为。
- 这里绝不写：`manus/**`、`notes/**`（`claims.md` 是 `/skill:stage-clms-auditor` 的台账，`refs/` 是 `/skill:stage-refs-curator` 的地盘）、`cycls/**`、`wkdrs/**`。这里不跑 LaTeX 构建。
- 只在本地：读文件、算校验和、以及对 `STAR_HOME` 处本地克隆跑脚本——不需要网络，也不用网络。
- 只用真实日期：`imported:` 与每个检查日期都取自系统时钟。
- Git：只读；本 skill 绝不提交。`mates/` 是被跟踪的，所以每一次登记与刷新都会出现在 `git status` 里，由用户去提交。

## 对话纪律

- 只存在两处提问——导入重写确认（Step 1）与登记出处问题（Step 2）——通过 AskUserQuestion，一次调用一个问题。它不可用时（非交互 `kimi -p` 下，无人应答），回落到纯文本，并在写入之前要求一个明确答复。
- 状态怎样就怎么报：`tampered` 就说篡改，附上证据，绝不软化成"改动过"；干净的检查就说干净。报告宣称的与 manifest 记录的，永不分岔。
- 直白地拒绝编造（原则 5），并在同一口气里给出诚实的替代方案：该投放的文件、该跑的 `import`、或者能产出这个数字的那次 STAR 运行。
- 用用户的语言回复；manifest 保持英文；中文回复里路径、哈希、指标名保持英文。
