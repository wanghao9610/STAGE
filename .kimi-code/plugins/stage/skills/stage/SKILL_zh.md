---
name: stage
description: 将显式调用的 /stage 请求准确路由到一个 STAGE 学术写作工作流 skill。无请求参数时显示当前论文状态。已经选定具体 stage-* skill 后不要再使用本路由器。
disableModelInvocation: true
---

# 路由 STAGE 请求

从当前项目根目录读取 `.agents/commands/stage.md`，并将其作为权威路由名册。
当 `.env` 设置 `STAGE_LANG=zh`，或该变量未设置且对话使用中文时，用户可见措辞使用 `.agents/commands/stage.zh-CN.md`，但 skill 名称和路由决策仍以英文名册为准。

只为 Kimi Code 调整调用拼写：

- `/stage`（即 `/skill:stage` 的简写）是本通用路由器。
- 当名册写作 `/stage-<name> <argument>` 时，以 `/skill:stage-<name> <argument>` 调用选中的项目 skill。

不要在本路由器中复述已选 skill 的工作流。
对于未标记的 skill，通过 Skill 工具启动它，并遵循当前项目可用 skill 中由 Kimi 拥有的副本。
对于标有 `†` 的 skill，按名册要求请求确认，显示准确的 `/skill:stage-<name> <argument>` 调用，然后等待。

如果 `.agents/commands/stage.md` 缺失，应报告当前项目不包含 STAGE 路由名册，不要根据插件包猜测。
