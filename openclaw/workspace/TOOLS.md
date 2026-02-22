# TOOLS.md - Local Notes

## Telegram Topics (AI 工作台 -1003885917198)

- topic:1 — General（日常对话、TODO 提醒）
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
- Gateway restart：允许直接执行，用 `gateway(action=restart)` 工具
- clawhub：`/usr/local/Cellar/node/25.6.1/bin/node $(which clawhub)`

## 重要教训

- `trash` > `rm`，但 Google Drive 文件用 `rm` 更可靠
- `openclaw configure` wizard 有时不能正确保存配置，用 `gateway config.patch` 更可靠
- clawhub install 默认装到 `~/.openclaw/workspace/skills/`

## Cron Jobs

| Job | ID | 时间 | 用途 |
|---|---|---|---|
| weekly-self-improvement | 8bf068d4 | 每周一 09:00 | 自我分析 → 提案给用户审核 |
| TODO reminder | adf8f141 | 每天早上 | 读取 TODO.md 发提醒 |
