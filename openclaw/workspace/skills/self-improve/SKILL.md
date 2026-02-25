---
name: self-improve
description: 手动触发自我改进与记忆维护。分析近期 memory 文件，维护工作区文件，提出改进提案。触发方式：/self_improve 或用户说"自我改进"、"self improve"。
command-dispatch: tool
user-invocable: true
---

# Self-Improvement Skill

手动触发的自我改进 + 记忆维护流程。

## 执行流程

### Phase 0: 自动清理（静默执行，无需提案）

1. 删除超过 7 天的 `~/.openclaw/workspace/memory/YYYY-MM-DD.md` 文件
2. 这一步直接执行，不需要用户确认

### Phase 1: 分析 & 生成提案

#### 1.1 Memory 分析
1. 读取最近 7 天的 `~/.openclaw/workspace/memory/YYYY-MM-DD.md`
2. 提取：工具/环境变更、行为教训、过时信息、问题模式

#### 1.2 配置一致性检查
1. 读取 `openclaw.json`，对比 TOOLS.md 中的关键信息（模型名、provider、路径等）
2. 发现不一致时生成维护类提案

#### 1.3 最佳实践对照
1. 参考 OpenClaw 文档（`/usr/local/lib/node_modules/openclaw/docs`）
2. 对比当前配置和工作流，识别可改进之处

#### 1.4 输出提案
将所有发现整理为提案列表，回复给用户。每条提案格式：

```
📌 提案 N: [标题]
- 类型：维护 / 改进 / 清理
- 目标文件：[文件路径]
- 问题：[发现了什么]
- 建议：[具体改什么]
- 理由：[为什么这样改更好]
```

提案末尾附 inline buttons 让用户选择：
- 全部执行
- 逐条确认
- 跳过

### Phase 2: 执行修改

用户确认后，按提案逐条执行文件修改。每条修改完成后简要说明改了什么。

## 提案过滤原则

生成提案前先过滤，避免无意义提案：

- **不重复记录** — 如果信息已在权威来源存在（如 openclaw.json 里的 provider/model 配置），不要提案在 TOOLS.md 中重复记录
- **不提案已知搁置项** — TODO 中长期未处理的条目，除非有新进展，不反复提醒
- **维护类可合并** — 多个事实性更新（路径、名称变更）合并为一条提案快速确认

## 规则

- Phase 0 自动执行，Phase 1-2 必须先提案后执行
- 如果没有发现需要改进的地方，直接说明即可
