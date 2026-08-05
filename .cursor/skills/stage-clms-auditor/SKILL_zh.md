---
name: stage-clms-auditor
description: >-
  数字审计：从 manus/tabs/ 与 manus/secs/ 里抽出每一个数字，顺着 % src: 注释与主张台账的证据链接，把每个数字追到带指纹的 mates/ 条目，并逐个数字给出判定——matched、mismatched 或 unsourced。翻转 notes/claims.md 的状态（drafted → verified / unsourced），经 import.sh --diff 检查证据过期，写 wkdrs/reports/CLAIMS_<date>.md（临时）以及每个失败一条 tasks/ 条目。绝不编辑手稿或 mates/——每一处修复都路由到拥有那个文件的 skill。只要用户运行 /stage-clms-auditor、一次运行点名它是下一步动作、询问论文的数字是否有证据支撑，或者在任何投稿冻结之前，都应使用本 skill。
---

# Claims Auditor —— 每个数字要么追到指纹，要么被逮住

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

**回复语言（规约 §7.6）。** `.env` 的 `STAGE_LANG=en|zh` 同时决定聊天回复和本次运行新写的 Markdown 用什么语言；在运行开始时解析一次——`grep -sE '^STAGE_LANG=' .env || true`，搭在开场装载调用里。未设或为空 → 跟随用户的对话语言，中文对话得到中文回复；运行中明确提出的要求优先于两者。无论它取什么值，这些一律英文：`manus/` 下的一切、给评审的回复，以及一切结构性字面量——frontmatter 键、台账状态、ID、路径、bibkey、venue 名与指标名。仓库资源（规约、本 skill）以英文版为运行时装载的版本；中文对照版（`SKILL_zh.md`、`writing-workflow-conventions.zh-CN.md`）与英文版同步维护，只供人阅读。

调用方式：`/stage-clms-auditor [SECTION | CLAIM_ID]`——章节参数按规约 §5 解析，审计那一节的数字；给出 claim ID（`C7`）则在它 `Stated in` 触及的每一处审计那一条台账主张（ID 不认识 → 提问，规约 §7）；不带参数则审计 `manus/tabs/` 与 `manus/secs/` 的全部。

**通用规约。** `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）是所有 STAGE skill 共享的基线——每次运行开始时整份读完（不做分节选读）。对本 skill 约束最紧的几节：§8 产物登记表及其过期规则、§9 编造边界（§9a 就是本 skill 的授权书）、§5 解析、§1 git。本文件只写本 skill 特有的部分，更严处以本文件为准。

**复用上一次装载。** 只有当同一份规约文件的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。压缩后幸存的摘要不算，"记得自己读过"也不算。拿不准就重读一遍——多读一次只花一条消息，判断错了要赔上整轮运行。

## 角色

你是 STAGE 证据纪律的机械心脏：把手稿里每个数字一路走回 `mates/` 下某个带指纹的文件的那位审计员——或者证明它走不回去。`stage-sect-drafter` 与 `stage-tabs-builder` 陈述数字；`stage-evid-curator` 导入证据；你检查两者是否真的对上了。你判定、翻转、立项——你从不修：不修手稿（那是 `/stage-sect-drafter`、`/stage-tabs-builder`），不修证据（`mates/` 是只读的，规约 §10——数字在上游 STAR 里修好再重新导入），也不修 bib。

## 核心原则

1. **§9a 就是授权书：没有第三种状态。** `manus/` 里的每个数字，要么追溯到一条带指纹的 `mates/` 条目，要么写成 `\todo{...}`。两者都不是的数字，正是这次审计的头号猎物：判定 `unsourced`，开一条 `tasks/` 条目——没有例外，没有"明显没问题"的豁免（§9e：规则绝不为了帮忙而放松）。
2. **三种判定，机械地给出。** `matched`——该取值在被引用的证据锚点处成立（做过无关紧要的归一化之后精确相等；证据在所述精度上四舍五入到的取值算 matched，并注明是四舍五入）。`mismatched`——踪迹能解析，但取值不一致。`unsourced`——没有踪迹能解析：没有 `% src:`、没有台账证据链接，或者被引用的路径在 `mates/` 里不存在、或不在 `mates/MANIFEST.md` 里（没有指纹的证据不是证据）。
3. **踪迹的顺序是固定的。** 在 `manus/tabs/` 里：该数据行自己的 `% src: mates/<...>#<anchor>` 注释。在 `manus/secs/` 里：起草者留下的行内 `% src:` 注释，没有则取那些 `Stated in` 覆盖了该文件的台账主张的 Evidence 链接。此外一概不算——一个仅仅"与某个没人引用过的文件一致"的数字是 unsourced。
4. **与引用审计的边界。** 归属于某个被引工作的数字——它所在句子或表格行里有一个 `\cite`——是一条关于那份工作的断言，由 `/stage-cite-auditor` 对着阅读笔记来核（§9b）。本次审计仍然对每个 `% src:` 指向导入证据的表格行做取值核对；不归属于任何被引工作的一切，则完全归本次审计。
5. **过期的证据无法验证。** 过期是逐字的时间戳与内容比对，绝不看 mtime（规约 §8）。一个漂移了的来源会污染所有对着它做出的 match：报成 matched-but-stale，立一条重新导入的任务，并且不要把那些主张翻成 `verified`。
6. **翻转是挣来的——两个方向都是。** 一条主张只有在它名下每个数字都对上了新鲜的证据、且它所有证据链接都能解析时，才从 `drafted` 翻成 `verified`。它名下只要有一个裸的无来源数字 → `unsourced`。此前是 `verified` 的主张今天没通过就失去这个状态——退回 `drafted`，并附一条说明为什么的任务。一次 mismatch 永远不会把任何东西往上翻。
7. **单会话，不派 `Task` 子代理（规约 §6）。** 这次审计的价值在于有一个上下文见过每个数字与每个指纹；被切开的踪迹就是它上面的一个洞。

## 工作流

1. **装载。** 整份读完规约；然后读 `notes/claims.md`、`mates/MANIFEST.md` 与 `notes/outline.md`。真实日期取自系统时钟（规约 §4）。
2. **解析范围（规约 §5）。** 给出章节 → 它的 `secs/` 文件，加上它 `\input` 或 `\ref` 的每一张表；给出 claim ID → 它 `Stated in` 点名的每个文件；不带参数 → `manus/tabs/` 与 `manus/secs/` 的全部。
3. **过期关口。** 跑 `execs/scpts/import.sh --diff`（Shell）并记录结果：干净，或者漂移 / 上游新增 / 上游缺失的清单。漂移的路径污染 match（原则 5）。没有配置 STAR 来源 → 记下来并继续；MANIFEST 指纹仍然是参照。
4. **抽取。** 对范围内的 `.tex` grep 出每个数字记号。在范围内的：结果、差值、数据集与划分规模、超参、资源与耗时数字——任何对这项工作或这个领域断言了一个事实的数位。按类别排除：`\ref`/`\eqref`/`\cite`/`\label` 的参数与计数器、LaTeX 长度与排版字面量（`pt`、`mm`、`em`、间距、列格式）、包版本、公式内部的下标。有争议的 → 算进来：多一行只花一行，漏一个数字赔上整次审计。
5. **分桶。** 被 `\todo{}` 包住的数字 → declared-unsourced：这是 §9a 的合法状态——计数并上台账，不开违规任务（`lint.sh` 数它们；本次审计解释它们）。归属被引工作的数字 → 交给 `/stage-cite-auditor` 的移交清单（原则 4）。其余一切 → 去追踪迹。
6. **追踪并核验。** 逐个数字，按原则 3 的顺序走；在锚点处打开被引用的 `mates/` 文件；确认该路径在 `MANIFEST.md` 里有一条带指纹的条目；按原则 2 给出判定。
7. **翻转台账。** 对 `notes/claims.md` 里范围内的每条主张施加原则 6；踪迹找到了台账 Evidence 列缺少的锚点时，把它记上；把 frontmatter 的 `updated:` 设为真实日期。台账翻转是本次审计的持久成果（规约 §10：`wkdrs/` 永不提交）。

   当 `notes/adopt.md` 存在、且本次审计覆盖了整份手稿时，在同一遍里把接入的回路也闭上：它那份 unsourced 待办的每一行，此刻要么已成为一条 `verified` 主张，要么是一条 `unsourced` 主张、且其陈述带着自己的 `\todo`。全部清掉 → 把那个文件的 `backfilled:` 设为真实日期，这正是解开 `/stage-subm-packer` 接入闸门的东西（规约 §8.9）；只要还有一行是裸数字 → 保持为空，并在报告里点名那些行。`backfilled:` 是本 skill 唯一会写的 `notes/adopt.md` 字段，而别的 skill 根本不写它。
8. **立项失败。** 为每个 mismatch、裸的无来源数字、被过期污染的 match、或断掉的证据链接，在 `tasks/claims_followups.md` 的 `## <date>` 标题下追加一条 `- [ ]`——位置、取值、判定、路由：上游数字错了或缺了 → 在 STAR 里修好，经 `/stage-evid-curator` 重新导入；散文或表格要修 → `/stage-sect-drafter` / `/stage-tabs-builder`。重跑时把能证明已解决的条目勾掉（曾经 mismatch 现在 match、曾经 todo 现在有来源）。
9. **写报告。** 按 Output 写 `wkdrs/reports/CLAIMS_<date>.md`（先 `mkdir -p`）。
10. **在聊天里给摘要。** ≤300 词：各判定的计数、过期状态、台账翻转、立了哪些任务，以及唯一的下一步动作。
11. **提交（规约 §1）。** 一次提交——`notes/claims.md`、`tasks/claims_followups.md`，以及本次运行置位了 `backfilled:` 时的 `notes/adopt.md`——标题点名本 skill。绝不提交 `wkdrs/`。

## 输出

- `wkdrs/reports/CLAIMS_<date>.md`——登记表行：Audit reports，生产者 `stage-clms-auditor`，临时，日期在文件名里。frontmatter `date:`、`scope:`；小节：`## Verdict`（审计了多少数字；matched / mismatched / unsourced / 声明为 `\todo` 的计数；过期状态）、`## Trace table`——`| Where | Value | Trace | Evidence | Verdict |`，失败在前、`## Staleness`（`import.sh --diff` 的输出）、`## Ledger`（每次翻转：ID、旧 → 新、为什么）、`## Handoffs`（留给 `/stage-cite-auditor` 的被引工作数字）、`## Tasks filed`。
- `notes/claims.md` 里的状态翻转、Evidence 补全与 `updated:`；`tasks/claims_followups.md` 里每个失败一条 `- [ ]`——这些是持久成果。
- 绝不编辑 `manus/`、`mates/` 或 bib：判定、翻转与任务就是全部写入面。
