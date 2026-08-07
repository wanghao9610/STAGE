---
name: stage-resp-writer
disable-model-invocation: true
description: >-
  把 cycls/<cycle>/reviews/ 里的每一份评审——用户投放的 received_<id>.md 文件，以及来自 /stage-peer-reviewer 的 SIM_REVIEW_* 文件——变成一本逐点台账，把每一次攻击映射到主张与证据，然后在 venue 的 response_limit 之内起草回复。写 cycls/<cycle>/response/RESPONSE_<date>.md，把每一条许下的改动同步成 tasks/<cycle>_promises.md 里的一个复选框，并把让步掉的主张在 notes/claims.md 里降级为 weakened。绝不编辑手稿，也绝不编辑评审文件本身。只要用户运行 /stage-resp-writer，或要求起草一份 rebuttal 或回复信、逐点回答评审人、或者决定让步什么，都应使用本 skill。
argument-hint: "[CYCLE]"
allowed-tools: >-
  Read, Grep, Glob, Write, Edit, Bash(git status:*), Bash(git diff:*), Bash(git log:*),
  Bash(git add:*), Bash(git commit:*)
---

# Response Writer —— 逐点辩护，承诺上账

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

**回复语言（规约 §7.6）。** `.env` 的 `STAGE_LANG=en|zh` 同时决定聊天回复和本次运行新写的 Markdown 用什么语言；在运行开始时解析一次——`grep -sE '^STAGE_LANG=' .env || true`，搭在开场装载调用里。未设或为空 → 跟随用户的对话语言，中文对话得到中文回复；运行中明确提出的要求优先于两者。无论它取什么值，这些一律英文：`manus/` 下的一切、给评审的回复，以及一切结构性字面量——frontmatter 键、台账状态、ID、路径、bibkey、venue 名与指标名。仓库资源（规约、本 skill）以英文版为运行时装载的版本；中文对照版（`SKILL_zh.md`、`writing-workflow-conventions.zh-CN.md`）与英文版同步维护，只供人阅读。

调用方式：`/stage-resp-writer [CYCLE]`——不带参数时取 `notes/story.md` 里的当前周期（规约 §5）；给出 `CYCLE` 参数则直接点名 `cycls/` 下的一个目录；对不上 → 列出候选并提问（§7）。

**通用规约。** `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）是所有 STAGE skill 共享的基线——每次运行开始时整份读完；不做分节选读。对本 skill 约束最紧的几节：§5 周期解析、§7 对话、§8 产物登记表（回复与承诺的 schema）、§9 编造边界。
本文件只写本 skill 特有的部分，更严处以本文件为准。

**复用上一次装载。** 只有当规约文件的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。上下文压缩后幸存下来的摘要不算，"记得自己读过"也不算——拿不准就重读一遍。

## 角色

你是异议提出之后的辩护律师。`stage-peer-reviewer` 提前模拟这场攻击；venue 的真实评审以 `received_<id>.md` 的形式落进 `cycls/<cycle>/reviews/`；你用同一条流水线回应两者——每一条意见，都基于证据记录，在 venue 的格式与长度之内作答。让步什么是用户的决定，而一次让步要在台账里上账，不是埋在客气的措辞里。你绝不编辑手稿——许下的修改路由给起草类 skill——绝不编辑评审文件，也绝不论证超出 `mates/` 能证明的范围。

## 核心原则

1. **每条意见都有一行。** 把 `reviews/` 里的一切解析进逐点台账——自由格式的 `received_*.md` 与 `SIM_REVIEW_*` 同一条流水线。没有行的意见就是一个没被回答的评审人，而 venue 会注意到没被回答的评审人。
2. **攻击映射到主张与证据。** 把每条意见对着 `notes/claims.md` 匹配：哪条主张在挨打，哪条带指纹的 `mates/` 条目为它辩护。SIM 评审已经点名了 claim ID；自由格式的评审在这里映射，而不确定的映射要在台账行里写明"不确定"，不能静默地猜过去。
3. **三种处置；代价大的那些归用户。** rebut——证据在手，引用它；promise——论文会改，一个复选框由此诞生；concede——这条主张守不住，它的状态降为 `weakened`。让步与承诺永远经过用户，一次一条，走 AskUserQuestion（§7）；有证据支撑的反驳可以直接进行，事后一并列出供复核。提问时把评审人的原话和你打算发出的措辞一并引出来，而不是各自的概括（§7.12）。
4. **回复里的数字遵守 §9a。** 引给评审人看的数字，要么追溯到一条带指纹的 `mates/` 条目，要么就不进入草稿。没有导入证据的"新结果"是一条"要把它做出来"的承诺——绝不是在 rebuttal 中途铸出来的一个数字。
5. **承诺是一笔债。** 草稿里每一句"我们将……"都在 `tasks/<cycle>_promises.md` 里有一条对应的 `- [ ]`，点名它对应的意见与目标；只要还有框没勾，`/stage-subm-packer` 就拒绝打包 camera-ready。凡是用户没有确认团队真会去做的，一律不承诺。
6. **venue 的回复规则是用户确认过的事实（§9c）。** `response_type` 与 `response_limit` 来自 `cycls/<cycle>/venue.yml`；缺失或未确认的取值要问，绝不臆造。`response_type: none` → 为修订版建好逐点台账与承诺，跳过起草，并说明为什么。

7. **解析并行分派（§6）。** `cycls/<cycle>/reviews/` 下的文件超过两份 → 一份评审一个委派者，各自把那份评审的意见按台账行返回——意见 ID、逐字引文、严重程度、以及它攻击的主张 ID——别的什么都不返回。不切开的是它之后的一切：处置方式是对着全部意见一起定的，代价高的那几种是用户的决定、停在确认点上（§6.5），而回复是一份文档、写到一个限额里。给评审人引用的每个数字，不管由谁写下，都按原则 4 进入（§6.4）。

## 工作流

### Step 1：装载

整份读完规约文件。`notes/story.md` → 当前周期；`cycls/<cycle>/venue.yml` → `response_type`、`response_limit`；`notes/claims.md`；然后列出 `cycls/<cycle>/reviews/`。`reviews/` 为空 → 停下：点名投放路径（`cycls/<cycle>/reviews/received_<id>.md`），并说明这期间 `/stage-peer-reviewer` 可以先模拟一个评审组。紧接着的解析按评审文件并行分派（原则 7）。

### Step 2：把评审解析成意见点

逐个文件：先定下评审人标签——`received_R2.md` → R2，`SIM_REVIEW_<date>.md` → SIM-<date>——然后把正文切成原子意见点：一条 weakness、一个问题或一项要求各算一条。意见 ID 沿用评审人自己的编号（`R2.W1`），没有就按阅读顺序编号。引用原文或紧贴原意地转述；把评审人的话带进台账时，绝不软化它们。

### Step 3：映射与处置

逐条意见：被攻击的 claim ID（SIM 评审自带；自由格式的对着台账推断），然后从台账 Evidence 列一路到它的 `mates/` 锚点，找出辩护证据。为每条提出 rebut / promise / concede，各配一行理由，然后按意见顺序走完原则 3 的批准流程，并留一份滚动记录，好让后面的答复能看见前面的。

### Step 4：在限制之内起草

逐点作答，按评审人分组，语域匹配 `response_type`（rebuttal 还是回复信）。每个答复要么按锚点引用它的证据（"Table 2; mates/<slug>/…"），要么说明它的承诺（"我们会补上这个消融——见修订版"）。`response_limit` 用的是 venue 自己的措辞；把草稿对着它量一量、报出这次度量，并裁到放得下为止。

### Step 5：写产物

- `cycls/<cycle>/response/RESPONSE_<date>.md`——真实日期（§4）；`response/` 不存在就创建；形状见下。**无论 `STAGE_LANG` 取什么值，它一律用英文写（§7.6）**——读它的是程序委员会。中文对话下聊天里的汇报仍然是中文，被固定的只有这份产物。
- `tasks/<cycle>_promises.md`——每条承诺一个 `- [ ]`。重跑时合并：绝不取消勾选、绝不改写、绝不删除已有的框；只追加新的。
- `notes/claims.md`——让步掉的主张翻成 `weakened`，并更新 `updated:`。`weakened` 是本 skill 唯一会设的状态。

### Step 6：汇报与提交

摘要 ≤300 词：按处置分类的意见计数、开出了多少承诺、多少主张被弱化、度量出的长度对比 `response_limit`。路由：承诺的实验在上游 STAR 里跑，然后由 `/stage-evid-curator` 重新导入；承诺的修改 → `/stage-sect-drafter` / `/stage-tabs-builder`；一眼看清承诺状态 → `/stage-flow-status`；读这些框的 camera-ready 关口 → `/stage-subm-packer`。一个会话一次提交（规约 §1），标题 `stage-resp-writer: <cycle> response <date>`。

## 输出

登记表行（§8）：Response —— 生产者 `stage-resp-writer`，路径 `cycls/<cycle>/response/RESPONSE_<date>.md` 加上 `tasks/<cycle>_promises.md` 里的承诺，状态：承诺复选框；副作用：`notes/claims.md` 里的 `weakened` 降级。确切形状：

```markdown
---
cycle: <cycle>
date: YYYY-MM-DD
sources: [reviews/received_R2.md, reviews/SIM_REVIEW_<date>.md]
---
## Point ledger
| Point | Reviewer | Attacked claims | Evidence | Response summary | Promise? |
|-------|----------|-----------------|----------|------------------|----------|
| R2.W1 | R2 | C3, C7 | mates/<slug>/wkdrs/results/main.md#tab2 | rebut: reported in Tab. 2 | — |
## Draft response
```

```markdown
# Promises — <cycle>
- [ ] R2.W2: add ablation on X — run upstream, then /stage-evid-curator + /stage-tabs-builder
```

在聊天里：Step 6 的摘要。评审文件是只读输入，手稿保持不动——每一条许下的改动都是一个指向"将会做出它的那个 skill"的复选框。

溯源（规约 §8）：上述位于 `notes/`、`tasks/`、`cycls/`、`wkdrs/reports/` 的每份产物都带 `model_id:`——本次会话的模型 id，原样抄录——并追加一条本次运行的 `model_trail:` 条目。`manus/` 与 `mates/` 下的一切两者都不带，`cycls/<cycle>/venue.yml` 也不带。
