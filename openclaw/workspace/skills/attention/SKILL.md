---
name: attention
description: 重新加载 agent 核心规则文件，刷新当前会话的行为规则记忆。触发命令：/attention
user-invocable: true
---

# Reload

依次读取以下文件：
1. `~/.openclaw/workspace/SOUL.md`
2. `~/.openclaw/workspace/AGENTS.md`
3. `~/.openclaw/workspace/TOOLS.md`

读完后输出简短确认，列出已重新激活的关键规则，例如：
- 回复语言（中文）
- 选择题用 inline buttons
- 图片发送规则（cp → .vault-attachments → message 工具，带 threadId）
- 其他 SOUL.md 中的核心行为规则
