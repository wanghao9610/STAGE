# 项目记忆——索引

**语言：** [English](MEMORY.md) | 简体中文

> 本文件是中文对照版。权威、可写的项目记忆索引仍是 [`MEMORY.md`](MEMORY.md)；请不要在本文件中添加 memory 条目。

Claude、Codex、Cursor、DSH、Kimi Code、Pi 与 Qwen Code 的会话钩子都会逐字解析英文权威索引中的条目，因此下面的格式固定不变。

每项持久项目记忆占一行，最新的放在最前：

```text
- <type> · <scope> · <verified> · [<slug>](<slug>.md) — <one-line fact>
```

有效 `type` 为 `env`、`pref`、`insight` 和 `deadend`。有效 `scope` 为 `global`、`machine:<name>`、`cycle:<cycle>` 和 `manus:<path>`。机器专属条目放在 `.stage/memory/local/` 下。

已经由 `mates/`、`notes/`、`cycls/` 或 `tasks/` 负责的内容不应放在这里。记忆不能作为论文数字、会场规则或被引论文断言的来源。详见 [`memory_spec.zh-CN.md`](../../docs/mds/stage-workflow/memory_spec.zh-CN.md)。

<!-- 条目只写入英文权威索引 -->
