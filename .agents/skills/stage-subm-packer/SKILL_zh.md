---
name: stage-subm-packer
description: >-
  为当前周期做投稿的预检与打包：execs/run.sh 构建与 execs/scpts/lint.sh 关口必须双双通过，然后对着用户确认过的 venue.yml 事实走一遍清单、做一次图/表/参考文献的齐备性巡检、在 wkdrs/builds/ 下打出包（camera PDF、补充材料、arXiv 可用源码）、写下持久记录 cycls/<cycle>/SUBMISSION_<date>.md，并打上冻结 tag freeze/<cycle>_<date>——它是这个家族里唯一被允许创建 git tag 的 skill。camera-ready 模式还会在 tasks/<cycle>_promises.md 仍有未勾选的承诺框时拒绝打包；convert 模式把论文改排成用户提供的官方 venue 模板，产出 wkdrs/ 下一份可重新生成的副本，绝不抓取或重建模板。它只打包与记录；绝不上传到投稿系统、绝不 push、绝不编辑手稿。只要用户调用 $stage-subm-packer，或要求打包、冻结、转成 venue 模板，或准备投稿、camera-ready、arXiv 源码，都应使用本 skill。
---

# Submission Packer —— 预检、打包、冻结

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

**回复语言（规约 §7.6）。** `.env` 的 `STAGE_LANG=en|zh` 同时决定聊天回复和本次运行新写的 Markdown 用什么语言；在运行开始时解析一次——`grep -sE '^STAGE_LANG=' .env || true`，搭在开场装载调用里。未设或为空 → 跟随用户的对话语言，中文对话得到中文回复；运行中明确提出的要求优先于两者。无论它取什么值，这些一律英文：`manus/` 下的一切、给评审的回复，以及一切结构性字面量——frontmatter 键、台账状态、ID、路径、bibkey、venue 名与指标名。仓库资源（规约、本 skill）以英文版为运行时装载的版本；中文对照版（`SKILL_zh.md`、`writing-workflow-conventions.zh-CN.md`）与英文版同步维护，只供人阅读。

调用方式：`$stage-subm-packer [camera | convert] [kit=<path>]`——不带参数则为当前周期打一个送审包，周期按规约 §5 从 `notes/story.md` 的 `cycle:` 解析；`camera` 为同一个周期打 camera-ready 包，并把承诺关口装上；`convert` 只把论文改排成本周期的 venue 模板并报出该版式下的页数，跳过所有冻结关口。`kit=<path>` 在转换前注册一份官方 venue 模板包（zip 或目录）。无法识别的参数则点名这三种模式并提问。

**转换流程。** `references/venue-convert.md`——模板包契约、`stys/arxiv.cls` 独占而 venue class 必须替换掉的那些命令、abstract 的搬家、`compat.sty`、匿名映射。转换之前读它；不做转换的运行不需要它。

**通用规约。** 每次运行开始时整份读完 `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）——不做分节选读。它是所有 STAGE skill 共享的基线；对本 skill 约束最紧的是 §1 git（冻结 tag `freeze/<cycle>_<date>` 只在这里创建）、§3 构建工具链与 `ANON`、§5 周期解析、§9 编造边界。本文件只写本 skill 特有的部分，更严处以本文件为准。

**复用上一次装载。** 只有当规约文件本身的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。上下文压缩后幸存下来的摘要，以及"记得自己读过"，两者都不满足这个判据——拿不准就重读一遍；多读一次只花一条消息，判断错了要赔上这次冻结。

## 角色

你是手稿与 venue 之间的气闸——工作离开仓库之前最后一道确定性检查。上游的一切都在协商内容；你只做核验、打包、冻结与记录。你发现什么都不修：发现路由给拥有它的那个 skill。而且你从不提交投稿——不上传投稿系统、不 `git push`、不碰 arXiv 账号、不填 venue 表格。冻结 tag 与 SUBMISSION 记录是你的；按下提交那一下是用户的。

venue 的版式也归你管，而这一点丝毫不改变上面那条线。改排产出的是 `wkdrs/` 下的一份**副本**；`manus/main.tex`、`secs/`、`tabs/`、`figs/`、`bibs/reference.bib` 只被读，从不被写——`manus/` 下也不新增任何文件。除 SUBMISSION 记录之外，本 skill 在 `wkdrs/` 之外唯一新增的东西是官方 venue 模板包，解包进 `cycls/<cycle>/template/`，与该周期的 `venue.yml` 并列。它刻意待在手稿之外：`manus/` 是一个被扫描的命名空间——`lint.sh` 会数它下面每个 `*.tex` 里的 `\todo{`，并在其中搜身份泄漏——而模板包自带的示例 `.tex` 带着样例作者名和一节 Acknowledgments，在 `ANON=true` 下那就是一次硬 lint 失败，触发它的还是一个这里谁都无权编辑的第三方文件。

## 核心原则

1. **关口是脚本，而且是硬的。** 在任何东西被打包之前，`execs/run.sh` 必须构建通过、`execs/scpts/lint.sh` 必须以 0 退出。lint 的硬失败——未定义的引用、`manus/` 里任何位置的 `\todo{`、超过 `page_limit_main`、`ANON=true` 下的身份泄漏——阻止打包，并且绝不在这里被豁免、被辩下去或被打补丁。一个 `\todo` 是 §9a 给"没有证据的数字"打的标记；把它打进包里就等于把那个不该存在的第三种状态发出去。
2. **冻结 tag 要么说真话，要么永远在撒谎。** `freeze/<cycle>_<date>` 只在干净的树上创建：`manus/`、`notes/` 或 `cycls/` 下有未提交的改动就在关口之前停下——那些提交属于做出那些编辑的会话（§1）。已有的 tag 绝不移动或删除；今天这个名字已经被占用时，说出来并停下。这是整个家族里唯一被允许打 tag 的 skill，而且每次打包恰好创建一个。
3. **venue 事实要么是用户确认过的，要么就不存在。** 页数上限、截稿日期、清单家族与匿名要求都来自 `cycls/<cycle>/venue.yml`，且只有在它的 `confirmed:` 已设时才有约束力（§9c）。未确认的档案会让运行停下——路由到 $stage-stry-coach；绝不为了让打包继续，就凭记忆填一个上限。
4. **camera-ready 兑现每一条承诺。** `camera` 模式下，`tasks/<cycle>_promises.md` 里任何一个未勾选的 `- [ ]` 都会让打包被拒：每个框都是白纸黑字向评审人许下的一项改动，而一份悄悄丢掉其中一条的 camera-ready 就是毁约。把未清的框连同能关掉它的那个 skill 一起列出来；绝不自己去勾框。
5. **软性发现只在留下记录时才被豁免。** 提纲行还没到 final、`import.sh --diff` 报出的证据漂移、缺失的补充材料——把清单摆出来、提问，并把用户的豁免写进 SUBMISSION 记录。没有被记录的豁免等于没发生过。
6. **包里不泄漏任何东西。** 这个包只装编译这篇论文所需的东西——源文件、图、样式、参考文献——此外什么都没有：不装 `mates/`、不装 `notes/`、不装 `tasks/`、不装 `.env`；在匿名周期下，lint 的 anon 家族会标出的东西一样都不装。`wkdrs/` 永不提交（§1）；持久记录是 SUBMISSION 文件与那个 tag。可编辑的图源也留在家里：`manus/figs/srcs/` 从不随包发出，因为一个绘图脚本或 `.drawio` 文件会带上渲染出的 PDF 不带的路径、用户名与机器名。
7. **venue 模板是被提供的，不是被合成的。** venue 的 class、style 与 `.bst` 文件来自用户交过来的官方模板包，逐字节拷贝，且永不被编辑——不为修一个编译错误改，也不为压一点页边距改。绝不去抓一份模板包，绝不凭"某个 venue 的 class 大概长这样"的记忆重建一份：§9 的边界管版式跟管数字是一模一样的，而一份凭记忆写出来的 class，错的地方要到投稿系统那一刻才浮出来。副本编译不过时，修改落在生成的 `compat.sty` 或生成的 `main.tex` 里，否则就是报告里的一行。
8. **venue 版式是生成的，不是写出来的。** 每一次转换都从 `manus/` 从头重建副本——没有增量同步，也没有第二份真值源。在副本内部手工打的补丁会被下一次运行抹掉，所以那从来不是答案；答案是经由拥有那个文件的 skill 去改 `manus/`。还有，`page_limit_main` 说的是副本的页数，不是预印本构建的页数：`lint.sh` 量的是另一个 class 下的另一份文档，那是写作期的代理指标，不是答案。

9. **扫描并行分派，关卡绝不（§6）。** Step 5 的完备性扫描按登记产物切开——提纲那三张表一个委派者、主张台账一个、笔记与 bib 一个、承诺文件一个——各自把自己这边的缺口作为发现返回，别的什么都不返回；Step 6 的清单走查在某个清单族条目超过 6 条时，一条一个委派者。硬关卡既不切开也不委派：`execs/run.sh`、`execs/scpts/lint.sh` 与工作树检查都是单次脚本调用，退出码由主 agent 自己读（§6.3）。Step 8 往后的一切也一样——打包、留档、提交与冻结 tag 都在 STOP 线上，属于用户所在的那个会话（§2、§6.5）。

## 工作流

1. **装载与解析。** 整份读完规约。从参数解析模式、按 §5 解析当前周期；读 `cycls/<cycle>/venue.yml`，`confirmed:` 未设就停下。`anonymized: true` 与 `.env` 的 `ANON` 不一致时（送审包需要 `true`；camera 需要 `false`），停下并说清重跑之前该改 `.env` 的哪一行。
   **`convert` 只跑第 7 步，别的一步都不跑**——不查树、不过承诺关口、不过构建与 lint 关口、不做巡检、不走清单、不打包、不提交、不打 tag。这是刻意的：把论文塞进 venue 的页数上限要转很多次，而每一次都发生在手稿里还有 `\todo`、`lint.sh` 还是红的时候。一个只肯在"已经能投"的论文上运行的转换，永远没法用来把论文变得能投。`convert` 还把 `confirmed:` 那道停止放宽为一条警告——无论如何都报出页数，并说明这个上限尚未确认（§9c：未确认的上限不构成约束）。
2. **树检查。** `manus/`、`notes/` 或 `cycls/` 下有未提交的改动就停下（原则 2）。tag `freeze/<cycle>_<date>` 已存在就停下。
3. **camera 关口（仅 `camera`）。** 扫描 `tasks/<cycle>_promises.md` 里的 `- [ ]`。有命中 → 拒绝：把每条未清的承诺连同能关掉它的 skill 一起引出来。有 `cycls/<cycle>/response/` 却缺承诺文件，是一处不一致——标出来并提问，不要直接当作"没有许过承诺"。
4. **硬关口。** 有一道比脚本更便宜，先跑：`notes/adopt.md` 的 `backfilled:` 为空。那正是被接入草稿的那种状态——手稿里既有的数字追不到任何东西，而 `lint.sh` 数的是标记、它们一个标记也没有，于是报告干净（规约 §9a、§8.9）。标记计数在这里能证明的比它看上去的少，所以拒绝打包，并路由给 `$stage-clms-auditor` 去把待办清掉、把这个字段置位。没有 `notes/adopt.md` 的仓库从来不是从草稿起步的，跳过这一关。
   然后跑 `execs/run.sh`（记下 PDF 路径与页数），再跑 `execs/scpts/lint.sh --no-build`。任何硬失败都让运行停下并路由：`\todo` → 那个数字的归属者（$stage-sect-drafter 或 $stage-tabs-builder；不清楚时找 $stage-clms-auditor）；未定义的引用 → $stage-cite-auditor 或 $stage-refs-curator；超页数 → $stage-copy-editor；身份泄漏 → 点名文件与行号。lint 报的页数是预印本构建的；第 7 步会在 venue 自己的版式下重新核一遍，那才是上限所指的那个数（原则 8）。
5. **齐备性巡检。** 检查：提纲 Sections 行处于 `polished` 或更好，Figures 与 Tables 行处于 `final`；每个 `manus/figs/*.pdf` 都有 `figs/srcs/` 下的源文件或一条 `mates/MANIFEST.md` 条目；手稿里陈述过的主张在 `notes/claims.md` 里没有一条还停在 `unsourced` **或 `weakened`**——`weakened` 意味着某份回复已经白纸黑字让过步，于是仍在陈述它的手稿等于寄出了一条作者自己已经撤回的主张，这在评审人眼里比原来的夸大更难看；`import.sh --diff` 报告没有漂移（`STAR_HOME` 未设时跳过并注明）。每处未达标都是一条软性发现：把清单连同建议摆出来，经 `request_user_input` 提问——带着点名的豁免继续，还是中止——并按原则 5 记录豁免。
6. **走清单。** 按 `venue.yml` 的 `checklist:`——`none` 则跳过；否则逐条走那个家族的条目，仓库回答不了的事实要问用户（§9c：答案属于用户，绝不臆造），并逐条记录 pass / fail / waived。
7. **转换。** 只在 `venue.yml` 的 `template:` 指名了一份模板包时做——该字段缺失、为空或为 `arxiv`，都意味着论文以预印本形态发出，这一步说明这一点然后什么也不做。否则按 `references/venue-convert.md` 走：把模板包解析或注册进 `cycls/<cycle>/template/`，读模板包自带的示例 `.tex` 与 class 文件以取得它要的宏，搭出副本，生成 `compat.sty` 与 `main.tex`，再用 `execs/run.sh --main <copy>/main.tex` 构建这份副本。`convert` 模式下副本落在 `wkdrs/builds/<cycle>_<template>_<date>/`；打包运行里它成为包的源码目录。拿副本的页数去对 `page_limit_main`：打包运行中超限是硬阻断，路由给 `$stage-copy-editor`；`convert` 里只是报出来的一个数。报告映射了什么、因没有 venue 对应物而丢掉了什么、还有什么需要人来处理——绝不为了让副本编译通过而丢内容。
   **转换留给人处理的东西写进 `tasks/<cycle>_venue.md`**，而不是只写在回复里——被丢掉的 `\keywords`、需要拍板的附录顺序、没有 venue 等价物的某个宏。一条发现一行 `- [ ]`，各带一个稳定的 `V<n>` 编号和拥有这个修法的 skill（形状见下）。这个文件是**被更新的，不是被重新生成的**：已勾选的条目保持勾选、永不被重新提出，于是转换跑二十遍也不会把用户已经拍板的事一再翻出来。它们是发现，不是承诺——一个未勾选的框永不阻断打包，因为为了「`\paperdate` 被丢掉了」就拒绝发出去，只会教会作者忽略那道真正要紧的关口。
   **只有 `convert` 写这个文件**，也只有 `convert` 注册模板包：`kit=<path>` 在打包运行里被忽略。`convert` 为它在 `wkdrs/` 之外写下的东西提出一次提交——注册了模板包时连同模板包，外加 `tasks/<cycle>_venue.md`——标题 `stage-subm-packer: convert <cycle> <template>`（§1）。打包运行读这份清单、报出其中未清的条目，并把本次转换的发现记进 SUBMISSION 记录，而不写任何 task 文件：一个在第 2 步树检查之后才写出的文件，会让冻结 tag 落在一棵已经不干净的树上。打包运行若发现 `cycls/<cycle>/template/` 不存在就停下，并路由到 `$stage-subm-packer convert kit=<path>`。
8. **打包。** 组装 `wkdrs/builds/<cycle>_<date>/`：按模式取构建出的 PDF（送审或 camera）、venue 与提纲定义了补充材料时的补充材料，以及源码目录——周期有模板时用第 7 步转换出的副本，否则用 arXiv 可用的形态：`main.tex`、`secs/`、`tabs/`、`figs/*.pdf`、需要的 `stys/`，加上 `bibs/reference.bib` 与本次构建的 `.bbl`——然后用同一个引擎从包内部重新构建一次：编译不过的捆包不算包。
9. **记录、提交、打 tag。** 写 `cycls/<cycle>/SUBMISSION_<date>.md`（形状见下；真实日期按 §4）。提交它——一次提交，只暂存这一个文件，标题 `stage-subm-packer: freeze <cycle> <date>`（§1）——然后在那个提交上创建 `freeze/<cycle>_<date>`。绝不 push；把投稿系统或 arXiv 的步骤交给用户，作为他们自己的下一步。

## 输出

登记表行（规约 §8）：Submission —— `cycls/<cycle>/SUBMISSION_<date>.md`、git tag `freeze/<cycle>_<date>`、`wkdrs/builds/` 下的包；状态字段 `frozen:`。

`SUBMISSION_<date>.md` frontmatter：`cycle:`、`date:`、`frozen:`（tag 名）、`package:`（`wkdrs/builds/` 下的路径）、`template:`（这个包被排成的 venue 模板，或 `arxiv`）。正文：lint 摘要、带豁免的清单结论、对照 `page_limit_main` 的页数——**取转换出的副本的页数，两者不同时把预印本构建的页数并列在旁**——转换丢掉了什么或留给了人什么，以及什么投到了哪里，按用户所述来写，因为上传是他们做的。

`convert` 的持久产物是注册进来的模板包与 `tasks/<cycle>_venue.md`；副本本身可重新生成，而 `wkdrs/` 永不提交（§1）。

`tasks/<cycle>_venue.md` frontmatter：`cycle:`、`template:`、`updated:`（真实日期按 §4）。正文：一条发现一行复选框——

```markdown
- [ ] V1 — `\keywords{...}` has no equivalent in this kit and was dropped; decide whether the
      keywords belong in the abstract instead → $stage-sect-drafter
- [x] V2 — appendix placed after the references, following the kit's example
```

编号是 `V<n>`，按顺序分配、永不重用。新发现以下一个空闲编号追加；不再适用的条目连同理由一起勾掉，而不是删除，好让这份清单始终是「转换曾经要求过什么」的完整记录。

聊天摘要，结论先行：**已打包**——包路径、tag 名、还等着用户做什么——或者 **已转换**——副本路径、对照上限的页数及该上限的确认状态、映射了什么、丢掉了什么、还有什么需要人处理——或者 **被阻断（n）**，逐条列出阻断项与能清掉它的那个 $stage-* skill。

溯源（规约 §8）：上述位于 `notes/`、`tasks/`、`cycls/`、`wkdrs/reports/` 的每份产物都带 `model_id:`——本次会话的模型 id，原样抄录——并追加一条本次运行的 `model_trail:` 条目。`manus/` 与 `mates/` 下的一切两者都不带，`cycls/<cycle>/venue.yml` 也不带。
