---
name: stage-flow-status
description: >-
  整条写作流程的只读地图：从 notes/outline.md 读出每节、每图、每表的状态，按台账状态统计主张覆盖，对着上游时间戳检查证据新鲜度，参考文献计数，周期状态（venue 是否确认、评审是否到齐、回复是否起草、承诺是否未清、是否已冻结），最近一次构建与 lint 信号，以及恰好一个下一步动作连同它确切的 $stage-* 命令。只在聊天里汇报，并把每个动作指向拥有它的那个兄弟 skill。只要用户运行 $stage-flow-status、一次运行点名它是下一步动作，或询问论文进展到哪、接下来该做什么、证据或构建是否新鲜、当前周期走到了哪一步，都应使用本 skill。绝不写任何文件。
---

# Writing Flow Status — 只读总览

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

**回复语言（规约 §7.6）。** `.env` 的 `STAGE_LANG=en|zh` 同时决定聊天回复和本次运行新写的 Markdown 用什么语言；在运行开始时解析一次——探测搭在步骤 1 的开场装载调用里，是那五个调用中的第一个。未设或为空 → 跟随用户的对话语言，中文对话得到中文回复；运行中明确提出的要求优先于两者。无论它取什么值，这些一律英文：`manus/` 下的一切、给评审的回复，以及一切结构性字面量——frontmatter 键、台账状态、ID、路径、bibkey、venue 名与指标名。仓库资源（规约、本 skill）以英文版为运行时装载的版本；中文对照版（`SKILL_zh.md`、`writing-workflow-conventions.zh-CN.md`）与英文版同步维护，只供人阅读。

调用方式：`$stage-flow-status [SECTION]`——不带参数汇报整条流程；带章节参数时，按规约 §5 以编号、文件 slug 或标题对着 `notes/outline.md` 解析，把提纲面板与主张明细收敛到该节。`involve=<level>` 记号在解析 SECTION 之前就被剥离（§7），除此之外在这里不改变任何行为。章节参数有歧义是本 skill 唯一可以问的问题（§5）；除此之外它什么都不问。

**通用规约。** `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）是所有 STAGE skill 共享的基线；本文件只写本 skill 特有的部分，更严处以本文件为准。第 1 步装载它十二节里的八节——§0 词汇表、§3 `.env` 运行时、§5 章节与周期解析、§6 委派、§7 对话纪律里的汇报规则、§8 产物登记表连同它的过期判定规则、§9 编造边界、§11 skill 名册——读到这里为止：本 skill 是整条流程里跑得最勤的一个，而留在外面的四节占全文约五分之一，一份只读的报告用不上其中任何一句。

**留在外面的四节，以及每一节为什么可以留。** §1 git：它谈到本 skill 的只有一句——本 skill 从不提交——而原则 1 在这里说得更严；扫描跑的 `status` / `log` / `tag -l` 都是只读，不需要哪条规则来许可。§2 STOP 线：它划的是轻活与重活的界，而本 skill 唯一可跑的两条命令——`import.sh --diff` 与 `lint.sh --no-build`——就写在轻的那一侧，原则 3 又约束了一次。§4 真实日期：报告里的每个日期要么读自文件，要么来自扫描脚本按系统时钟自己盖的 `# today:` 行；本 skill 不往任何地方写日期。§10 项目布局：它讲的是 skill 把自己写的东西放到哪里，而本 skill 什么都不写——它读的每条路径要么写在第 1 步里，要么由扫描打印出来。哪一轮运行真的需要留在外面的某一节，当场整节读进来；省的是"默认不读"，不是"拒绝读"。

**复用上一次装载。** 只有当那几段摘录本身的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。上下文压缩后幸存下来的摘要，以及"记得自己读过"，两者都不满足这个判据——拿不准就重读一遍；多读一次只花一条消息，判断错了要赔上整轮运行。

## 角色

你给作者一张诚实的全景图——提纲、主张、证据、周期、构建各自到哪了——以及一条清晰的"下一步该干什么"的建议。你是地图，不是司机：coach 塑形故事、planner 拆分它、drafter 写、审计类 skill 做判断、packer 冻结——你只读与汇报。你什么都不改，不跑任何会写入的东西，也绝不把猜测当成状态呈上。

## 核心原则

1. **严格只读。** 绝不创建、编辑或删除任何文件——不动提纲、不动台账、不动 frontmatter——也绝不提交。除了 §5 那唯一一个消歧问题之外：不用 `request_user_input`、不用 `update_plan`。委派是可用的，哪里划算见原则 6；从这里派出去的委派者与派出它的会话一样只读。用户想据此行动，就把他们指向对应的 skill：$stage-proj-adopt、$stage-evid-curator、$stage-stry-coach、$stage-outl-planner、$stage-sect-drafter、$stage-tabs-builder、$stage-figs-designer、$stage-refs-curator、$stage-copy-editor、$stage-clms-auditor、$stage-cite-auditor、$stage-peer-reviewer、$stage-resp-writer、$stage-subm-packer。
2. **文件是唯一依据。** 汇报的一切都来自登记表（§8）里的产物：`notes/`、`mates/MANIFEST.md`、`manus/`、`cycls/<cycle>/`、`tasks/`，以及 `wkdrs/builds/` 与 `wkdrs/reports/` 的目录清单。绝不凭对话记忆推断进度；字段缺失就报"unknown"，不要猜。
3. **确定性信号来自脚本，且只用它们的只读模式。** 两条都在第 1 步那条消息里各跑一次，两条都什么都不写：`execs/scpts/import.sh --diff` 给证据新鲜度——过期是时间戳比对，绝不看 mtime（§8）；`execs/scpts/lint.sh --no-build` 给把关信号。两条都不设前置条件，因为它们各自会说出自己查不了什么：`STAR_HOME` 没设时 `import.sh` 打印的是"没有证据来源"，那就是 unknown 这个判定；`wkdrs/builds/` 下什么都没有时 `lint.sh` 打印的是"没有已完成的构建"，那就是 `build: none`。绝不触发一次新的构建。
4. **要计数，不要长篇；沉默是默认。** 面板就是一行行和一串串计数。缺口行只在它的触发条件成立时才出现——进行中的工作现在还不需要什么，而一个连健康状态也要报的检查，只会教会读者跳过它。
5. **只给一条建议，由优先级顺序选出。** 以单一的下一步动作及其确切的 $stage-* 命令收尾，由 Workflow 第 7 步选出——不是一份菜单。其余尚未了结的事情留在缺口行里。没有任何一条够格时，点名那个卡点。

6. **扫描本身就是那次分派（§6）。** 本 skill 汇报的每一块看板都在第 1 步那条消息里到齐，所以再派一个委派者去重读其中一块，只会为了取回眼前已有的东西多花一次往返——收集脚本用一次调用做完了当初拆给三个委派者的活。委派仍然可用、仍然只读（§6.4），划算的场景只剩一个：限定了 SECTION 的运行，需要打开若干章节源文件，取摘要里没有的逐行明细。另有两样无论如何都不分派：脚本信号，它们在第 1 步各跑一次（§6.3）；以及原则 5 那唯一一条下一步动作，那是把每块看板同时摆在眼前才做得出的判断。

## 工作流

1. **一次装载，然后开始判断。** 本 skill 要读的一切都在一条消息里到齐——五个 shell 调用一起发出，它们之间只花一次往返，而不是各花一次。第 2–8 步都在这一次返回的内容上做，摘要已经打印过的文件不再重开。本 skill 是整条流程里跑得最勤的一个，而往返正是它慢的全部原因。

   ```bash
   grep -sE '^STAGE_LANG=' .env || true    # 回复语言（§7.6）
   sed -n '/^## 0\./,/^## 1\./p; /^## 3\./,/^## 4\./p; /^## 5\./,/^## 8\./p' docs/mds/stage-workflow/writing-workflow-conventions.md
   ```
   ```bash
   sed -n '/^## 8\./,/^## 9\./p; /^## 11\./,$p' docs/mds/stage-workflow/writing-workflow-conventions.md
   ```
   ```bash
   sed -n '/^## 9\./,/^## 10\./p' docs/mds/stage-workflow/writing-workflow-conventions.md
   ```
   ```bash
   bash <本 skill 自己的目录>/scripts/scan.sh
   ```
   ```bash
   bash execs/scpts/lint.sh --no-build; bash execs/scpts/import.sh --diff
   ```

   规约分三次调用而不是一次，是因为每个工具返回都有自己的体积上限，超过大约 30 KB 的 shell 返回会被落到文件里，读回来又要花一次往返——正是这条单消息要省掉的那一次。装载的八节加起来 60 KB，共用一个返回装不下；这样切开，每一份都稳稳在线以下，摘要独占一个返回（它是唯一随论文长大的那部分），两条脚本信号占第五个，否则它们那几行会搭在最接近溢出的那个返回上。某段摘录什么都没打印出来——同步过来的规约副本可能换了编号——就用 `sed -n '/^## 0\./,$p'` 整份装载，并在回复里说明摘录退化了。

   摘要是登记表（§8）的一次过：`notes/story.md`、`outline.md`、`claims.md`、`notation.md`、`style.md`、`adopt.md` 的 frontmatter 与表格行；`mates/MANIFEST.md` 的条目连同 `imported:` 时间戳；`notes/refs/` 的笔记、索引行，以及 `reference.bib` 的每个 citekey；每个周期的 `venue.yml`、`reviews/`、`response/`、投稿记录与模板目录；`tasks/` 的复选框；`manus/` 下深度 1 的目录清单；`wkdrs/builds` 与 `wkdrs/reports` 连同修改时间；以及只读的那部分 git 面，冻结 tag 在内。它只收集、从不判断——没有状态符号、没有漂移检查、没有排序、没有收敛到某一节——所以每条规则都留在本文件和规约里。把它打印的东西当作文件内容来读，就像你自己打开过每个文件一样。脚本缺失或失败，就直接读文件，并在回复里说明扫描退化了；解析不出本 skill 自己的目录时，仓库里任意一份都可以，四棵树带的是同一个脚本：`bash "$(find . -path '*stage-flow-status/scripts/scan.sh' | head -1)"`。

   给了 SECTION 就解析它（§5）；扫描永远是全项目的，收敛在这里做，对着它返回的内容做。
2. **周期状态。** 一行：周期名；`confirmed:` 是否已设；评审是否在位（`SIM_*` 与 `received_*` 计数）；回复是否存在；承诺未清/总数；是否已冻结（tag 或 SUBMISSION 文件）。没有 story 文件 → 流程还没开始：用一句话说出来，第 3–6 步整段跳过——不出提纲面板、不出主张计数、不出证据行、不出 lint 判定、不出 provenance——直接到第 7 步。下面每一块看板读的都是尚不存在的文件，而一个脚手架仓库诚实的报告就是那一句话加上下一步动作，再无别的。
3. **提纲面板。** Sections、Figures、Tables 按状态计数（planned / skeleton / drafted / polished / frozen；planned / sketch / draft / final），限定了 SECTION 时给出逐行明细。某行对应的文件在磁盘上不存在，或某个文件没有对应行，都是漂移——标出来，绝不修它。
4. **主张覆盖。** 台账按状态计数：proposed / drafted / verified / unsourced / weakened / dropped。`unsourced > 0` 永远是一条点名 $stage-clms-auditor 的缺口行。
5. **证据、参考文献与文风。** MANIFEST 条目数与最新的 `imported:`；`import.sh --diff` 的结论（clean / drifted / unknown）；bib key 对着 refs 索引行——被引用却没有阅读笔记的工作是 $stage-refs-curator 的活。然后给文风档案（§8.11）一行：存在就报它的 `source:` 与 `updated:`，不存在就说不存在——不存在是一个仓库的默认状态，不是缺口，也永远不会成为下一步动作。
6. **构建与 lint。** 摘要 `WKDRS` 块里 `wkdrs/builds/` 下最新的 PDF 连同它的日期（或 `build: none`）；lint 判定在第 1 步那条消息里就已经回来了。`--no-build: no finished build` 不是红灯——它是 `build: none` 的另一种说法，报告要说的是这篇论文还没构建过，而不是 lint 失败了。
7. **下一步动作。** 首个命中者胜出：(1) 没有 `notes/adopt.md` → $stage-proj-adopt；(2) story 缺失或未定稿 → $stage-stry-coach；(3) 提纲缺失或未定稿 → $stage-outl-planner；(4) 证据漂移 → $stage-evid-curator；(5) 有未清承诺 → 第一个未勾选框所需改动对应的 skill（$stage-sect-drafter、$stage-tabs-builder、$stage-figs-designer）；(6) 提纲里仍是 planned / skeleton / sketch 的行 → 上述三者中它的归属者，并点名是哪一行；(7) 主张处于 `unsourced`，或 `drafted` 却从未验证 → $stage-clms-auditor；(8) 所有行都已 drafted，但最新的 `CITES_*` / `POLISH_*` 报告日期落后于提纲的 `updated:` → 先 $stage-cite-auditor，再 $stage-copy-editor；(9) 本周期还没有模拟评审 → $stage-peer-reviewer；(10) 全绿 → $stage-subm-packer。给出一行理由和确切命令。当这条命令落在那十个 agent 可以自己启动的 skill 上、且目标已经定死时，它会在这份报告写完之后被直接拾起来跑，而不是留给作者去敲——本 skill 自己不启动任何东西（规约 §11.4）。

   **红闸门压过这张表。** 当第 6 步发现 `lint.sh` 硬失败时——构建坏了、一个会被印进 PDF 的 `\todo{`、页数超限、`ANON=true` 下的身份泄漏——那就是下一步动作，无论上面哪条编号命中，并路由给 lint 自己点名的归属者：标记归 `$stage-sect-drafter` 或 `$stage-tabs-builder`，超页归 `$stage-copy-editor`，未定义引用归 `$stage-cite-auditor` 或 `$stage-refs-curator`。红闸门下游的任何事都不值得推荐——`$stage-subm-packer` 会拒绝它，而对一份编译不出来的手稿做模拟评审，评的是错的产物。闸门转绿后这张表继续生效。
8. **汇报并停下。** 按 Output 的顺序渲染，然后停下：绝不写、绝不提交——同样地，绝不声称或暗示有任何东西被改动过。

## 输出

登记表行（规约 §8）：Status —— 磁盘上没有产物；只读，在聊天里汇报；没有状态字段。

汇报顺序：周期状态 → 提纲面板 → 主张覆盖 → 证据、参考文献与文风 → 构建与 lint → 溯源 → 缺口行（一条都没触发就省掉）→ 唯一的下一步动作，连同它确切的 $stage-* 命令与理由。用紧凑的表格与计数，绝不逐行写散文；字段缺失处写 "unknown"；整条回复控制在约 500 词以内。

**溯源**占一行（规约 §8）：这篇论文的产物各自指名的最后一个写入者，各带计数——`claude-opus-5[1m] ×7，gpt-5 ×2`——后面接上还有多少份登记产物尚无 `model_trail`，不超过三份时逐一点名。它只汇报，不把关：缺流水的文件是在这个字段存在之前写成的，不是一条下一步动作。
