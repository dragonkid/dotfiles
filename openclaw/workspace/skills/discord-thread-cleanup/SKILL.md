---
name: discord-thread-cleanup
description: Use when user wants to list or delete Discord threads/sub-channels in a channel. Triggers on /discord_thread_cleanup or requests like "清理子区", "删除 thread", "清理 Discord 子区".
user-invocable: true
---

# Discord Thread Cleanup

列出并删除指定 Discord 频道中的子区（thread）。

## 工作流程

1. 从对话上下文获取目标 guild 和 channelId，缺失时询问用户
2. 用 `thread-list`（含 `includeArchived: true`）列出所有子区
3. 展示列表，询问用户：删除全部、按编号选择、还是取消
4. 得到确认后用 `channel-delete` 逐条删除，报告进度

## 关键参数

- `thread-list`：需要 `guildId` + `channelId`
  - **⚠️ API 怪行为**：`includeArchived: true` 时反而查不到 active threads
  - 正确做法：先不传 `includeArchived`（或传 `false`）查 active；再传 `includeArchived: true` 查 archived；合并结果
- `channel-delete`：用子区自身的 `channelId`（即 threadId），加 `reason: "thread cleanup"`

## 安全规则

删除不可逆，必须先展示列表并获得用户明确确认，不得静默批量删除。
