# OpenClaw 使用最佳实践

*基于实际使用经验和官方文档整理*

---

## 🎯 核心原则

### 1. **文件即记忆**
- **心智模型：** AI 每次会话都是新鲜的，文件是唯一的持久化方式
- **不要依赖"记住"：** 永远写到文件里，不要指望 AI 记住上次说的话
- **结构化存储：** 
  - `MEMORY.md` - 长期重要记忆（仅主会话加载）
  - `memory/YYYY-MM-DD.md` - 每日工作日志
  - `TODO.md` - 待办事项清单
  - `RULES.md` - 你的工作规则和偏好

### 2. **自动化优先**
- **Heartbeat：** 用于批量周期性检查（邮件、日历、天气等）
- **Cron：** 用于精确时间触发（提醒、报告、备份）
- **规则：** 优先批量任务到 heartbeat，精确任务用 cron

### 3. **安全第一**
- **凭证保护：** `chmod 700 ~/.openclaw/credentials`
- **定期审计：** 每周自动安全扫描
- **最小权限：** 不需要的权限不开启
- **备份：** 定期备份配置和数据

---

## 📁 工作区组织

### 推荐目录结构
```
~/.openclaw/workspace/
├── AGENTS.md          # 你的行为准则（启动时读取）
├── SOUL.md            # AI 的人格和原则
├── USER.md            # 关于你的信息
├── IDENTITY.md        # AI 的身份定义
├── TOOLS.md           # 本地工具和环境特定配置
├── RULES.md           # 你的工作规则（必须遵守）
├── TODO.md            # 待办事项
├── MEMORY.md          # 长期记忆（敏感，仅主会话）
├── HEARTBEAT.md       # 周期性检查任务清单
└── memory/            # 每日日志
    ├── 2026-02-07.md
    ├── 2026-02-06.md
    └── ...
```

### 文件使用指南

**AGENTS.md** - 启动时自动读取
- 定义 AI 的行为模式
- 何时主动、何时沉默
- 群聊参与规则
- 安全边界

**SOUL.md** - AI 的人格
- 核心价值观
- 沟通风格
- 决策原则

**RULES.md** - 强制遵守的规则
- GitHub 操作规范
- 网页抓取策略
- TODO 管理规则
- 每次添加新规则时展示所有规则并提示合并

**TODO.md** - 任务管理
- 保持简洁，只记录任务和链接
- 新任务自动调研并添加总结
- 保留原始链接（可能需要查看完整内容）

**MEMORY.md** - 长期记忆（敏感）
- **仅在主会话加载**（不要在群聊或共享会话中加载）
- 记录重要决策、经验教训、偏好
- 定期审查和更新（通过 heartbeat）

**HEARTBEAT.md** - 周期性任务
- 空文件 = 跳过 heartbeat（节省 API 调用）
- 添加检查清单时批量处理（邮件+日历+通知）
- 适合时间不敏感的周期性任务

---

## ⏰ 自动化策略

### Heartbeat vs Cron 选择指南

| 场景 | 推荐方案 | 原因 |
|------|---------|------|
| 每天检查邮件、日历 | Heartbeat | 批量处理，节省 API 调用 |
| 每周一 9:00 安全审计 | Cron | 精确时间，独立会话 |
| "20分钟后提醒我" | Cron | 一次性任务 |
| 定期整理笔记 | Heartbeat | 可以访问主会话上下文 |
| 生成每日报告 | Cron | 定时输出，独立任务 |

### Heartbeat 最佳实践
```markdown
# HEARTBEAT.md 示例

## 每日检查（早上 9:00-10:00 之间）
- [ ] 检查未读邮件（重要的才提醒）
- [ ] 查看今天和明天的日历事件
- [ ] 天气预报（如果有户外计划）

## 每周检查（周一）
- [ ] 审查并更新 MEMORY.md
- [ ] 清理过期的 TODO 项

## 状态跟踪
最后检查时间记录在 memory/heartbeat-state.json
```

### Cron 最佳实践
```bash
# 安全审计 - 每周一 9:00
openclaw cron add --name "security-audit" \
  --schedule "0 9 * * 1" \
  --isolated \
  --message "运行安全审计，有问题才提醒"

# 待办提醒 - 每天 10:00
openclaw cron add --name "todo-reminder" \
  --schedule "0 10 * * *" \
  --isolated \
  --message "读取 TODO.md，有未完成项才提醒"

# 版本检查 - 每天 9:00
openclaw cron add --name "update-check" \
  --schedule "0 9 * * *" \
  --isolated \
  --message "检查更新，有新版本才提醒"
```

**关键原则：**
- 使用 `isolated` 会话（不污染主会话历史）
- 只在有重要信息时才发送通知
- 无事发生时回复 `HEARTBEAT_OK`（OpenClaw 会丢弃）

---

## 🔒 安全最佳实践

### 定期审计
```bash
# 每周自动运行
openclaw security audit --deep

# 修复建议的问题
openclaw security audit --fix
```

### 凭证管理
- **存储位置：** `~/.openclaw/credentials/`
- **权限：** `chmod 700` （仅所有者可读写）
- **敏感数据：** API keys, tokens, 密码
- **版本控制：** 不要提交到 git

### 更新管理
```bash
# 检查更新
openclaw update status

# 手动更新
openclaw update --yes

# 切换到 beta 频道（如果需要最新功能）
openclaw update --channel beta
```

---

## 📝 工作流示例

### 场景 1：任务管理
```markdown
用户："帮我研究一下 X 功能"

AI 操作：
1. 在 TODO.md 添加任务
2. 自动搜索相关文档/文章
3. 总结要点添加到任务下方
4. 保留原始链接
```

### 场景 2：定期提醒
```markdown
用户："每天 10 点提醒我待办事项"

AI 操作：
1. 创建 cron 任务（isolated 会话）
2. 任务读取 TODO.md
3. 有未完成项 → Telegram 提醒
4. 全部完成 → HEARTBEAT_OK（静默）
```

### 场景 3：信息收集
```markdown
用户："帮我监控 GitHub 仓库的 issue"

AI 操作：
1. 使用 `gh` CLI（不用 web_fetch）
2. 检查用户是否已参与（作者或评论者）
3. 已参与 → 有邮件通知，不额外订阅
4. 未参与 → 提示用户手动订阅
```

---

## 🎨 个性化配置

### 定义你的 AI 助手
**SOUL.md：**
- 你希望它是什么性格？（专业/随和/幽默）
- 如何处理不确定的情况？（保守/积极）
- 群聊中的参与度？（活跃/安静/按需）

**IDENTITY.md：**
- 名字、emoji、头像
- 助手的"物种"定义（AI/机器人/精灵？）

### 工作规则
**RULES.md：**
- GitHub 操作习惯
- 文件组织偏好
- 通知频率控制
- 隐私边界

---

## 🚀 高级技巧

### 1. 使用 Skills
```bash
# 查看可用技能
ls /usr/local/lib/node_modules/openclaw/skills/

# 常用技能
- github: 用 gh CLI 管理仓库
- weather: 天气查询
- tmux: 远程控制终端
- healthcheck: 安全审计和系统加固
```

### 2. 集成外部工具
- **Obsidian：** 将 workspace 放在 vault 内
- **Gmail：** 使用 Pub/Sub webhook（实时推送）
- **Calendar：** Heartbeat 定期检查日程

### 3. 多会话管理
```bash
# 列出所有会话
openclaw sessions list

# 向其他会话发消息
openclaw sessions send --label "background-task" --message "状态如何？"

# 启动独立子任务
openclaw sessions spawn --task "研究 X 技术" --cleanup delete
```

### 4. 模型切换
```bash
# 查看当前模型
openclaw models status

# 添加其他模型
openclaw models add anthropic --apiKey YOUR_KEY

# 临时使用更强模型
/model opus-4  # 在对话中切换
```

---

## 🛠️ 故障排查

### 常见问题

**1. Cron 任务没触发**
```bash
# 检查任务状态
openclaw cron list

# 查看执行历史
openclaw cron runs --job-id <id>

# 查看日志
openclaw logs --follow
```

**2. API 认证失败**
```bash
# 检查凭证
openclaw models status

# 测试连接
curl -X POST <api-endpoint> -H "Authorization: Bearer <key>"
```

**3. 会话丢失**
- 检查 `~/.openclaw/agents/main/sessions/`
- 主会话持久化，isolated 会话可能被清理

### 调试技巧
```bash
# 实时日志
openclaw logs --follow

# 详细状态
openclaw status --deep

# 安全审计
openclaw security audit --deep
```

---

## 📊 性能优化

### 减少 Token 消耗
1. **HEARTBEAT.md 保持精简**（或留空跳过）
2. **Cron 任务用 isolated 会话**（不污染主上下文）
3. **定期清理旧的 daily notes**（保留最近 1-2 周）
4. **MEMORY.md 定期精简**（去掉过时信息）

### 提升响应速度
1. **本地缓存：** 使用文件存储常用信息
2. **批量操作：** 一次 heartbeat 处理多个检查
3. **异步任务：** 用 sessions_spawn 处理长任务

---

## 🎯 总结清单

**每日：**
- [ ] 查看 TODO 提醒（10:00 自动）
- [ ] 更新 `memory/YYYY-MM-DD.md`（记录重要事件）

**每周：**
- [ ] 审查 MEMORY.md（整理长期记忆）
- [ ] 检查安全审计结果（周一 9:00 自动）
- [ ] 清理完成的 TODO 项

**每月：**
- [ ] 备份 `~/.openclaw/` 目录
- [ ] 审查 cron 任务是否还需要
- [ ] 更新 RULES.md（新的工作习惯）

**按需：**
- [ ] 模型失效时更换 API key
- [ ] OpenClaw 更新时查看 changelog
- [ ] 新功能发布时更新最佳实践

---

## 📚 参考资源

- **官方文档：** https://docs.openclaw.ai
- **技能仓库：** https://github.com/openclaw/skills
- **社区：** https://discord.com/invite/clawd
- **技能市场：** https://clawhub.com

---

*这份指南会随着你的使用不断演进。遇到新的最佳实践时，随时更新这个文件。*
