# TOOLS.md - Local Notes

## Telegram Topics (AI 工作台 -1003885917198)

- topic:1 — General（日常对话、TODO 提醒）
- topic:3 — Obsidian（裸 URL 自动抓取 → Clippings/，Obsidian 笔记工作流）
- topic:7 — Tools（安全审计、自我改进等系统任务）

## Obsidian Vault

- 路径：`~/Documents/second-brain`（symlink → Google Drive）
- Git：`/usr/local/data/second-brain.git`
- 约定：见 `~/Documents/second-brain/CLAUDE.md`
- 注意：Google Drive FUSE 导致 `trash`/`rm` 对已有文件可能失败，新建文件可以 `rm`

## Skills（位于 `~/.openclaw/workspace/skills/`）

| Skill | 触发方式 | 用途 |
|---|---|---|
| obsidian-summary | `/obsidian_summary` | 文档摘要 → vault 五阶段工作流 |
| obsidian-search | `/obsidian_search` | vault 搜索 + 知识问答 |
| obsidian-research | `/obsidian_research` | 深度研究 + 头脑风暴 |
| obsidian-link | `/obsidian_link` | 笔记关系分析 + wikilink 建议 |
| web-clipper | 自动（topic 3 裸 URL）| 抓取网页全文 + 图片 → Clippings/ |
| skill-creator | 手动 | 创建/打包新 skill |
| todo | `/todo` | TODO 管理 |

## 环境

- Node（x86_64）：`/usr/local/Cellar/node/25.6.1/bin/node`
- Brave Search：已配置
- Gateway restart：用 `gateway(action=restart)` 工具直接重启；CLI 方式（`openclaw gateway restart`）作为备用
- clawhub：`/usr/local/Cellar/node/25.6.1/bin/node $(which clawhub)`
- 当前默认模型：`anthropic-custom/claude-sonnet-4-6`

## 重要教训

- `trash` > `rm`，但 Google Drive 文件用 `rm` 更可靠
- `openclaw configure` wizard 有时不能正确保存配置，用 `gateway config.patch` 更可靠
- clawhub install 默认装到 `~/.openclaw/workspace/skills/`

## Cron Jobs

| Job | ID | 时间 | 用途 |
|---|---|---|---|
| weekly-self-improvement | 8bf068d4 | 每周一 09:00 (Asia/Shanghai) | 自我分析 → 提案给用户审核 |
| daily-todo-reminder | adf8f141 | 每天 10:00 (Asia/Shanghai) | 读取 TODO.md 发提醒到 topic:1 |
| healthcheck:security-audit | b86dcc27 | 每周三 09:00 (Asia/Shanghai) | 安全审计 + 版本检查 → topic:7 |

## Telegram Cron Delivery 格式

- 发送到指定 topic：`-1003885917198:topic:1`（General）或 `-1003885917198:topic:7`（Tools）
- 格式：`delivery.channel = "telegram"`, `delivery.to = "<chatId>:topic:<topicId>"`
