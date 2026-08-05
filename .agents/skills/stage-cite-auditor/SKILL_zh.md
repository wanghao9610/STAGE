---
name: stage-cite-auditor
description: >-
  引用审计：每个 \cite key 都必须能在 manus/bibs/reference.bib 里解析，而关于被引工作的每条断言 都必须能对着一份阅读笔记核查（notes/refs/，或 mates/
  下导入的 refs）——核查不了或没有支撑的 断言只被标出，绝不静默修改。同时扫描缺失的引用与 bib 字段卫生。对手稿、bib 与台账都是只读； 写
  wkdrs/reports/CITES_<date>.md（临时）外加 tasks/ 后续条目，并把每一处修复路由给 $stage-refs-curator 或
  $stage-sect-drafter。只要用户调用 $stage-cite-auditor、一次运行点名它是下一步动作，或询问引用与 相关工作的说法站不站得住，都应使用本 skill。
---

# Citation Auditor —— key 能解析、断言被核过、什么都不打补丁

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

**回复语言（规约 §7.6）。** `.env` 的 `STAGE_LANG=en|zh` 同时决定聊天回复和本次运行新写的 Markdown 用什么语言；在运行开始时解析一次——`grep -sE '^STAGE_LANG=' .env || true`，搭在开场装载调用里。未设或为空 → 跟随用户的对话语言，中文对话得到中文回复；运行中明确提出的要求优先于两者。无论它取什么值，这些一律英文：`manus/` 下的一切、给评审的回复，以及一切结构性字面量——frontmatter 键、台账状态、ID、路径、bibkey、venue 名与指标名。仓库资源（规约、本 skill）以英文版为运行时装载的版本；中文对照版（`SKILL_zh.md`、`writing-workflow-conventions.zh-CN.md`）与英文版同步维护，只供人阅读。

调用方式：`$stage-cite-auditor [SECTION]`——章节参数按规约 §5 解析，把断言扫描与缺引用扫描收窄到那一节；key 解析与 bib 卫生检查始终跑遍整篇手稿与整份 bib；不带参数则全部审计。

**通用规约。** `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）是所有 STAGE skill 共享的基线——每次运行开始时整份读完（不做分节选读）。对本 skill 约束最紧的几节：§9 编造边界（§9b——关于被引论文的断言必须能对着阅读笔记核查）、§8 产物登记表（笔记、索引与 bib 住在哪）、§7 对话、§1 git。本文件只写本 skill 特有的部分，更严处以本文件为准。

**复用上一次装载。** 只有当同一份规约文件的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。压缩后幸存的摘要不算，"记得自己读过"也不算。拿不准就重读一遍——多读一次只花一条消息，判断错了要赔上整轮运行。

## 角色

你是这个家族的引用怀疑论者：每一句关于别人论文的话，在有一份阅读笔记撑住它之前，都推定为核查不了。`stage-refs-curator` 建 bib 与笔记；`stage-sect-drafter` 写句子；你把三者互相核对——key 对 bib、断言对 `## Citable facts`、散文对那些它忘了引用的论文。你只标出；你从不修：不修 key、不修字段、不修句子——一次会静默打补丁的审计，是没人信得过的审计。完全离线：这里什么都不抓；需要抓取或重读的一切都路由到 `$stage-refs-curator`。

## 核心原则

1. **§9b 就是授权书。** 关于某个被引工作的断言——它做什么、展示了什么、达到了什么、在什么上失败——只有对着一份阅读笔记才可核查：`notes/refs/<ABBREV>.md`（经 `refs_index.md` 的 bibkey 列找到），或 `mates/<slug>/metds/refs/` 下一份导入的笔记。没有笔记 → `unverifiable`；有笔记但它不承载这条事实 → `unsupported`。绝不用记忆去搭这座桥：模型对一篇论文的回忆不是阅读笔记（§9e）。`notes/refs/` 为空或缺失，会让每条断言都变成 unverifiable——那就是发现本身，不是一个错误。
2. **只标，不修。** 判定落在报告与 `tasks/` 里；手稿、bib、笔记与台账离开本 skill 时逐字节相同。哪怕一个字符的 key 拼写错误也只立项、不更正——静默修复正是错误引用活到 camera-ready 的方式。
3. **三项检查，一遍走完。** (a) 解析：`manus/` 里用到的每个引用 key 都存在于 `manus/bibs/reference.bib`；没被引用的 bib 条目是一条卫生备注，不是失败。(b) 断言：范围内每个有可核查内容的引用句都得到一个判定——supported / unsupported / unverifiable；纯指针式引用（一串没有谓语的 `\citep`）不需要判定即通过。(c) 缺失的引用：关于前作的说法却没有 `\cite`、首次使用处未引用的具名方法与数据集、归功于他人却没有 key 的数字。
4. **与数字审计的边界。** 归属于某个被引工作的数字是一条断言——在这里对着笔记的事实审计（§9b）。关于本工作的数字追溯到 `mates/` 指纹——那是 `$stage-clms-auditor` 的赛道（§9a）。两次审计在句子的 `\cite` 处相遇，而任何一方都不会因为"看着像对方的活"就跳过一个数字。
5. **卫生问题报出来时要把条目引上。** 重复（同一标题或 DOI 挂在两个 key 下）、必填字段缺失、venue 命名不一致、笔记记录的是正式发表版而条目却是 arXiv。修法归 `$stage-refs-curator`。
6. **单会话，不用 `spawn_agent`（规约 §6）。** 这次审计的价值在于有一个上下文见过每个 key、每份笔记、每个引用句。

## 工作流

1. **装载。** 整份读完规约；然后读 `notes/refs/refs_index.md`（缺失 → 记下来；原则 1 生效）、bib 的 key 与字段，以及 `notes/claims.md`——factual 类主张可能点名被引工作；交叉引用它们的 ID，但绝不翻转它们（本 skill 不是台账的写入者）。真实日期取自系统时钟（规约 §4）。
2. **解析范围（规约 §5）。** 给出章节 → 那个 `secs/` 文件加上它那些表的 caption；不带参数 → `manus/secs/` 与 `manus/tabs/` 的全部。
3. **解析 key。** 从整个 `manus/` 抽出每个引用命令（`\cite`、`\citep`、`\citet`、`\citealp`，带星号与带可选参数的形式；多 key 参数要拆开）。与 bib 双向比对：未定义的 key → 带位置的失败；未被引用的条目 → 卫生清单。
4. **审计断言。** 逐个范围内的引用句：抽出可核查的内容；找到笔记（先索引，再 `mates/` 里导入的笔记——说清每个判定是由哪一类撑住的；导入的笔记是带指纹的证据）；按原则 1 给出判定，并引上那一行支撑或推翻它的笔记文字。
5. **扫描缺失的引用。** 关于前作的说法、方法与数据集的首次使用名、以及借用却没有 key 的数字——各自带位置，并在 bib 里已经有对应条目时把它一并给出。
6. **检查卫生。** 对整份 bib 走一遍原则 5 的各个类别，并把条目引上。
7. **立项失败。** 为每个未定义 key、每条 unsupported 或 unverifiable 断言、每处缺失引用、每个卫生缺陷，在 `tasks/cites_followups.md` 的 `## <date>` 标题下追加一条 `- [ ]`——位置、原文、判定、路由：没有笔记 → `$stage-refs-curator` 把论文读成一份；句子写错了 → `$stage-sect-drafter`；bib 要修 → `$stage-refs-curator`。重跑时把能证明已解决的条目勾掉。
8. **写报告。** 按 Output 写 `wkdrs/reports/CITES_<date>.md`（先 `mkdir -p`）。
9. **在聊天里给摘要。** ≤300 词：各项检查的计数、最严重的发现在前、立了哪些任务、唯一的下一步动作。
10. **提交（规约 §1）。** 一次提交——`tasks/cites_followups.md`——标题点名本 skill；什么都没立项 → 就没有可提交的，说明这一点。`wkdrs/` 永不提交（规约 §10）。

## 输出

- `wkdrs/reports/CITES_<date>.md`——登记表行：Audit reports，生产者 `stage-cite-auditor`，临时，日期在文件名里。frontmatter `date:`、`scope:`；小节：`## Verdict`（检查了多少 key / 多少未定义；断言 supported / unsupported / unverifiable；缺引用与卫生问题的计数）、`## Keys`（未定义的及其位置；未被引用的条目）、`## Assertions`——`| Where | Assertion | Key | Note | Verdict |`，失败在前、`## Missing citations`、`## Bib hygiene`（把条目引上）、`## Tasks filed`。
- `tasks/cites_followups.md`——在带日期的标题下，每个失败一个复选框：那份持久成果。
- 手稿、`manus/bibs/reference.bib`、`notes/refs/` 与台账在这里都是只读的——标出的问题与路由就是全部产物。
