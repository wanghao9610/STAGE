# 来源政策——bib 记录从哪来，什么可以改

`manus/bibs/reference.bib` 里的每个字段，要么追溯到本次运行抓回的一条记录，要么来自从 `mates/` 播种过来的上游条目。本文件固定记录可以从哪来、按什么顺序来、一条记录如何判定属于某篇论文、转录之后允许做哪些改动，以及每个 citekey 与出处行的形状。第一次抓取之前先读它。

## 唯一的硬规则

一个 bib 字段合法的唯一条件是：它出现在下面某个来源机器抓回的记录里，或出现在从 `mates/` 逐字节复制过来的上游条目里。绝不凭模型记忆写字段，绝不"顺手修正"记录里写错的内容，绝不靠推断补齐缺失字段——年份不行，页码不行，出版社也不行。抓不到记录的论文**不成为条目**，它进下面说的 `%% Needs manual check` 块。90% 转录加 10% 记忆的条目，就是一条编造的条目（规约 §9）。

Google Scholar 不是这里的来源：它没有 API，用 CAPTCHA 挡自动请求，而且它导出的 bibtex 本身就是机器生成的——经常缺页码、用缩写的 venue 串、偏爱预印本而不是已发表记录。人可以去读它；这个 skill 绝不爬它。下面这些数据库正是 Scholar 的 bibtex 所生成自的地方，既可抓取，又离源头更近。

## 抓取优先顺序

逐篇论文，命中第一个给出匹配记录的来源就停：

1. **DBLP**——CS 会议期刊的权威源。
   - 检索：`https://dblp.org/search/publ/api?q=<query>&format=json&h=10`
   - bibtex：`https://dblp.org/rec/<key>.bib?param=1`（压缩形式；`param=0` 会吐出 crossref 风格的条目——不要用）
   - 同一标题同时存在 CoRR（arXiv）记录与会议/期刊记录时，取已发表的那条。
2. **Crossref**——以 DOI 为准；期刊与很多会议论文集。
   - `https://api.crossref.org/works/<doi>`，或 `https://api.crossref.org/works?query.bibliographic=<title>&rows=5`
   - 通过内容协商拿 bibtex：`curl -LH "Accept: application/x-bibtex" https://doi.org/<doi>`
3. **Semantic Scholar**——覆盖面与引用数最好。用它的 `externalIds`（DOI、DBLP）**往回跳**到来源 1–2，而不是把它当 bib 来源。
   - 检索：`https://api.semanticscholar.org/graph/v1/paper/search?query=<q>&fields=title,year,venue,authors,externalIds,citationCount`
4. **arXiv**——只用于没有正式发表版本的工作。
   - `http://export.arxiv.org/api/query?id_list=<id>`（Atom）
   - 写成 `@misc`，带 `eprint`、`archivePrefix = {arXiv}`、`primaryClass`、`year`

每份抓回的原始内容，**先**缓存到 `wkdrs/refs_<date>/raw/<citekey>.<source>.<ext>` 再使用。`wkdrs/` 可再生、永不提交（规约 §1.2），所以这份缓存服务的是本次运行的自查和当天的重跑；能活下来的是 bib 里那行 `% src:` 与该条目在 `notes/refs/refs_index.md` 里的行——那两处是被跟踪的。

## 主题发现——按主题找候选

上面每一节回答的都是"**这一篇**论文的权威记录是什么"。这一节回答的是它之前那个问题——没人点过任何一篇的时候，到底哪些论文值得看——这也是本 skill 里唯一一处让查询去描述一个主题、而不是指认一篇论文的地方。记录规则不为它松半分：一条候选要成为条目，仍然得回头走一遍上面那套抓取优先顺序。

**端点。** 是相关性检索，不是记录查询：

- **Semantic Scholar 相关性检索**——`https://api.semanticscholar.org/graph/v1/paper/search?query=<q>&limit=20&fields=title,abstract,year,venue,authors,externalIds,citationCount`——主力。候选被收进来时，它的 `externalIds` 能直接往回跳到 DBLP 或 Crossref；它的 `citationCount` 不用第二次调用就给出了临时分数。
- **引文图扩展**，手上已经有几条候选之后——`https://api.semanticscholar.org/graph/v1/paper/<id>/references` 与 `/citations?fields=title,year,venue,citationCount`——一篇近邻工作站在谁肩上、以及谁回应了它。这能够到任何关键词查询都翻不出来的工作，也是结果太薄时该做的事：再造同义词是在假装覆盖，走引文图才是真去找。**扩展绝不扩大自己的输入**：它只在关键词扫掠已经产出的候选上跑，绝不在扩展自己翻出来的论文上跑。这就是它终止的原因，也是这里不需要任何计数的原因——一页 `/references` 就带回上百个节点，每一个还能再展开，所以一张允许自己喂自己的图没有最后一步，而一张只从"开跑之前就已经闭合的前沿"里取的图，走完那个前沿就无事可做了。挑与画像重合度最高的候选去展开，绝不挑被引最多的。
- **DBLP 文献检索**——`https://dblp.org/search/publ/api?q=<q>&format=json&h=20`——venue 型与作者型查询的召回更好。
- **arXiv 全文查询**——`http://export.arxiv.org/api/query?search_query=all:<q>&max_results=20`——够得着新到别处还没收录的工作。

**查询。** 由检索画像生成，差异要体现在种类上而不是措辞上，而这些种类就是下界：任务本身的词、机制的词、这个领域实际在用的同义说法（一条只讲你自己词汇的查询，只找得到和你共用词汇的论文）、benchmark 与数据集名字，以及论文给自己取标题时那种"X for Y"的形状——每个适用于本文的种类各出一条，不因为"看着没戏"就省掉哪一条。上界是饱和而不是条数：只要一条查询还能带回前面没出现过的候选就继续，直到某一条回来全是已见过的，这一轮扫掠就结束。每条查询都记下它返回了多少条命中——命中为零的也记，因为"查了，什么都没有"和"根本没查"是两种状态，只有其中一种构成停下来的理由。这份记录同时让停止条件事后可核：查干了的扫掠看得出来，早停的也看得出来。

**终止。** 这里没有任何东西靠请求额度来配给。额度会是一个谁也辩护不了、谁也没法拿日志去核的数字；取而代之，每个机制各自带一个停止条件，而每一个都看得见地写在这轮运行留下的记录里。扫掠在某条查询回来全是已见过的时候停。扩展停，是因为它的输入在开跑之前就已经闭合。作者挑完之后的部分，在挑中的论文都收完时停——挑了几篇是作者的决定，不是本文件配给的额度。没有哪一步可以一直跑下去，也没有哪一步需要把计数器递给下一步。礼貌是另一个问题、另一种东西——它是速率，由下面的分主机速率结清，绝不由总量结清。某个机制停下来时要点名是哪个条件让它停的：查干了、前沿走完了，还是主机拒绝了。绝不悄悄拿记忆把剩下的补齐。

**匿名。** 当前周期的 `venue.yml` 写了 `anonymized: true`，或 `.env` 设了 `ANON=true` 时，查询只带主题词：绝不带手稿标题，绝不带它里面的原句，也绝不猜作者。查询会离开这台机器，而一条用论文自己句子拼出来的查询，能让握有日志的人认出一篇匿名投稿。

**一条命中是线索，不是事实。** 检索返回的内容一律不誊写进 `reference.bib`：命中里的标题常常是预印本那版的，venue 字段常常为空或不对，作者名单常常被截断。用户挑中的候选，要从抓取优先顺序的最上面重新抓一遍、和任何论文一样做三项匹配；权威记录到那时解析不出来的候选，就不成为条目。缺席是对称的——什么都没返回是一次抓取的结果，绝不是"不存在这样的工作"的证据。

## 记录与论文的匹配判定

三项全部对上才算匹配：

- **标题**——忽略大小写与标点，副标题算在内；
- **第一作者姓氏**；
- **年份**——±1，用来吸收 arXiv 到正式发表之间的时差。

只有一两项对上不算匹配——工作坊论文、它的扩展版、一篇综述之间标题高度相似是常事。有歧义 → 绝不猜：这篇论文进 `%% Needs manual check` 块，候选与它们的 URL 进 index 的 §6。

## 标题的解析

论文可以只用标题点名，于是标题就是全部可匹配的东西。解析用上面那些检索端点（DBLP 检索、Crossref 的 `query.bibliographic`、Semantic Scholar 检索）加匹配规则的归一化：忽略大小写与标点。当且仅当恰好有一篇论文的记录标题与输入相等时解析成功——完整标题，或副标题冒号之前的主标题。有几篇不同的论文都匹配（工作坊论文与它的扩展版是经典一对），或者最佳命中只是"接近"→ 问，一个直接问题列出每个候选的标题、venue、年份与 URL；哪里都找不到 → 进待人工核对块。解析成功之后它就只是一篇普通论文：记录照样走抓取顺序、三项匹配规则和已发表优先。

## 已发表优先于预印本

只要存在已发表记录就用它；arXiv id 只有在抓回的记录本来就带它时才保留。只有 arXiv 版的工作是正当的，照收——在 index 里标 `preprint`（‡），类型写 `@misc`。

## Citekey

`<年份>_<方法>_<第一作者姓氏>`——例如 `2021_CLIP_Radford`、`2023_SAM_Kirillov`。

- **年份**——被引用的那条记录的年份（已发表记录胜出时，就是发表年）。
- **方法**——论文自己写的缩写（`CLIP`、`DETR`、`SAM`）。没有 → 从标题自拟一个紧凑的 CamelCase 名（`MaskDistill`），并在 index 里标为自拟（†）。
- **第一作者姓氏**——ASCII，无变音符，无空格：`Müller` → `Mueller`，`van den Berg` → `vandenBerg`。
- 冲突 → 追加一个小写字母（`2021_CLIP_Radforda`）。key 在全文件唯一。

citekey 是你唯一"创作"的字段。其余全部是转录。

有两类 key 这套方案不碰。**从 `mates/` 播种过来的条目**逐字节保留它的上游 key：key 正是这条条目与它来自的那份导入文件之间的纽带，改写它就同时弄断这条纽带和记录它的那行 `% src:`。以及**文件里已有的历史 key**——接入时随论文仓库一起进来的，或这套方案之前写下的——原样保留：改掉一个 `manus/` 正在引用的 key 就是弄断那条引用，而这个 skill 从不编辑 `manus/secs/`。新条目按方案走；两种 key 并存的状态写进 index 的 §8，不静默修补。

阅读笔记文件名用的 `ABBREV` 是另一个串，保持原样——`notes/refs/CLIP.md` 与 citekey `2021_CLIP_Radford` 并列，`方法` 那一段就是两者的纽带。笔记 frontmatter 的 `bibkey:` 记完整 citekey。

## 出处注释——`% src:`

每条条目正上方一行，写的出处与 index 出处表登记的是同一个：

- 抓回的记录：`% src: <记录 URL> (fetched YYYY-MM-DD)`——URL 与日期同该条目在 index 里那一行完全一致。
- 从 `mates/` 下导入的 refs 树合并过来的条目：`% src: mates/<slug>/metds/refs/reference.bib (seeded YYYY-MM-DD)`。
- 用户手工添加、没有抓取记录的条目：`% src: user-supplied`。

写进去之前先把 URL 里的 `mailto` 参数去掉，因为 `reference.bib` 里任何注释都不许含 `@`。BibTeX 在条目之外也扫这个字符，会把 `%` 行里的 `@article` 当成一条新记录的开始，把它下面那条静默吞掉——bib 照样解析通过，key 却消失了，最后表现成一个离病因很远的未定义引用。要提某个类型就写"an article-type entry"，绝不写字面量。

这行注释属于条目，不属于它在文件里的位置：重新分类时两者一起移动，从上游复制进来的条目也带着它的出处一起到达。

## 待人工核对块——`%% Needs manual check`

抓不到权威记录的论文不写成条目，写成这个块里的一行注释。块固定在文件最后，排在所有类别块之后：

```text
%% Needs manual check — 2 papers, no authoritative record as of 2026-08-05
% "Learning to Segment Everything with Less" — DBLP / Crossref / Semantic Scholar / arXiv 均无匹配记录；见 refs_index.md 第 6 节
% "Prompt Tuning for Dense Prediction" — 三条候选标题高度相似，无法判定；候选与 URL 见 refs_index.md 第 6 节
```

一行一篇：标题，加上试过什么、卡在哪。绝不写一条注释掉的条目——`%` 行里那个记录起始字符正是上一节警告的东西，而注释掉的条目既是最容易顺手写下的形式，代价也最大。URL 同理不写进来；细节留在 index 的 §6，块里那行指过去。

论文后来抓到了记录，它就成为一条正式条目，那一行同时从块里删掉。它绝不同时出现在两处。

## 规范化——封闭清单

允许的只有这些，多一样都不行：

- 把来源自带的 key 换成 citekey。
- 删噪声字段：`bibsource`、`biburl`、`timestamp`、`abstract`、`keywords`、只是重复 DOI 的 `url`、venue 本身已经固定的 `month`。
- 给 BibTeX 会小写掉的大写字母加花括号保护：`{CLIP}`、`{ImageNet}`、`{T}ransformer`。这改的是渲染，不是内容。
- **用抓回记录里本来就有的名字**把 venue 缩写展开：DBLP 的 `booktitle` 一般本来就写着 `IEEE/CVF Conference on Computer Vision and Pattern Recognition (CVPR)`，写下它属于转录。凭空造一个记录里从未出现过的全名不属于。

不允许：补记录没有的页码、编者、出版社、卷号、DOI 或年份；"修正"作者缩写或姓名顺序；把两条记录的字段拼成一篇论文的一条（只选一条记录；index 里写明选了哪条）。

## 条目类型与字段

- `@inproceedings`——会议论文集：`author`、`title`、`booktitle`、`year`，记录里有就带上 `pages` / `publisher`。
- `@article`——期刊：`author`、`title`、`journal`、`year`，记录里有就带上 `volume` / `number` / `pages`。
- `@misc`——仅 arXiv：`author`、`title`、`year`、`eprint`、`archivePrefix`、`primaryClass`。
- `@book`、`@incollection`——按记录本身写。

AI 会议的模板（NeurIPS / CVPR / ICML / ICLR / ACL）会渲染 author、title、booktitle/journal、year、pages、volume、publisher。记录里有就留着；其余不要凑。

这些字面量写在这里是安全的：禁 `@` 那条规则管的是 `reference.bib` 内部的注释——BibTeX 在那里扫描——而不是一份没有任何程序解析的政策文档。

## 影响力分（0–10）——index 的信号，绝不是 bib 字段

紧挨着"相关"的第二根轴：领域给了这项工作多少注意力。它定详略——index 突出哪些条目、`position` 把哪些工作排在一簇之首、相关工作必须先接住谁——绝不决定什么能进这个文献库。每个输入都是运行中抓取的指标，连同抓取日期登记在 index 里；合成只有下面这套固定算式，别无其他。印象绝不入分，任何一个分量也绝不进 `reference.bib`。

**总分 = 0.40 × 引用分 + 0.25 × 发表分 + 0.35 × 代码分**，保留一位小数，各分量按对数分档：

- **引用分**——年均引用 `c = citationCount ÷（当前年份 − 发表年份 + 1）`，用手头已有的 Semantic Scholar 记录：`c ≥ 1000 → 10`，`≥ 300 → 9`，`≥ 100 → 8`，`≥ 30 → 6`，`≥ 10 → 4`，`≥ 3 → 2`，其余 `1`。累计引用偏袒老论文；按年折算才让 2024 年的论文站得到 2017 年的旁边。
- **发表分**——抓回记录的 venue 字段对 `venue-tiers_zh.md` 的档位表匹配：旗舰 `10`，二档 `7`，其他正式发表 `4`，仅预印本 `2`。
- **代码分**——没有官方仓库 → `0`。官方仓库——论文自己页面挂出的那个；从别处找到的一律记 `unofficial`、不计分——起步 `4`，星标 `≥ 10k → +5`，`≥ 3k → +4`，`≥ 1k → +3`，`≥ 300 → +2`，其余 `+1`，12 个月内有提交再 `+1`；封顶 `10`。

三条规则随分同行：

- **残缺就标，绝不猜。** 抓不到指标的分量弃权，剩余分量的权重归一化；总分带 `*`（`6.4*`）。论文正文从未抓过的条目，天生没有代码信号。
- **注明日期，因为指标会漂。** 每个子指标在 index 里带抓取日期；`score` 模式重抓指标、重建整表。
- **`new` 是旗标，不是判决。** 发表 ≤ 18 个月的论文在分数旁标 `new`：引用速度尚未定型，行文把低分的 `new` 论文当作未经证明，而不是可以忽略。

分档与权重按 CS/AI 文献校准，也正因如此放在这个文件里——换领域的项目改的是这些常数。常数可改；"印象不入分"不可改。

### 指标从哪来

- **引用数**搭上面已经列出的 Semantic Scholar 调用——`citationCount` 就在检索的字段表里，所以录入时不额外付费。`score` 模式一次调用刷新整个 bib：`POST https://api.semanticscholar.org/graph/v1/paper/batch?fields=citationCount,year,externalIds`，请求体里最多 500 个 id（`{"ids": ["DOI:…", "ARXIV:…", …]}`），id 取自 index 已经登记的出处。批量接口解析不出来的条目保留旧值与旧日期。
- **发表档**是离线的：抓回记录的 venue 字段对 `venue-tiers_zh.md`。
- **星标与最近提交**——`https://api.github.com/repos/<owner>/<repo>` → `stargazers_count`、`pushed_at`。响应先缓存成 `<citekey>.github.json` 再用。未认证的 GitHub 每小时允许 **60 次请求**——这是最紧的那道限制，仍比一次运行需要的仓库数多出几倍；和对待其他主机一样，约 1 秒 1 次串行。这里的 403/429 通常**就是**小时配额：退避一次，然后记下失败并把该分量标为未抓到——按残缺规则给分，绝不进重试循环，绝不写一个凭记忆的数字。

**只认官方仓库。** 一个仓库合格的唯一条件是论文自己的页面挂出了它：arXiv abs 页、项目页，或论文的 PDF/HTML 本身。发现顺序：录入步骤本来就要读的论文页 → arXiv abs 页 → 论文的 Hugging Face papers 页（`https://huggingface.co/papers/<arxiv-id>`）。Papers with Code 已于 2025 年 7 月关停——不要抓它。用其他任何方式找到的仓库（代码搜索、某个引用它的仓库的 README）在 index 里记 `unofficial`，绝不计分。

## 限速与失败

- 按主机串行：DBLP 与 Semantic Scholar 约每秒 1 次，Crossref 约每秒 3 次（加 `mailto` 走它的礼貌池，写进 `% src:` 行之前再把它去掉）。这份预算属于整个会话对每台主机，不是每个 agent 一份。
- 论文页面——arXiv abs/HTML、ACL Anthology、CVF open access、项目页——用同样的礼貌默认：约每秒 1 次，对 arXiv 约每 3 秒 1 次，那是它要求的。
- HTTP 429 / 503 → 指数退避（2s、4s、8s），最多重试 3 次，然后放过并记下失败。限速永远不是凭记忆补缺口的理由。
- 某个来源什么都没返回，记成"not found in `<source>`"——那是一次抓取的结果，不是这篇论文不存在的证据。

## 阅读收集者合同

阅读那一步扇出时，一个只读委派者返回什么（`SKILL_zh.md` 原则 9）。一篇论文一个，而且它只对着主 agent 已经抓好、缓存在 `wkdrs/refs_<date>/raw/` 下的那份论文页面干活——它不打开任何 URL，不写任何文件，只返回下面这些字段：

- `abbrev_suggestion`——论文给自己取的代号（`CLIP`、`DETR`），或者 `none`。文件名仍由主 agent 定：它必须在 `notes/refs/` 里唯一。
- `what_it_does`——3–6 句，用你自己的话写。这是 `## What it does` 的素材，不是写好的那一节。
- `facts`——`[{fact, where, quote}]`，`## Citable facts` 的候选。`fact` 是一个自足的要点，数字要带着它的数据集、指标与设置一起走；`where` 是它出自哪一节、哪张表、哪个公式；`quote` 是从缓存页面里逐字符抄下来的至多 25 个词。主 agent 拿这条引文去缓存里搜，所以这里写成转述，就等于这条事实注定被丢掉。
- `floor_evidence`——`{sections_reached: [...], results_table: <表题加一行，逐字>}`，或者 `not reached`。底线是摘要、intro、方法与主结果表；确实没有结果表的论文在这里说明，并点名什么顶了它的位置。
- `repo_named`——这篇论文自己的页面挂出来的仓库，或者 `none found`。你不去抓它；那一次 GitHub 调用是主 agent 的。
- `relation_material`——`[{claim, where}]`：`## Relation to ours` 的原始素材，绝不是那一节本身——那一节要对着手稿的故事与主张台账写，而这两样都没有交给你。
- `failures`——`[{what, why}]`：缓存页面里没有的那一节、解析不出来的表、抽不出文字的扫描件。

此外什么都不返回：不给 frontmatter，不给 `bibkey:` 或 `added:`，不给索引行，不给影响力分，也不给起草好的 `## Relation to ours`。这些属于写文件的那个会话，以及一份委派者根本看不到的 `reference.bib`。

**主 agent 拿这份返回做什么。** 写笔记之前，每条 `quote` 都要在缓存页面里搜到：搜不到的那条事实丢掉，并在摘要与 index 的 §7 里点名。`floor_evidence: not reached` 与正文压根抓不到是同一个结果——bib 条目保留，不写笔记。返回里的任何东西都绝不进 `reference.bib`：那里的字段来自书目记录，不来自论文自己的页面。

## 收尾前的自查

1. `reference.bib` 里每个 citekey 都在运行缓存里有对应的原始内容**且**在 `refs_index.md` 里有一行出处**且**条目上方那行 `% src:` 与该行的 URL 和日期一致。播种来的条目那一行写 `mates/<...>`；用户手工添加的写明是手工添加。
2. 随机重抓 5 条（`verify` 模式下是全部），与文件逐字段 diff。有出入 → 把文件改成与来源一致，并重查该条所在的整批。
3. 已经装好 bib 解析器就用它解析文件；没有就机械地检查花括号配平与 key 唯一性。绝不为跑这一项去安装什么——说明这次是手工核的。
4. 没有条目的必填字段为空；没有 key 出现两次。
5. `%% Needs manual check` 块里没有哪一篇同时已是条目；块里没有任何一行含 `@`。
