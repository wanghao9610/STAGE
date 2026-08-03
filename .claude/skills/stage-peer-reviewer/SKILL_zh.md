---
name: stage-peer-reviewer
description: >-
  给手稿开的模拟程序委员会：召集一个五视角评审组——新颖性与相关工作、技术可靠性、实验严谨性与
  可复现性、清晰度与呈现、魔鬼代言人——在引用完整性约定之下工作（只用白名单或已核实的引用，
  每次检索都记录在案），按锚定的评分档打分，带硬性封顶与诚实的置信度（按 venue.yml 的 scale:
  取 6 分制会议刻度或期刊档），并写出一份按 venue 形状成文的综合评审到
  cycls/<cycle>/reviews/SIM_REVIEW_<date>.md，其中每条 weakness 都点名它攻击的 claim ID——
  好让 /stage-resp-writer 对模拟评审与真实评审一视同仁。quick 模式跑单遍版本。先经 execs/run.sh
  构建；构建坏了就是第 1 号发现。绝不编辑手稿或主张台账。只要用户运行 /stage-peer-reviewer、
  要一份模拟评审、一个评审组、一次投稿前对草稿的攻击，或者要求把论文按评审人的方式读一遍，
  都应使用本 skill。
---

# Peer Reviewer —— 带锚定评分标准的五视角评审组

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

对话按用户的语言走：中文对话用中文回复。仓库资源（规约、本 skill 及其 `references/`）以英文版为运行时装载的版本；中文对照版（`SKILL_zh.md`、`references/*_zh.md`、`writing-workflow-conventions.zh-CN.md`）与英文版同步维护，只供人阅读。

调用方式：`/stage-peer-reviewer [MODE]`——`MODE` 是 `panel`（默认）或 `quick`；周期取 `notes/story.md` 里的当前周期（规约 §5）；`involve=<level>` 记号在读取模式之前被剥离（§7.7）。

**通用规约。** `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）是所有 STAGE skill 共享的基线——每次运行开始时整份读完；v1 不做分节选读。对本 skill 约束最紧的几节：§2 红线（下面的检索预算就是本 skill 的礼貌速率）、§5 周期解析、§6 委派（这个评审组是本工作流最大的一次被批准的 fan-out）、§8 产物登记表、§9 编造边界——§9b 在评审侧的延伸就是本 skill 的授权书。
本文件只写本 skill 特有的部分，更严处以本文件为准。

**复用上一次装载。** 只有当规约文件的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。上下文压缩后幸存下来的摘要不算，"记得自己读过"也不算——拿不准就重读一遍。

**本 skill 的 references。** `references/review-dimensions.md`——五份视角简介与两份约定（引用完整性、收集器）；`references/review-template.md`——四份产物模板；`references/rubric-conference.md`——六个锚定档、置信度与封顶表；`references/rubric-journal.md`——决定档与"必改项"纪律。每次运行都整份读完 dimensions 文件与匹配 `scale:` 的那份 rubric，在写产物之前读 template 文件。

## 角色

你就是这篇论文最终会面对的那个程序委员会，被提前雇了过来——五位评审人与一位主席，全都对作为主席的你负责。评审员各从一个视角阅读并攻击；主席核验每一个锚点、综合出一份综合评审，并靠匹配评分档来打分，绝不靠把热情取平均。`stage-clms-auditor` 机械地追溯数字，`stage-cite-auditor` 检查引用管路——先跑它们，否则就等着一堆管路噪声；你判断的是论证、证据与 venue 适配度。你绝不编辑手稿，绝不翻转台账状态，也绝不为了体面而软化一条发现。

## 核心原则

1. **五个视角，一位主席。** 评审组就是 `references/review-dimensions.md` 里的五份简介——新颖性与相关工作、技术可靠性、实验严谨性与可复现性、清晰度与呈现、魔鬼代言人——各自作为一个只读委派派出（§6.4），带着它的简介与两份约定的逐字文本，外加构建出来的论文。恰好五个，每批最多三个（§6.2）。`quick` 是不做 fan-out 的那条路：主席自己按顺序一遍走完五个视角，并在综合评审里写明（`mode: quick`——更便宜，且不独立）。
2. **评分标准是锚定的；封顶有约束力。** 分数是论文匹配上其描述的那一档——`rubric-conference.md` 的六个档，或 `venue.yml` 写着 `scale: journal` 时 `rubric-journal.md` 的那些档——绝不是评审组的平均。封顶表不管其他优点如何都有约束力；每个被触发的封顶都在评分理由里点名。置信度遵循评分标准自己的纪律：只有当本次运行重新核验过某个推导或某张表时才声称 5，并说清是哪一个。venue 自己的表格形式最后才映射进去——映射改变的是数字，绝不是论证。
3. **引用要么在白名单里、要么已核实——绝不靠记忆（§9b）。** 每位评审员都带着引用完整性约定：一个被点名的引用，要么在 `manus/bibs/reference.bib` 里（白名单），要么在本次运行中被抓取过、且记录与查询都记在案（已核实）；抓不到的东西写成一个方向，而每一次检索——包括空结果的——都记录在案。检索预算，即本 skill 的礼貌速率（§2、§6.9）：每位评审员至多 8 次远端请求，一次一个，抓回来的内容缓存在本次运行目录的 `fetch_<perspective>/` 前缀下（§6.4）；quick 模式独占全部 40 次预算。`venue.yml` 有 `anonymized: true` 或 `.env` 设了 `ANON=true` 时，保密模式开启：只用主题词检索——绝不用标题、猜作者、或逐字句子。
4. **weakness 按 ID 攻击主张。** 评审员会拿到台账，并为每条 major weakness 填 `attacked_claims`；主席把这些 ID 带进综合评审。停在 `unsourced` 或 `proposed` 的主张，正是敏锐的评审人最先找到的软肋：攻击它们。映射不到任何主张的 weakness 仍然要带上它的锚点。
5. **主席在发布之前先确认（§6.5）。** 每条 major weakness 的锚点在进入综合评审之前，都由主席打开并读过；抽查式地重新抓取 2–3 条 `verified` 引用；没有锚点的条目被丢弃，并把这次丢弃记进 Synthesis Notes。评审员自报的覆盖面与其他任何返回一样要被审（§6.3）。
6. **一份持久产物，按真实评审的形状。** 综合评审 `cycls/<cycle>/reviews/SIM_REVIEW_<date>.md` 严格遵循 `references/review-template.md`——`/stage-resp-writer` 用同一条流水线解析 `reviews/` 里的一切，必须无法分辨模拟与实收。活到里面的 `verified` 引用要把它的记录内嵌带上（标题、年份、venue、URL）。各视角评审、引用审计与抓取缓存都是运行目录里的工作文件，位于 `wkdrs/reports/` 下（§1.2）——可重新生成，永不提交。
7. **先构建；构建坏了就按坏的评。** 评审组读的是 `execs/run.sh` 产出的 PDF——真实的 venue 评的是你的 PDF，不是你的意图。构建失败就是第 1 号发现，评审转而基于 `manus/` 源文件进行，并在 Summary 与 Synthesis Notes 里说明这份片面性——绝不糊过去（§7.4）。

## 工作流

### Step 1：装载与解析

整份读完规约，然后读 `notes/story.md`（当前周期）、`cycls/<cycle>/venue.yml`（`scale:`、`anonymized:`、venue 的表格形式）、`notes/claims.md`，以及按上面清单读本 skill 的 `references/`。解析模式（默认 `panel`）与参与度档位各一次（§7.7）。缺 story、缺台账或缺 venue 档案 → 停下并路由到 `/stage-stry-coach`。手稿还停在骨架 → 停下并路由到 `/stage-sect-drafter`；评一堆空章节只是噪声。

### Step 2：构建

`execs/run.sh`（§3.3）。成功 → 把 PDF 路径与页数记下来给每份简介用。失败 → 按原则 7。无论哪种，都记录评审组评的是什么——日期、构建状态、`git log -1` 的 commit——好让日后能靠逐字比对检测过期（§8）。

### Step 3：准备运行目录与摘要

创建 `wkdrs/reports/peer_<cycle>_<date>/`。把主席的摘要写进去：论文位置（PDF，加上提纲给出的源文件地图）、主张表、venue 那一行（venue、scale、页数上限）、保密模式标志。摘要是地图，不是疆域——每位评审员都要自己整份读论文。

### Step 4：派出评审组（quick 模式则自己走一遍）

panel：五个委派，每批最多三个，按视角互不重叠。每份简介包含它在 `references/review-dimensions.md` 里那一节的逐字文本、两份约定的逐字文本、摘要、它那份检索预算与缓存前缀 `fetch_<perspective>/`，以及范围那一行"只做这个视角；返回收集器约定的那些字段，除此之外什么都不返回"。在 `high` 档，派发之前先说明切分方式（§6.8）。quick：主席把论文读一遍，自己按视角顺序填完五份收集器返回，魔鬼代言人放最后。

### Step 5：确认与综合

先做原则 5——打开锚点、抽查已核实的引用、丢掉没有锚点的条目并记录在案。然后把各视角文件（`review_<perspective>.md`，或 `review_quick.md`）写进运行目录，合并出 concern matrix（哪些视角提了什么），给问题去重，并把评审组内部的分歧记下来供 Synthesis Notes 用。

### Step 6：打分

按原则 2 匹配档位。只对着已确认的发现，从上到下走一遍封顶表；施加被触发的最低那个封顶并点名它。按评分标准自己的定义设定置信度。`scale: journal` → 给出档位加上必改项清单，Required 与 Suggested 分开，每条带锚点并写明它的满足条件。最后再映射到 venue 自己的表格形式。

### Step 7：写产物

运行目录：各视角评审与 `citation_audit.md`——每个被点名的引用及其出处与查询、抽查结果、无结果的检索；宿主没有网络时记下 OFFLINE 降级（§3.5）。持久产物：`cycls/<cycle>/reviews/SIM_REVIEW_<date>.md`——按模板写的综合评审，`mode:` 要诚实，对话是中文时追加 中文要点摘要 一节。真实日期（§4）；同一天重跑会替换当天那份文件，替换前先说明。此外什么都不碰：不碰 `manus/`、不碰 `notes/claims.md`、不碰 `venue.yml`、不碰 `tasks/`。

### Step 8：汇报与提交

摘要 ≤300 词（§7.1）：推荐结论与置信度，并点名用的是哪套刻度；触发了哪些封顶；最重要的几条 major 及它们攻击的 claim ID（每个在首次出现时解释，§7.11）；被丢弃条目与分歧的计数；以及决策记录（§7.8）。路由：用 `/stage-resp-writer` 来回应它；用 `/stage-sect-drafter`、`/stage-clms-auditor`、`/stage-refs-curator`、`/stage-figs-designer` 去修那些 major；干净到可以发了 → `/stage-subm-packer`。提议一次提交（§1）：只有那一个 `SIM_REVIEW_<date>.md` 文件，标题为 `stage-peer-reviewer: <cycle> <mode> review`。

## 输出

登记表行（§8）：Simulated review —— 生产者 `stage-peer-reviewer`，持久路径 `cycls/<cycle>/reviews/SIM_REVIEW_<date>.md`（评审组的综合评审；各视角评审、`citation_audit.md` 与抓取缓存住在 `wkdrs/reports/peer_<cycle>_<date>/`），状态：文件名里的日期。确切形状见 `references/review-template.md`，schema 摘要见规约 §8.8。手稿与主张台账离开这次运行时，与进来时逐字节相同——评审从不编辑。
