# RULES.md - 工作规则

*这些是你明确要求我遵守的规则。*

---

## GitHub 规则 (2026-02-06)

1. **优先使用 `gh` 命令** - 所有 GitHub 相关操作优先使用 GitHub CLI
2. **永远不要订阅整个仓库** - 除非用户明确告知
3. **跟踪 issue 的方式** - 检查用户是否已参与（作者或已评论），如果是则默认有邮件通知，无需额外订阅
   - 如需订阅单个 issue，提示用户直接在网页上操作

### GitHub 账号
- **登录账号：** dragonkid
- **配置文件：** `~/.config/gh/hosts.yml`

---

## 浏览器与网页抓取规则 (2026-02-06)

1. **优先使用 web_fetch** - 简单页面优先用 web_fetch，不启动浏览器
2. **需要登录的网站** - web_fetch 失败时直接告知用户手动阅读，不尝试浏览器
3. **任务完成后必须关闭 tab** - 用 `browser(action=close, targetId=...)` 关闭，不关闭整个浏览器
4. **不要自动登录** - 需要登录的网站让用户手动登录，避免触发反爬虫

---

## Gateway 管理规则 (2026-02-07)

1. **可直接重启** - 用 `gateway(action=restart)` 工具，无需征得同意
2. **重启后主动通知** - 重启前创建延迟 60 秒的一次性 cron job 发送通知
3. **config 修改优先用 config.patch** - `openclaw configure` wizard 有时不能正确保存，用 `gateway(action=config.patch)` 更可靠

---

## 自我改进规则 (2026-02-08)

1. **理解偏差必须追根溯源** - 找到根本原因（SKILL.md 描述不清？规则缺失？上下文误判？），修复对应文件
2. **Skill 触发时必须先读 SKILL.md** - 收到 "Use the xxx skill" 时，必须先读取对应的 SKILL.md
3. **多个问题时提供选项** - 需要问超过一个问题时，用编号选项方便回答

---

## launchd 规则 (2026-02-25)

1. **创建 plist 必须记录** - 每次创建 launchd plist 后，立即更新 TOOLS.md 的 launchd Agents 表格，包含 Label、plist 路径、用途、频率、日志路径

---

## 安装规则 (2026-02-25)

1. **安装前必须征得同意** - 执行任何 `pip install`、`npm install`、`brew install` 等安装命令前，先说明要装什么、为什么，等用户确认后再执行

---

## 信息查询规则 (2026-02-23)

1. **回答问题前先搜索** - 回答任何问题前，先用 `mgrep search -w -a "<query>"` 获取最新信息，再开始回答；mgrep 不可用时降级到 web_search

---

## UI 交互规则 (2026-02-22)

1. **需要用户决策时必须用组件** - 凡是选择、确认、方案选择，用 `message` tool 的 `components` param 发送，不能只列文字等用户打字回复
2. **选择类型** - 固定动作（确认/跳过/继续等）用 buttons；动态数据列表（model/文件/provider 等）用 select menu
3. **Button 文字要简短** - 详细说明放消息正文，避免截断
4. **多问题合并** - 需要问多个问题时，合并成一条消息 + 一组 components，不连续追问
