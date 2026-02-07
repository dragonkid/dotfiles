# TODO 列表

## 待阅读文章

- [ ] [Claude Code: Longform Guide](https://x.com/affaanmustafa/status/2014040193557471352)
- [ ] [Claude Code: Shorthand Guide](https://x.com/affaanmustafa/status/2012378465664745795)

## 待办事项

- [x] openclaw 迁移到性能更好的电脑上

- [x] 查看 Claude Code insight
  - 功能: /insights 命令生成关于 Claude Code 使用模式的综合 HTML 报告
  - 输出: ~/.claude/usage-data/report.html 交互式报告
  - 分析内容:
    - 项目领域（你在做什么）
    - 交互风格（你如何使用 Claude）
    - 工作流效果（什么有效）
    - 摩擦点（哪里有问题）
    - 改进建议（CLAUDE.md 添加、功能尝试）
    - 未来机会（更高级模型能做什么）
  - 技术细节:
    - 使用 Haiku 模型分析
    - Facets 缓存在 `~/.claude/usage-data/facets/`（加速后续运行）
    - 每次最多分析 50 个新会话
    - 超过 30k 字符的 transcript 会被分块总结
  - 参考: [Deep Dive: How Claude Code's /insights Command Works](https://www.zolkos.com/2026/02/04/deep-dive-how-claude-codes-insights-command-works.html)

- [ ] 研究 Claude Code agent teams 功能
  - 功能: 多个 Claude Code 实例协同工作，一个作为 lead 协调，其他独立执行任务
  - 启用: 设置 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`（实验性功能）
  - 使用场景:
    - 研究和审查：多个角度同时调查
    - 新模块/功能：各自独立负责不同部分
    - 调试：并行测试不同假设
    - 跨层协调：前端、后端、测试分别处理
  - 与 subagents 区别:
    | Subagents | Agent Teams |
    |-----------|-------------|
    | 回报给主 agent | 互相直接通信 |
    | 共享上下文 | 独立上下文窗口 |
    | 适合专注任务 | 适合需要协作的复杂工作 |
    | Token 成本更低 | Token 成本更高 |
  - 显示模式:
    - In-process: 所有 teammates 在主终端内，Shift+Up/Down 切换
    - Split panes: 每个 teammate 独立面板（需要 tmux 或 iTerm2）
  - 当前限制（实验性）:
    - In-process teammates 不支持 session resumption
    - 一个 lead 只能管理一个 team
    - 不支持嵌套 teams
    - 分屏面板需要 tmux/iTerm2
  - 文档: [Agent Teams - Claude Code Docs](https://code.claude.com/docs/en/agent-teams)

- [ ] 研究用 openclaw 或 claude code 管理 obsidian 文档库
  - 方案 1: OpenClaw + Obsidian 集成
    - 将 workspace 放在 Obsidian vault 内: ~/obsidian-vault/openclaw
    - 用 TOOLS.md 描述 vault 结构，让 AI 知道文件位置
    - 用 heartbeat 自动抓取外部数据（如 Oura、Gmail）写入 daily notes
    - 已有技能: obsidian-daily (openclaw/skills 仓库), obsidian-cli 集成
    - 参考: [OpenClaw: the missing piece for Obsidian's second brain](https://notesbylex.com/openclaw-the-missing-piece-for-obsidians-second-brain)
  - 方案 2: Claude Code 编辑 Obsidian markdown
    - 直接用 Claude Code 批量重构/搜索 vault
    - 适合大规模跨文件修改
  - 建议: 混合使用 - OpenClaw 日常自动化 + Claude Code 大规模重构

- [ ] 添加 openclaw 监控 gmail 邮箱
  - 方案: OpenClaw 原生支持 Gmail Pub/Sub webhook 集成
  - 推荐命令: openclaw webhooks gmail run (自动启动 + 续期 watch)
  - 前置条件:
    - gcloud SDK + gogcli (gogcli.sh) + Tailscale
    - GCP 项目: 启用 gmail & pubsub API，创建 topic gog-gmail-watch
  - 配置: hooks.enabled: true, hooks.presets: ["gmail"]
  - 优势: 实时推送（而非轮询），低延迟，按需触发 agent
  - 文档: https://docs.openclaw.ai/automation/gmail-pubsub

- [ ] 探索 Telegram Topic 多会话功能
  - **功能：** Telegram 论坛主题（Topics）支持独立会话隔离
  - **会话键格式：** `agent:<agentId>:telegram:group:<groupId>:topic:<topicId>`
    - 例如：`agent:main:telegram:group:-1001234567890:topic:42`
  - **存储位置：** 
    - 会话记录：`~/.openclaw/agents/<agentId>/sessions/<SessionId>-topic-<threadId>.jsonl`
    - 每个 topic 拥有独立的上下文和历史
  - **使用场景：**
    - 在一个 Telegram 群组中创建多个话题（Topics）
    - 每个话题与 AI 进行独立对话（互不干扰）
    - 适合按项目/主题分类讨论
  - **配置：**
    - 需要 Telegram 超级群组（Supergroup）启用论坛模式
    - OpenClaw 自动识别 topic ID 并隔离会话
  - **重置策略：**
    - 可通过 `session.resetByType.thread` 单独配置 topic 的重置规则
    - 支持每日重置、空闲重置等策略
  - **CLI 支持：**
    - `message` 工具支持 `--thread-id` 参数发送到指定 topic
  - **优势：**
    - 上下文隔离：不同 topic 不会混淆上下文
    - 组织性强：按主题分类管理对话
    - 灵活配置：每个 topic 可以有不同的会话策略
  - **参考文档：**
    - `/usr/local/lib/node_modules/openclaw/docs/zh-CN/concepts/channel-routing.md`
    - `/usr/local/lib/node_modules/openclaw/docs/zh-CN/concepts/session.md`
    - `/usr/local/lib/node_modules/openclaw/docs/cli/message.md`

- [ ] 测试 code.newcli.com 支持的所有模型列表
  - **当前状态：** 只确认 `claude-sonnet-4-5-20250929` 可用
  - **已测试不支持：**
    - Opus 4.6: `claude-opus-4.6`, `claude-opus-4-20250514`
    - Opus 4.5: `claude-opus-4.5`, `claude-opus-4-5-20241022`
  - **测试方法：**
    - 端点：`https://code.newcli.com/claude/v1/messages`
    - 模型列表接口被 Cloudflare 保护，无法直接访问
    - 需要逐个模型名称尝试
  - **待测试模型：**
    - Sonnet 3.5/3.7 系列
    - Haiku 系列
    - 其他 Sonnet 4.x 版本
  - **联系供应商：** 询问完整的支持模型列表和文档
