---
name: skill-creator
description: Use when creating a new skill or updating an existing skill that extends agent capabilities with specialized workflows, tool integrations, or domain knowledge.
license: Complete terms in LICENSE.txt
---

# Skill Creator

## 结构

```
skill-name/
├── SKILL.md          # 必须
├── scripts/          # 可执行脚本（Python/Bash）
├── references/       # 参考文档（按需加载）
└── assets/           # 输出用文件（模板、图片等）
```

## 创建流程

1. **理解需求** — 明确具体使用场景和触发条件
2. **规划资源** — 确定需要哪些 scripts/references/assets
3. **初始化** — 运行 `init_skill.py`（新建时）
4. **编写内容** — 先写资源文件，再写 SKILL.md
5. **直接安装** — 放到 `~/.openclaw/workspace/skills/` 重启即可
6. **迭代优化** — 基于实际使用反馈改进

> 打包（`package_skill.py`）仅用于分发，本地使用不需要。
> 注意：打包脚本不允许 `user-invocable`、`command-dispatch` 等 OpenClaw 扩展字段，会报验证错误。

## Frontmatter 字段（OpenClaw）

```yaml
---
name: skill-name           # 必须，用连字符分隔
description: ...           # 必须，见下方规范
user-invocable: true       # 暴露为 slash command（默认 true）
command-dispatch: tool     # 直接派发到工具，需同时提供 command-tool
command-tool: <tool-name>  # command-dispatch: tool 时必填，否则注册被忽略
disable-model-invocation: true  # 从模型 prompt 中排除（仍可用户调用）
metadata: { "openclaw": { "requires": { "bins": ["rg"], "config": ["channels.discord"] } } }
---
```

**⚠️ 常见坑：** `command-dispatch: tool` 缺少 `command-tool` 时，OpenClaw 会静默忽略整个 dispatch，slash command 不会注册（日志报 `Ignoring dispatch`）。

## Description 编写规范

**核心原则：只描述触发条件，绝不总结工作流程。**

原因：description 含工作流摘要时，Claude 会直接按 description 行动，跳过读取 SKILL.md 正文。

```yaml
# ❌ 错误：包含工作流摘要
description: 创建 skill 时使用 - 初始化目录、编写 SKILL.md、打包分发

# ❌ 错误：太模糊
description: A guide for skills

# ✅ 正确：只描述触发条件
description: Use when creating or updating a skill that extends agent capabilities
```

**编写要点：**
- 以 `Use when...` 开头
- 包含具体触发场景、症状、工具名（便于 Claude 搜索匹配）
- 第三人称
- 尽量控制在 500 字符以内
- 不要总结 skill 的执行步骤

## Token 效率目标

| 类型 | 目标 |
|------|------|
| 频繁加载的 skill | < 200 词 |
| 一般 skill | < 500 词 |
| SKILL.md 总行数 | < 500 行 |

**技巧：**
- 大段参考文档移到 `references/` 按需加载
- 一个好例子胜过多个平庸例子
- 不要重复 Claude 已知的通用知识

## SKILL.md 正文结构建议

```markdown
# Skill Name

## 概述（1-2 句）

## 工作流程 / 步骤

## 关键参数 / 配置

## 常见错误
```

详细模式说明见 `references/design-patterns.md`。

## Discord Slash Command 注意事项

新增 skill 重启 gateway 后，Discord 客户端有缓存，新命令不会立即出现。
提醒用户按 `Cmd+R`（Mac）/ `Ctrl+R`（Windows/Linux）强制刷新。

## 反模式

- **叙事式写法** — "在某次会话中我们发现..." → 改为可复用的模式描述
- **多语言示例** — 同一模式写 5 种语言 → 选最相关的一种
- **总结工作流的 description** — 导致 Claude 跳过正文
- **冗余说明** — 不要解释 Claude 已知的内容
- **不必要的辅助文件** — 不要创建 README.md、CHANGELOG.md 等
