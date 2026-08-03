# Venue Template Conversion（venue 模板转换）

> 本文件是 `venue-convert.md` 的中文对照版，随英文版同步维护，供人阅读；运行时装载的仍是英文版。两版冲突时，以 `venue-convert.md` 为准。

`stage-subm-packer` 如何把手稿变成一份能在官方 venue class 下编译的副本。做转换时装载——`convert` 模式，或者周期的 `template:` 指名了一份已注册模板包的打包运行。`SKILL.md` 写规则，本文件写流程。

一句话形状：**读 `manus/`，写出一份独立副本，每次运行都从头重新生成这份副本。** 没有就地换模板，没有第二份真值源，也没有增量同步。

## 契约

四条。每一条之所以存在，是因为绕过它的那个显而易见的捷径，会产出一篇错得没人察觉、直到评审人察觉的论文。

1. **模板包是唯一的真值源。** venue 的 class、style 与 bibliography style 文件来自用户提供的官方模板包。绝不去抓一份，绝不凭"CVPR 的 class 大概长这样"的记忆重建一份，绝不自己写一个 `.cls`（规约 §9）。一份凭记忆而非凭阅读得到的 class，和一个凭记忆而非凭导入得到的指标是同一种缺陷——它通常很接近，而"通常很接近"不是 chair 会接受的版式。
2. **`manus/` 永不被编辑，也不往里新增任何东西。** 不改 `main.tex`，不改 `secs/`，不改 `tabs/`，不改 `bibs/reference.bib`，也不动 `stys/`——模板包落在 `cycls/<cycle>/template/`（第 1 步）。手稿这棵树只被读，仅此而已。
3. **官方文件逐字节拷贝，永不打补丁。** 当 venue 自己的 class 看起来需要改一下副本才能编译时，那个改动属于生成的 `compat.sty` 或生成的 `main.tex`——两者都装不下时，属于报告。悄悄改一个 venue class，就是悄悄让这次投稿不合规。
4. **副本是生成的，不是写出来的。** 输出目录下的一切都活不过下一次运行。在那里手工打的补丁是会消失的补丁；真正的修改要么去 `manus/`（经由拥有那个文件的 skill），要么改本文件里的转换规则。

## 1. 解析模板包

**模板包住在 `cycls/<cycle>/template/`**——一个周期一份，与该周期的 `venue.yml`、`reviews/`、`response/` 并列，因为一份 venue 模板属于一次 venue 尝试，生命周期恰好就是那么长。明年改投是另一个周期、另一份模板包，两者不必靠目录名去区分。

`venue.yml` 的 `template:` 指名的是**模板包里那个 class**，不是目录：`template: cvpr` 意味着生成的 `main.tex` 写 `\documentclass{stys/cvpr}`。一份模板包会带好几个 class 与 style 文件、常常不止一个像样的入口，所以需要这个字段来挑一个。

它刻意不放在 `manus/` 下。那棵树是一个**被扫描的命名空间**——`lint.sh` 会数它下面每个 `*.tex` 里的 `\todo{`，并在其中搜身份泄漏——而模板包自带的示例 `.tex` 带着样例作者名和一节 Acknowledgments。在 `ANON=true` 下，那就是一次由第三方文件引发的硬 lint 失败，而那个文件谁都无权编辑，于是每次打包都失败，永远如此。

- **给了 `kit=<path>`**——路径是一个 zip 或一个目录。把它整份、原封不动地解包或拷贝进 `cycls/<cycle>/template/`。若该目录已存在且内容不同，先展示差异再提问（规约 §7.2）：在一个周期底下把模板包换掉，等于把此前每一个决策所依据的页数预算换掉。
- **没给 `kit=`**——`cycls/<cycle>/template/` 必须已经存在。不存在就停下，并给出唯一能解开它的东西：官方模板包的路径。
- **`template:` 缺失、为空或为 `arxiv`**——不做转换。包就是用 `stys/arxiv.cls` 构建出的预印本形态，那也正是手稿本来编译成的样子。把这一点说出来，而不是转换成一个空。

模板包是纳入版本管理的，不是被忽略的：只有排版它的那个 class 也在同一段历史里，一个包才谈得上能从冻结 tag 复现。venue 禁止再分发的模板包由用户定夺——说清正要提交的是什么，让他们决定（§7.2）。

## 2. 读模板包

在解包后的模板包里读：它的示例 `.tex`、它的 `.cls` 与 `.sty` 文件、它随附的 `.bst`（如果有），以及任何 README 或作者须知。提取并记下六件事：

| 什么 | 通常在哪 |
|---|---|
| 确切的 `\documentclass` 行及其选项 | 示例 `.tex` 的第一行 |
| class 不加载而示例加载的宏包 | 示例的导言区 |
| 原生的 title / author / affiliation 宏及其确切签名 | 示例的导言区，以及 class 里的 `\newcommand` |
| 模板包期望的 bibliography style | 示例的 `\bibliographystyle`，或随附 `.bst` 的名字 |
| 匿名开关 | 一个 `\...finalcopy` 命令、一个 `final`/`review` class 选项，或一个 `\ifreview` 之类的条件 |
| abstract 是环境还是命令 | 示例的正文部分 |

模板包没有展示的东西一律不臆造。一个模板包里没有匿名开关的 venue，就是没有匿名开关，报告里写明匿名只能另行处理——而不是从别的 venue 借一个 `\cvprfinalcopy` 过来。

## 3. 搭出副本

输出目录：`convert` 模式下是 `wkdrs/builds/<cycle>_<template>_<date>/`；打包运行里是包的源码目录。无论哪种，它都是整份重新生成的。

逐字节、不加编辑地拷进去：

- `cycls/<cycle>/template/` 里每一个 `.cls`、`.sty`、`.bst` → 副本的 `stys/`（模板包的示例 `.tex`、README 与样例图留在原地——副本只装编译这篇论文所需的东西，别的都不装）
- `manus/stys/stage.sty` → 副本的 `stys/`——**写作层原样发出。** 它是一个自足的 package，不带选项地加载内容级宏包（所以在已经拉过这些包的 class 下二次加载是静默的空操作），并且携带 `\todo`、`\parahead`、`\cmark`、`\tablestyle`、`x`/`y`/`z`/`P`/`Y` 列类型、`Light*` 行底色、`\figref`/`\tabref`/`\eqnref`、`accentcolor` 兜底以及 `\graphicspath{{figs/}}`。这一层本来就是为跨模板存活而设计的；不要在 `compat.sty` 里重新实现它的任何一部分。
- `manus/secs/`、`manus/tabs/` → 不加编辑
- `manus/figs/*.pdf` → 副本的 `figs/`。**不含 `figs/srcs/`**：论文需要的是渲染出的图，而一个绘图脚本或 `.drawio` 文件可能把路径、用户名或机器名带进一次匿名投稿。
- `manus/bibs/reference.bib` → 副本的 `bibs/`

venue 需要另一种引用样式，那是生成的 `main.tex` 里的一处 `\bibliographystyle{...}` 改动，绝不是对 `reference.bib` 的编辑。

## 4. 生成 `compat.sty`

`stage.sty` 覆盖的是写作 skill 会写进手稿的那些宏。它**刻意不**覆盖的，是 `stys/arxiv.cls` 在它之上再加载的那些内容级宏包——而一个照着那些宏包写出来的 section 或 table，在一个都不加载它们的 venue class 下会挂。`compat.sty` 恰好补这个缺口：

| `arxiv.cls` 提供而 `stage.sty` 没有 | 在正文文件里表现为 |
|---|---|
| `algorithm`、`algpseudocode` | `\begin{algorithm}`、`\State`、`\Require` |
| `\algref{alg}{line}`——class 的双参形式（`arxiv.cls:104`） | 算法行级引用；`stage.sty` 只提供单参兜底 |
| `mathtools`、`bm` | `\coloneqq`、`\bm{}`、`\DeclarePairedDelimiter` |
| `siunitx` | `\SI{}`、`\num{}` |
| `nicematrix` | `NiceTabular` |
| `enumitem` | `\begin{itemize}[leftmargin=*]` |

**只加拷进来的正文文件真正用到的那些。** 逐条在 `secs/`、`tabs/`、`figs/` 里扫这些构造，命中了才把对应宏包加进去。把 `arxiv.cls` 的整份 `\RequirePackage` 清单抄进 `compat.sty`，正是制造 option clash 的办法：venue class 通常已经带选项加载过它自己的 hyperref、geometry 与 caption 设置，一次不带选项的二次加载会跟它打起来。

生成的 `main.tex` 里的加载顺序：venue class，然后 `stys/stage`，然后 `compat`。`compat.sty` 里凡是 venue class 已经定义过的，一律用 `\providecommand`——绝不用 `\renewcommand` 盖掉一个 venue 的宏。

## 5. 生成 `main.tex`

由 venue 自己的宏（第 2 步）填上从 `manus/main.tex` 读出的值构成。要跟着那份导言区里可达的 `\input` 链走：值并不总是字面写在 `main.tex` 里——`$stage-outl-planner` 会把 abstract 移进 `manus/secs/0_abstract.tex`，只在原处留一个 `\input`。

要搬过去的：

- **标题、作者、单位、贡献说明、关键词、元数据链接**，用 venue 的宏重新发射。每个 `arxiv.cls` 命令装的是什么，见下表。
- **论文自己的 `\newcommand` / `\renewcommand`**，来自 `manus/main.tex` 的导言区——`\method` 那一类。它们属于这篇论文而不属于框架，所以既不在 `stage.sty` 也不在 `compat.sty` 里，而正文依赖它们。
- **`\input{secs/...}` 的顺序**，与 `manus/main.tex` 定下的完全一致——`<n>_` 前缀是承重的（规约 §5.5）。
- **`\bibliographystyle{...}`** 设为模板包的样式；`\bibliography{bibs/reference}`。
- **附录**，若 `manus/main.tex` 有，则用 venue 自己的附录机制。venue 在"附录在参考文献之前还是之后"上做法不一；照模板包的示例走，并在报告里说明用了哪种顺序。

### `arxiv.cls` 独占的部分

下面每一个命令都由 `stys/arxiv.cls` 定义，别处都没有。在一个 venue class 下，每一个要么被原生等价物重新表达，要么被丢掉——原样留着，它就是一个未定义控制序列，副本编译不过。

| `arxiv.cls` 命令 | 行号 | 变成 |
|---|---|---|
| `\affiliation[key]{...}` | 330 | venue 的单位宏 |
| `\contribution[mark]{...}` | 335 | venue 的同等贡献 / 通讯作者说明，或一个 `\thanks` |
| `\keywords{...}` | 341 | venue 的关键词宏；它没有就丢掉 |
| `\code` `\project` `\dataset` | 351–354 | 用 venue 自己的写法排一行链接，或丢掉；匿名下要涂掉 |
| `\correspondence{...}` | 355 | venue 的通讯作者说明 |
| `\paperdate{...}` | 356 | 丢掉——venue class 自己给论文集标日期 |
| `\paperstyle{...}` `\papercolor{...}` | 359、180 | **丢掉。** 它们驱动的是 `arxiv.cls` 的标题面板，没有 venue 等价物 |
| `\beginappendix` | 617 | venue 的附录机制，通常是 `\appendix` |
| `\metadata[label]{value}` | — | 一行链接，或丢掉 |

### abstract 要搬家

这是最容易漏、而且一漏就必然编译不过的那一处搬迁。

`arxiv.cls` 把 abstract 当作**导言区命令** `\abstract{...}`，所以 `manus/main.tex` 在 `\begin{document}` 之前调用它，`$stage-outl-planner` 的 `\input{secs/0_abstract}` 也待在导言区。而几乎每个 venue class 要的都是**正文里的环境** `\begin{abstract}...\end{abstract}`，位置在 `\maketitle` 之后。

所以：把 abstract 的正文抽出来——从 `manus/main.tex` 的 `\abstract{...}`，或者从导言区 `\input` 的那个文件里——再用 venue 自己的机制在正文里重新发射。**不要**把 `\input{secs/0_abstract}` 放进生成的导言区：venue class 要么根本没定义 `\abstract`（编译报错），要么定义了一个不兼容的（静默地排错）。`secs/` 的其余部分照常在正文里 `\input`，一字不改。

### 匿名

它不是一个单独的模式，而是跟着这次运行本来在做的事走：

| 运行 | `venue.yml` | 副本 |
|---|---|---|
| `convert`，或送审包 | `anonymized: true` | 匿名：作者写 "Anonymous Author(s)"、单位写 "Anonymous Institution"，`\code`/`\project`/`\dataset` 的 URL 换成 "Link redacted for review"，打开模板包的匿名开关 |
| `camera` 包 | `anonymized: false` | 完整元数据，打开模板包的 final-copy 开关 |

`.env` 的 `ANON` 与 `venue.yml` 的 `anonymized:` 不一致，在主工作流里本来就是一处停止（规约 §3.4）——转换绝不靠挑一个来把它化解掉。

## 6. 构建、迭代、数页数

用和其他一切相同的入口、相同的引擎构建这份副本：

```
bash execs/run.sh --main <copy>/main.tex
```

它以副本自己的目录为工作目录、以副本的 `stys/` 上 TEXINPUTS 来编译，所以构建通过就证明了这份副本是自足的——那正是重点。产物落在 `<copy>/.build/`，绝不落在 `wkdrs/builds/`，于是 `lint.sh --no-build` 复用的那份手稿构建不会被覆盖。

`--main` 是随本功能才有的，所以一个 `execs/run.sh` 早于它的论文仓库，会把这个参数当作未知选项一路传给 latexmk。构建之前先查一次：`bash execs/run.sh --help` 里有没有列出 `--main`。没有就停下——副本已经写好了，构建是那个跑不起来的步骤——并给出那一行修法：`bash execs/update.sh`，它会连同 skill 树与工作流文档一起同步这个入口脚本。若跑完它 `--main` 仍然不在，说明这个仓库的 `update.sh` 本身也早于这次改动，而它老到还不会自我更新——新版会装上自己的替代品，旧版不会——那就得手工从上游拷贝这两个入口脚本，把这一点说出来就是报告本身。绝不用一条裸 `latexmk` 命令把它糊过去：§3.3 让每一次构建都走入口脚本，好让引擎只有一个来源，而一份用别的命令构建出来的包，并不能证明 `execs/run.sh` 构建得了它。

失败时，改 `compat.sty` 或生成的 `main.tex` 再重建。绝不给 venue 文件打补丁（契约第 3 条），也绝不为了让它编译通过而丢内容——映射不过去的内容是被报告的，不是被删掉的。

**这次构建报出的页数才是算数的那个。** `lint.sh` 量的是预印本构建，那是另一个 class 下的另一份文档：作为写作期的代理指标有用，但不是"这篇论文放不放得下"的答案。拿这个页数去对 `page_limit_main`：

- **打包运行，超限**——硬阻断，路由给 `$stage-copy-editor`。
- **`convert` 运行，超限**——连同超出量一起报出来，不设关口。
- **`venue.yml` 的 `confirmed:` 未设**——报出页数，并说明该上限尚未确认。未确认的上限不构成约束（规约 §9c）。

## 7. 报告

分两处，而这个拆分正是重点：聊天回复只被读一次，待办清单会在下一次运行时再被读到。

**`tasks/<cycle>_venue.md`**——每一条需要人处理的发现，一条一行 `- [ ]`，各带一个稳定的 `V<n>` 编号和拥有这个修法的 skill。只由 `convert` 写；打包运行读它，并把自己的发现放进 `SUBMISSION_<date>.md`。要更新它，不要重新生成它：先读已有的文件，把每个已勾选的条目保持勾选、不再重新提出，真正新的发现以下一个空闲编号追加，不再适用的条目连同理由勾掉——绝不删除。第二十次跑转换，对着一份用户已经处理过的清单，应该产出一个空 diff。

**聊天回复**，结论先行，然后是：

- 副本在哪，它对照上限的页数，以及该上限的确认状态
- 映射了什么：class 与选项、用到的标题元数据宏、bibliography style、匿名开关、`compat.sty` 不得不补的东西
- **丢掉了什么**，一行一条——`\paperstyle`、`\papercolor`、`\paperdate`，以及其他一切没有 venue 等价物的东西
- 什么需要人来处理：转换没有自动化的某条 venue 规则、模板包没提供而内容需要的某个宏包、任何没能一一对应映射过去的东西、附录顺序的选择

绝不为了让报告显得干净而让一处缺口静默通过。一次靠悄悄丢掉关键词而编译通过的转换，是一次会在投稿系统那里给人惊喜的转换。
