# TOOLS.md - Local Notes

## Telegram Topics (AI 工作台 -1003885917198)

- topic:1 — General（日常对话、TODO 提醒）
- topic:3 — Obsidian（裸 URL 自动抓取 → Clippings/，Obsidian 笔记工作流）
- topic:7 — Tools（安全审计、自我改进等系统任务）

## Obsidian Vault

- 路径：`~/Documents/second-brain`（symlink → Google Drive）
- Git：`/usr/local/data/second-brain.git`
- 约定：见 `~/Documents/second-brain/CLAUDE.md`
- **发送 vault 图片**：用 `~/.openclaw/workspace/.vault-staging/图片名.png`（cp 图片到此目录后通过 message 工具发送）

## Skills（位于 `~/.openclaw/workspace/skills/`）

| Skill | 触发方式 | 用途 |
|---|---|---|
| obsidian-capture | `/obsidian_capture` | 对话话题 → vault 笔记（含去重/合并/MOC 更新）|
| obsidian-summary | `/obsidian_summary` | 文档摘要 → vault 五阶段工作流 |
| obsidian-search | `/obsidian_search` | vault 搜索 + 知识问答 |
| obsidian-research | `/obsidian_research` | 深度研究 + 头脑风暴 |
| obsidian-link | `/obsidian_link` | 笔记关系分析 + wikilink 建议 |
| obsidian-clipper | 自动（Discord #obsidian-vault 裸 URL / PDF 附件）| 抓取网页全文 + 图片 → Clippings/ |
| obsidian-index | `/obsidian_index` | vault 语义索引（ChromaDB + bge-m3） |
| self-improve | `/self_improve` | 自我改进 + 记忆维护 |
| skill-creator | 手动 | 创建/打包新 skill |
| todo | `/todo` | TODO 管理 |

## 环境

- Node（x86_64）：`/usr/local/Cellar/node/25.6.1/bin/node`
- Brave Search：已配置
- Gateway restart：用 `gateway(action=restart)` 工具直接重启（需配置 `commands.restart=true`）
- clawhub：`/usr/local/Cellar/node/25.6.1/bin/node $(which clawhub)`
- 当前默认模型：`claude-sonnet-4-6`

## 重要教训

- **编辑 vault 文件时**：先 `cp` 到 `~/.openclaw/workspace/.vault-staging/`，所有编辑完成后再 `cp` 回 vault。避免在 Google Drive FileProvider 目录内多次写入触发递归冲突副本。创建新文件同理：先在 staging 写好，再一次性 cp 到 vault。
- `trash` > `rm`，但 Google Drive 文件用 `rm` 更可靠
- `openclaw configure` wizard 有时不能正确保存配置，用 `gateway config.patch` 更可靠
- clawhub install 默认装到 `~/.openclaw/workspace/skills/`
- **Browser 非 headless 模式**：LaunchAgent 启动 Chrome 需要 `TMPDIR` 环境变量，否则 GUI 初始化失败。修复：在 plist `EnvironmentVariables` 里加 `TMPDIR`（值用 `echo $TMPDIR` 获取）。如果重装系统需重新确认路径。

## launchd Agents

| Label | plist 路径 | 用途 | 频率 | 日志 |
|---|---|---|---|---|
| com.dk.vault-index | `~/Library/LaunchAgents/com.dk.vault-index.plist` | Obsidian vault 增量语义索引 | 每小时 | `~/.openclaw/workspace/logs/vault-index.log` |
| com.dk.secondbrain-sync | `~/Library/LaunchAgents/com.dk.secondbrain-sync.plist` | Google Drive → iCloud rsync 同步 Second Brain | 每分钟 | `/tmp/secondbrain-sync.log` |

管理命令：
```bash
launchctl start com.dk.vault-index   # 手动触发
launchctl stop com.dk.vault-index    # 停止
launchctl unload ~/Library/LaunchAgents/com.dk.vault-index.plist  # 注销
launchctl load ~/Library/LaunchAgents/com.dk.vault-index.plist    # 重新注册
```

## Cron Jobs

| Job | ID | 时间 | 用途 |
|---|---|---|---|
| weekly-self-improvement | 8bf068d4 | 每周一 09:00 (Asia/Shanghai) | 自我分析 → 提案给用户审核 |
| daily-todo-reminder | adf8f141 | 每天 10:00 (Asia/Shanghai) | 读取 TODO.md 发提醒到 topic:1 |
| healthcheck:security-audit | b86dcc27 | 每周三 09:00 (Asia/Shanghai) | 安全审计 + 版本检查 → topic:7 |
| discord-thread-inactive-check | 95592f9c | 每周一 09:00 (Asia/Shanghai) | 检查 #general 超过 7 天不活跃的 thread，有则提示 /discord_thread_cleanup |

## Telegram Cron Delivery 格式

- `delivery.to` 只填群组 chat_id：`-1003885917198`，不要加 `:topic:N`（格式错误会报 Unknown target）
- 发到指定 topic：在 payload 的 `message` 工具调用里用 `threadId=<topicId>` 参数控制
- 格式：`delivery.channel = "telegram"`, `delivery.to = "-1003885917198"`
