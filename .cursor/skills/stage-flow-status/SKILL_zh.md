---
name: stage-flow-status
description: >-
  整条写作流程的只读地图：从 notes/outline.md 读出每节、每图、每表的状态，按台账状态统计主张覆盖，对着上游时间戳检查证据新鲜度，参考文献计数，周期状态（venue 是否确认、评审是否到齐、回复是否起草、承诺是否未清、是否已冻结），最近一次构建与 lint 信号，以及恰好一个下一步动作连同它确切的 /stage-* 命令。只在聊天里汇报，并把每个动作指向拥有它的那个兄弟 skill。只要用户运行 /stage-flow-status、一次运行点名它是下一步动作，或询问论文进展到哪、接下来该做什么、证据或构建是否新鲜、当前周期走到了哪一步，都应使用本 skill。绝不写任何文件。
---

# Writing Flow Status — 只读总览

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

**回复语言（规约 §7.6）。** `.env` 的 `STAGE_LANG=en|zh` 同时决定聊天回复和本次运行新写的 Markdown 用什么语言；在运行开始时解析一次——`grep -sE '^STAGE_LANG=' .env || true`，搭在开场装载调用里。未设或为空 → 跟随用户的对话语言，中文对话得到中文回复；运行中明确提出的要求优先于两者。无论它取什么值，这些一律英文：`manus/` 下的一切、给评审的回复，以及一切结构性字面量——frontmatter 键、台账状态、ID、路径、bibkey、venue 名与指标名。仓库资源（规约、本 skill）以英文版为运行时装载的版本；中文对照版（`SKILL_zh.md`、`writing-workflow-conventions.zh-CN.md`）与英文版同步维护，只供人阅读。

调用方式：`/stage-flow-status [SECTION]`——不带参数汇报整条流程；带章节参数时，按规约 §5 以编号、文件 slug 或标题对着 `notes/outline.md` 解析，把提纲面板与主张明细收敛到该节。`involve=<level>` 记号在解析 SECTION 之前就被剥离（§7），除此之外在这里不改变任何行为。章节参数有歧义是本 skill 唯一可以问的问题（§5）；除此之外它什么都不问。

**通用规约。** 每次运行开始时整份读完 `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）——不做分节选读。它是所有 STAGE skill 共享的基线；对本 skill 约束最紧的是 §0 词汇表、§5 章节与周期解析、§7 对话纪律里的汇报规则、以及 §8 产物登记表连同它的过期判定规则。本文件只写本 skill 特有的部分，更严处以本文件为准。

**复用上一次装载。** 只有当规约文件本身的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。上下文压缩后幸存下来的摘要，以及"记得自己读过"，两者都不满足这个判据——拿不准就重读一遍；多读一次只花一条消息，判断错了要赔上整轮运行。

## 角色

你给作者一张诚实的全景图——提纲、主张、证据、周期、构建各自到哪了——以及一条清晰的"下一步该干什么"的建议。你是地图，不是司机：coach 塑形故事、planner 拆分它、drafter 写、审计类 skill 做判断、packer 冻结——你只读与汇报。你什么都不改，不跑任何会写入的东西，也绝不把猜测当成状态呈上。

## 核心原则

1. **严格只读。** 绝不创建、编辑或删除任何文件——不动提纲、不动台账、不动 frontmatter——也绝不提交。除了 §5 那唯一一个消歧问题之外：不用 AskQuestion、不进 plan 模式、不派 `Task` 子代理。用户想据此行动，就把他们指向对应的 skill：/stage-proj-adopt、/stage-evid-curator、/stage-stry-coach、/stage-outl-planner、/stage-sect-drafter、/stage-tabs-builder、/stage-figs-designer、/stage-refs-curator、/stage-copy-editor、/stage-clms-auditor、/stage-cite-auditor、/stage-peer-reviewer、/stage-resp-writer、/stage-subm-packer。
2. **文件是唯一依据。** 汇报的一切都来自登记表（§8）里的产物：`notes/`、`mates/MANIFEST.md`、`manus/`、`cycls/<cycle>/`、`tasks/`，以及 `wkdrs/builds/` 与 `wkdrs/reports/` 的目录清单。绝不凭对话记忆推断进度；字段缺失就报"unknown"，不要猜。
3. **确定性信号来自脚本，且只用它们的只读模式。** 证据新鲜度：`STAR_HOME` 有设置时跑 `execs/scpts/import.sh --diff`（按约定只读），否则报 unknown——过期是时间戳比对，绝不看 mtime（§8）。构建与 lint：点名 `wkdrs/builds/` 下最新的产物，存在时跑 `execs/scpts/lint.sh --no-build` 取当前把关信号——它什么都不写；绝不触发一次新的构建。
4. **要计数，不要长篇；沉默是默认。** 面板就是一行行和一串串计数。缺口行只在它的触发条件成立时才出现——进行中的工作现在还不需要什么，而一个连健康状态也要报的检查，只会教会读者跳过它。
5. **只给一条建议，由优先级顺序选出。** 以单一的下一步动作及其确切的 /stage-* 命令收尾，由 Workflow 第 7 步选出——不是一份菜单。其余尚未了结的事情留在缺口行里。没有任何一条够格时，点名那个卡点。

## 工作流

1. **装载。** 整份读完规约，然后扫描登记表里的产物：`notes/story.md`、`notes/outline.md`、`notes/claims.md`、`notes/notation.md` 的 frontmatter 与状态表；`mates/MANIFEST.md` 条目；`notes/refs/refs_index.md` 的行对着 `manus/bibs/reference.bib` 的 key；当前周期的 `venue.yml`、`reviews/`、`response/` 与 `SUBMISSION_*`；`tasks/<cycle>_promises.md`；`manus/secs|figs|tabs` 与 `wkdrs/builds|reports` 的目录清单；`git tag -l 'freeze/<cycle>_*'`（只读）。给了 SECTION 就解析它（§5）。
2. **周期状态。** 一行：周期名；`confirmed:` 是否已设；评审是否在位（`SIM_*` 与 `received_*` 计数）；回复是否存在；承诺未清/总数；是否已冻结（tag 或 SUBMISSION 文件）。没有 story 文件 → 流程还没开始；说出来，直接跳到第 7 步。
3. **提纲面板。** Sections、Figures、Tables 按状态计数（planned / skeleton / drafted / polished / frozen；planned / sketch / draft / final），限定了 SECTION 时给出逐行明细。某行对应的文件在磁盘上不存在，或某个文件没有对应行，都是漂移——标出来，绝不修它。
4. **主张覆盖。** 台账按状态计数：proposed / drafted / verified / unsourced / weakened / dropped。`unsourced > 0` 永远是一条点名 /stage-clms-auditor 的缺口行。
5. **证据与参考文献。** MANIFEST 条目数与最新的 `imported:`；`import.sh --diff` 的结论（clean / drifted / unknown）；bib key 对着 refs 索引行——被引用却没有阅读笔记的工作是 /stage-refs-curator 的活。
6. **构建与 lint。** `wkdrs/builds/` 下最新的 PDF（或 `build: none`）；按原则 3 取 lint 把关信号。
7. **下一步动作。** 首个命中者胜出：(1) 没有 `notes/adopt.md` → /stage-proj-adopt；(2) story 缺失或未定稿 → /stage-stry-coach；(3) 提纲缺失或未定稿 → /stage-outl-planner；(4) 证据漂移 → /stage-evid-curator；(5) 有未清承诺 → 第一个未勾选框所需改动对应的 skill（/stage-sect-drafter、/stage-tabs-builder、/stage-figs-designer）；(6) 提纲里仍是 planned / skeleton / sketch 的行 → 上述三者中它的归属者，并点名是哪一行；(7) 主张处于 `unsourced`，或 `drafted` 却从未验证 → /stage-clms-auditor；(8) 所有行都已 drafted，但最新的 `CITES_*` / `POLISH_*` 报告日期落后于提纲的 `updated:` → 先 /stage-cite-auditor，再 /stage-copy-editor；(9) 本周期还没有模拟评审 → /stage-peer-reviewer；(10) 全绿 → /stage-subm-packer。给出一行理由和确切命令。当这条命令落在那十个 agent 可以自己启动的 skill 上、且目标已经定死时，它会在这份报告写完之后被直接拾起来跑，而不是留给作者去敲——本 skill 自己不启动任何东西（规约 §11.4）。

   **红闸门压过这张表。** 当第 6 步发现 `lint.sh` 硬失败时——构建坏了、一个会被印进 PDF 的 `\todo{`、页数超限、`ANON=true` 下的身份泄漏——那就是下一步动作，无论上面哪条编号命中，并路由给 lint 自己点名的归属者：标记归 `/stage-sect-drafter` 或 `/stage-tabs-builder`，超页归 `/stage-copy-editor`，未定义引用归 `/stage-cite-auditor` 或 `/stage-refs-curator`。红闸门下游的任何事都不值得推荐——`/stage-subm-packer` 会拒绝它，而对一份编译不出来的手稿做模拟评审，评的是错的产物。闸门转绿后这张表继续生效。
8. **汇报并停下。** 按 Output 的顺序渲染，然后停下：绝不写、绝不提交——同样地，绝不声称或暗示有任何东西被改动过。

## 输出

登记表行（规约 §8）：Status —— 磁盘上没有产物；只读，在聊天里汇报；没有状态字段。

汇报顺序：周期状态 → 提纲面板 → 主张覆盖 → 证据与参考文献 → 构建与 lint → 缺口行（一条都没触发就省掉）→ 唯一的下一步动作，连同它确切的 /stage-* 命令与理由。用紧凑的表格与计数，绝不逐行写散文；字段缺失处写 "unknown"；整条回复控制在约 500 词以内。
