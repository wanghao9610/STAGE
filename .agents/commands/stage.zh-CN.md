# 路由 STAGE 请求

> 本文件是 [`stage.md`](stage.md) 的中文对照版。运行时路由以英文原文件为准。

使用下表把论文写作请求准确路由到一个 STAGE skill。

| Skill | | 用途 |
| --- | --- | --- |
| `stage-proj-adopt` | † | 接入已有论文仓库 |
| `stage-evid-curator` | | 导入并登记证据；对照 manifest 核查磁盘上的证据文件（`check`，默认） |
| `stage-stry-coach` | † | 塑造论文故事并建立初始论断；选定 venue 并开启一个投稿周期 |
| `stage-outl-planner` | † | 规划章节、篇幅、图、表与记号 |
| `stage-sect-drafter` | | 起草或修订一个章节 |
| `stage-tabs-builder` | | 构建一张可追溯证据的表格 |
| `stage-figs-designer` | | 审计图的清单；规划清单（`plan`）；构建或修订一张图或 teaser 图（`teaser`） |
| `stage-refs-curator` | | 整理参考文献记录与阅读笔记；查找值得引用的工作（`discover`）；为相关工作对文献库聚类（`position`）；重新抓取每个 bib 条目并逐字段比对（`verify`） |
| `stage-copy-editor` | | 在不改变论断或证据的前提下恢复自然的学术表达；记录作者的文风档案（`style`） |
| `stage-clms-auditor` | | 追溯手稿中的每个数字 |
| `stage-cite-auditor` | | 核验每条引用断言 |
| `stage-peer-reviewer` | | 模拟五种视角的评审，或单遍评审（`quick`）；评审一篇外部论文（`extern=<path>`） |
| `stage-resp-writer` | † | 起草回复与承诺清单 |
| `stage-subm-packer` | † | 预检并打包投稿材料或 camera-ready（`camera`）；把论文转换为 venue 模板（`convert`） |
| `stage-pstr-builder` | † | 规划、制作或检查海报 |
| `stage-flow-status` | | 汇报状态与唯一的下一步行动 |

标有 † 的六个 skill 只能显式调用，因为每个都控制一项属于作者的决定。通用 `/stage` 路由绝不直接启动它们：先请求明确确认，给出准确的 `/stage-<name> <argument>` 命令，然后等待。任务明确匹配时，可以选择其余十个 skill。

请求为空时选择 `stage-flow-status`。否则，说明选中的 skill、选择它的一句话理由，并把原请求作为参数传入。未标记的 skill 应通过当前宿主的原生 skill 机制启动，并使用该宿主拥有的副本。如果两个 skill 同样合理，只问一个简洁问题，不要混合两者范围。绝不能绕过 skill，凭一般知识直接生成归它所有的产物。
