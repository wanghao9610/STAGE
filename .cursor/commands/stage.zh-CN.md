# `/stage` — 把请求路由到正确的 STAGE skill

读取 `.agents/commands/stage.md`，并把其中的路由规则应用于用户在本消息中紧邻 `/stage` 输入的内容。

对于未标记的 skill，完整读取 `.cursor/skills/` 下由 Cursor 拥有的副本并遵循它。命令旁没有文本时选择不带参数的 `stage-flow-status`。
