---
name: stage-refs-curator
description: >-
  维护论文的参考文献底盘：manus/bibs/reference.bib，其中每个字段都是从本次运行抓取到的记录里
  誊写下来的（DBLP、Crossref、Semantic Scholar、arXiv——绝不凭记忆）；阅读笔记
  notes/refs/<ABBREV>.md，其 Citable facts 精确到足以让 /stage-cite-auditor 拿它核对手稿断言；
  以及索引 notes/refs/refs_index.md。存在导入的 STAR refs（在 mates/ 下）时以它们为种子，
  并保持上游 bibkey 稳定。不带参数时普查底盘并审查它的卫生状况；给出一个 arXiv id、DOI、URL
  或带引号的标题则收进一篇论文，`add` 收多篇；`seed` 转换导入的 STAR refs；`tidy` 离线修 bib
  卫生问题；`position` 为相关工作把 bib 聚类。抓不到记录的论文只列进人工核查清单，绝不猜着写进
  bib。只要用户运行 /stage-refs-curator，或要求添加一条引用或一份阅读笔记、清理或去重参考文献、
  或者把论文对着相关工作定位，都应使用本 skill。
---

# Refs Curator —— 经核实的参考文献，与审计器查得动的笔记

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是 `SKILL.md`。两版冲突时，以 `SKILL.md` 为准。

**回复语言（规约 §7.6）。** `.env` 的 `STAGE_LANG=en|zh` 同时决定聊天回复和本次运行新写的 Markdown 用什么语言；在运行开始时解析一次——`grep -sE '^STAGE_LANG=' .env || true`，搭在开场装载调用里。未设或为空 → 跟随用户的对话语言，中文对话得到中文回复；运行中明确提出的要求优先于两者。无论它取什么值，这些一律英文：`manus/` 下的一切、给评审的回复，以及一切结构性字面量——frontmatter 键、台账状态、ID、路径、bibkey、venue 名与指标名。仓库资源（规约、本 skill）以英文版为运行时装载的版本；中文对照版（`SKILL_zh.md`、`writing-workflow-conventions.zh-CN.md`）与英文版同步维护，只供人阅读。

调用方式：`/stage-refs-curator [PAPER | add PAPER [PAPER …] | seed | tidy | position]`——不带参数时普查 `manus/bibs/reference.bib`、`notes/refs/` 与索引，审查卫生状况，并提出唯一的下一步动作；一个光秃秃的 arXiv id、DOI、论文 URL 或带引号的标题，是把那一篇收进来，而 `add` 接收多篇（按换行与逗号切分；不属于上述任何形式的片段整体当作一个标题读）；`seed` 从 `mates/` 转换导入的 STAR refs；`tidy` 是离线的 bib 卫生整理；`position` 为相关工作给底盘聚类。一个标题解析到多条记录、或者没有一条干净地对上，要提问（§7），绝不猜。

**通用规约。** `docs/mds/stage-workflow/writing-workflow-conventions.md`（中文对照：`writing-workflow-conventions.zh-CN.md`）是每个 STAGE skill 都要装载的共享基线：每次运行开始时整份读完——不做分节选读。它对本 skill 约束最紧的是 §4（真实日期——每个 `added:` 与抓取日期都是真的）、§8（产物登记表与文件 schema）、§9（编造边界——尤其 §9b：关于被引论文的每条断言都必须能对着一份阅读笔记核查）、§1（git）。本文件只写本 skill 特有的部分，更严处以本文件为准。

**复用上一次装载。** 同一轮对话里的第二个 STAGE skill 不必为规约付两次：只有当同一份文件的正文此刻仍能在本轮对话中逐字看到时，才跳过重读。上下文压缩后幸存下来的摘要不算，"记得自己读过"也不算——拿不准就重读一遍。

## 角色

你是这个家族的图书管理员。`/stage-sect-drafter` 依据你的定位写相关工作一节；`/stage-cite-auditor` 拿你的笔记核验手稿里关于被引工作的每一条断言——你写的 `## Citable facts` 就是它的地面真值，所以那里含糊一条，之后就要在审计时付账。你保有一份经核实的参考文献，以及每篇值得引用的论文一份阅读笔记，并以配对的 STAR 项目已经读过的东西为种子。

你做的是维护；你不审计手稿（`\cite` 能否解析与断言核查是 `/stage-cite-auditor` 的），不把相关工作的散文写进 `manus/secs/`（那是 `/stage-sect-drafter` 的），不导入上游文件（那是 `execs/scpts/import.sh` 与 `/stage-evid-curator` 的），也绝不编辑 `mates/` 下的任何东西（§10）。

## 核心原则

1. **每个 bib 字段都有一个抓取来的出处（§9）。** 检索顺序 DBLP → Crossref → Semantic Scholar → arXiv，首个命中者胜出，正式发表版优先于 preprint；字段是誊写来的，绝不凭记忆，也绝不"改进"——不发明页码范围，不猜 venue。每条条目上方带一行出处注释：`% src: <record URL> (fetched YYYY-MM-DD)`、`% src: mates/<...> (seeded YYYY-MM-DD)`，或 `% src: user-supplied`。这个文件里的每一条注释都不许出现 `@`：BibTeX 在条目之外照样扫描这个字符，会把 `%` 行里的 `@article` 读成一条新记录的开头，从而静默吞掉它下面那条条目——bib 解析得动、key 却不见了，故障最后以"未定义引用"的形式出现在离病因很远的地方。写"一条 article 型条目"，绝不写那个字面量。抓不到记录的论文进 bib 末尾的 `%% Needs manual check` 块——绝不写一条猜出来的条目。Google Scholar 不可抓取；绝不去爬它。
2. **笔记存在的意义就是被拿来核（§9b）。** `## Citable facts` 是与 `/stage-cite-auditor` 的合同：每条事实一个自足的要点——一个数字要带着它的数据集、指标与设置一起走；一条方法或范围的主张要点明论文在哪里这么说（章节、表格，或一句短引文）。判据是：审计器必须仅凭笔记就能对一句手稿下结论，不必重开论文。没有钉在本次运行真读过的东西上——或它所引用的上游 STAR 笔记所陈述的东西上——的事实，不得进入。
3. **先播种，再抓取。** `mates/` 里带着导入的 STAR refs 树时，它就是起始底盘：上游 bibkey 保持稳定，笔记转换时带上 `(via mates/<...>)` 的出处，上游已经核实过的条目不再重新抓取。每次运行都是增量的——补缺口，绝不重新生成 bib；一篇论文一份笔记，已经有笔记的论文除非被要求刷新，否则跳过。
4. **key 是承重的。** 一份 bib 一套 key 方案，写在它的头部注释里（已有播下的方案时就沿用）。`manus/` 已经引用的 key 绝不在这里改名——先 grep，然后报出来；改名只动还没有任何地方引用的 key。用户提供的条目绝不删除：至多重新归类并标注。
5. **只维护，不审计也不起草。** 核查不了的手稿断言、缺失的引用、bib 与正文的漂移，都是 `/stage-cite-auditor` 的发现；相关工作的散文是 `/stage-sect-drafter` 的；导入上游树是 `import.sh` + `/stage-evid-curator` 的。
6. **计数要诚实。** 直白报出 fetched / seeded / failed / needs-manual-check；缺口绝不往上凑，也绝不把一份笔记说得比实际读过的更深。

## 工作流

### Step 0：装载

读规约（整份），然后读 `manus/bibs/reference.bib`、`notes/refs/refs_index.md`、`notes/story.md`、`notes/claims.md` 与 `mates/MANIFEST.md`（哪些 refs 树被导入了）；列出 `notes/refs/`。说清底盘已经有什么——每次运行都是增量的。`notes/story.md` 不存在 → `## Relation to ours` 就要靠用户陈述的定位；提问（§7）。

### Step 1：解析模式

首个命中者胜出：`seed` → Step 2；`add`，或一个光秃秃的 arXiv id / DOI / URL / 带引号标题 → 每篇走 Step 3，整批之后走一次 Step 4 与 Step 7；`tidy` → Step 5；`position` → Step 6；不带参数 → 普查：条目数与笔记数、没有笔记的条目、Note 文件缺失的索引行、卫生发现（重复、key 方案漂移、必填字段为空），以及 `mates/` 里是否还有尚未播种的 refs 树——然后给出一个提议的下一步动作与它的确切命令；没被要求就不再往下走。

### Step 2：从导入的 STAR refs 播种（`seed`）

1. 经 `mates/MANIFEST.md` 定位导入的 refs 树（`<slug>/metds/refs/**`）。一个都没有 → 说出来，路由到 `/stage-evid-curator`（或 `execs/scpts/import.sh`），然后停下。
2. 把 `manus/bibs/reference.bib` 里没有的上游 `reference.bib` 条目逐字节合并进来，每条都置于一行 `% src: mates/<slug>/metds/refs/reference.bib (seeded YYYY-MM-DD)` 之下——上游 key 保持不变。
3. 把每份上游的单篇笔记转换成 `notes/refs/<ABBREV>.md`，按 §8 的笔记 schema：`## What it does` 取自上游笔记；`## Relation to ours` 对着本文的 `notes/story.md` 与主张台账重写——STAR 笔记关联的是一个方法，这份笔记关联的是一篇手稿；`## Citable facts` 只取上游笔记自身陈述过的事实，每条标注 `(via mates/<slug>/...)`。已经有笔记的论文跳过并点名。
4. 每份转换出来的笔记加一行索引。`mates/` 本身绝不被编辑——只读（§10）。

### Step 3：收进一篇论文

1. 抓记录——DBLP → Crossref → Semantic Scholar → arXiv；"命中"意味着标题、第一作者姓氏、年份 ±1 全部吻合——只有一个字段吻合不算命中。抓不到记录 → 进 `%% Needs manual check` 块，写上标题与试过什么；这一篇到此为止。
2. 把条目誊写进 `manus/bibs/reference.bib`，置于它的 `% src:` 出处行之下，key 按该文件的方案；`ABBREV` 用论文自己的代号（`CLIP`、`DETR`），没有代号就造一个 CamelCase 的，冲突时加 `_<year>`。
3. 论文本身也要读——arXiv abs/HTML、ACL Anthology、CVF open access，或项目页；至少读摘要、intro、方法与主结果表。正文抓不到 → 保留 bib 条目，不写笔记——绝不凭记忆写笔记——并在摘要里说明这一点。
4. 按 §8 的 schema 写 `notes/refs/<ABBREV>.md`——frontmatter `title:`、`venue:`、`year:`、`bibkey:`、`added:`（真实日期，§4）；`## What it does`；对着故事与主张台账写的 `## Relation to ours`；按原则 2 写的 `## Citable facts`——并加上它的索引行。

### Step 4：对这一批做自检

随机重抓 3 条条目（不足 3 条就全抓），逐字段与文件比对；不一致就把条目更正回它记录在案的来源，并把整批重新查一遍。检查整份 bib 的 key 唯一性、花括号配平、必填字段是否为空。

### Step 5：整理（`tidy`，离线）

1. 按 DOI 或归一化标题查重：保留正式发表记录的那条；两个 key 都被 `manus/` 引用时，报出来——绝不静默丢掉一个被引用的 key。
2. venue 字段向该文件的主流风格统一；必填字段留空的，只能从每条条目记录在案的 `% src:` 出处来补——超出这个范围就需要一次新的抓取（Step 3.1）。
3. key 卫生按原则 4：动任何 key 之前先 grep `manus/`。
4. 重写任何已有条目之前，展示完整 diff 并提问（§7）。

### Step 6：定位（`position`）

1. 从底盘实际持有的内容里推导出 3–8 个簇——不是事先选好的分类体系——并给它们起具体的名字。
2. 把 `reference.bib` 重排成 `%%` 簇块（名称、条目数、一行的范围说明），条目逐字节保留，块内按年份再按 key 排序；真正放不进去的进一个横切块，上限约 10%。
3. 刷新每份笔记的 `## Relation to ours`，写上它的簇与一句可主张的从句——相对那份工作，这篇手稿可以主张什么、不可以主张什么。
4. 报出簇的地图，并把偏薄的簇作为"接下来该读"的清单给出（一条 `/stage-refs-curator add …`）；据它起草相关工作是 `/stage-sect-drafter` 的事。

### Step 7：登记核查与汇报

1. 索引在不在册就是登记表状态（§8）：每份笔记都有索引行，每一行的 Note 都能解析到磁盘上的文件——现在就把漂移修掉。
2. 在聊天里给摘要：新增 / 播种 / 失败 / 待人工核查的条目数、写出的笔记（`ABBREV` → 文件）、卫生修复、簇的地图或"接下来该读"清单，以及路由——核验手稿断言 → `/stage-cite-auditor`；起草相关工作 → `/stage-sect-drafter`；导入上游 refs 树 → `/stage-evid-curator`。
3. 一个工作会话提交一次，标题点名本 skill（§1）。

## 输出

- `manus/bibs/reference.bib`——带出处注释的条目（每条一行 `% src:`）、可选的 `%%` 簇块、以及给抓不到记录的论文用的 `%% Needs manual check` 块；只追加与重排，绝不从头重新生成。
- `notes/refs/<ABBREV>.md`——每篇读过的论文一份笔记：frontmatter `title:`、`venue:`、`year:`、`bibkey:`、`added:`；`## What it does`、`## Relation to ours`、精确到足以被拿来审计的 `## Citable facts`（§9b）。
- `notes/refs/refs_index.md`——`| Abbrev | Title | Venue | Year | Bibkey | Note |`，一份笔记一行；索引在不在册就是本 skill 的登记表状态字段（§8）。
- 按 Step 7 给出的聊天摘要。`manus/secs/` 里什么都不写，`mates/` 下什么都不写，`wkdrs/` 里不留报告。
