---
name: obsidian-vault-lint
description: "Vault 健康检查：扫描 orphan 笔记、过期 uncertain、孤立 source、MOC gap 与 Backlog 不一致、断链等问题。当用户说 'vault lint'、'检查 vault'、'vault 健康'、'有哪些笔记需要清理'、'vault 有什么问题' 时触发。"
---

# /obsidian-vault-lint — Vault 健康检查

灵感来源：Karpathy LLM Wiki 的 Lint 操作——定期检查知识库的一致性、完整性和健康度。

Vault 像代码库一样会积累技术债：orphan 笔记没人引用、uncertain 知识长期不晋升、MOC 标记了 gap 但 Backlog 没有对应计划。Lint 的目的是暴露这些问题，让用户决定如何处理。

## 检查项

按严重程度排序，并行执行所有检查。

### 1. 断链（Broken Links）

扫描 `30-Notes/` 和 `40-Maps/` 中的 `[[wikilink]]`，检查目标是否存在。Obsidian 按文件名全局搜索解析 wikilink，所以只有**目标文件名在整个 vault 中不存在**才算断链。

**分两类报告**（严重程度不同）：

**1a. 笔记断链**（高优先级）：目标无扩展名、非 Archive 路径。说明引用了不存在的笔记——拼写错误、笔记被删除、或计划创建但未完成（如 `ENT-claude-code`）。
- 排除 `70-Archive/` 开头的引用（归档笔记断链是预期行为）

**1b. 附件断链**（中优先级）：目标有扩展名（`.png`, `.jpg`, `.pdf`, `.csv` 等）或带路径前缀（`Attachments/...`, `smartflow-*/...`）。说明引用了不存在的图片/PDF——可能是文件未下载、路径变更、或 clipping 迁移时图片未同步。
- 用 Glob 检查文件名是否存在于 vault 任意位置（模拟 Obsidian 的全局搜索行为）
- 如果文件名存在但路径不匹配，不算断链（Obsidian 能解析）

**方法**：用 Grep 提取所有 `[[target]]` 和 `[[target|alias]]` 中的 target 部分，按扩展名分类后分别检查。

### 2. Orphan 笔记（未被任何 MOC 引用）

扫描 `30-Notes/` 下所有 PN-/HYP-/ENT-/CMP- 文件，检查 `40-Maps/` 中是否有文件通过 `[[filename]]` 引用了它。

未被 MOC 引用的笔记是孤岛——存在但不可通过 MOC 导航发现，违反 Zettelkasten "每个笔记至少属于一个上下文"的原则。

修复方向：基于笔记的 tags 和 `up` 字段推荐最合适的 MOC，或建议创建新 MOC。

### 3. 孤立 Source（未被任何 PN/ENT/CMP 引用）

扫描 `20-Sources/SRC-*.md`（包括子目录 Articles/ 和 Reports/），检查 `30-Notes/` 中是否有文件引用了它。

未被引用的 SRC 说明 source 被记录但知识没有被提取——decompose 不彻底或 source 价值不高。

### 4. 过期 Uncertain（confidence/uncertain 超过 30 天）

扫描带 `confidence/uncertain` tag 的笔记，对比 `created` 日期与今天。超过 30 天仍为 uncertain 说明知识点需要验证或应该晋升/归档。

修复方向：
- 有明确验证方法 → 建议加入 Backlog
- 主观判断无法验证 → 建议晋升为 `likely`
- 已被推翻 → 建议归档到 `70-Archive/`

### 5. MOC Gap 与 Backlog 不一致

扫描 `40-Maps/` 中所有 `⚠️ **Gap**:` 标记，检查 `00-Dashboard/Backlog.md` 中是否有对应待办项。

Gap 标记了知识空白，但 Backlog 没有对应计划就永远不会被填补。

### 6. Frontmatter 完整性（抽样）

随机抽 10 个 `30-Notes/` 笔记检查 frontmatter 是否包含：`title`, `tags`, `created`, `up`。缺失字段降低可搜索性。

**macOS 兼容性**：不使用 `shuf`（macOS 无此命令），改用 `awk 'BEGIN{srand()} {if(rand()<0.2) print}'` 或 `$RANDOM` 做随机抽样。

### 7. 不规范目录

Zettelkasten 编号目录有严格的子目录规范。任何不在规范中的目录都是潜在问题——可能是手动创建的临时目录、测试目录或误操作。

规范目录白名单（来源：obsidian-deep-research `references/vault-conventions.md`）：
- `00-Dashboard/`
- `10-Inbox/`, `10-Inbox/Fleeting/`, `10-Inbox/Clippings/`
- `20-Sources/`, `20-Sources/Articles/`, `20-Sources/Reports/`
- `30-Notes/`, `30-Notes/Permanent/`, `30-Notes/Entity/`, `30-Notes/Comparison/`, `30-Notes/Hypothesis/`
- `40-Maps/`
- `50-Research-Log/`
- `60-Outputs/`
- `70-Archive/`

方法：用 `find` 列出编号目录（`00-` 到 `70-`）下的所有一级和二级子目录，与白名单做差集。

修复方向：文件应移到正确目录，然后删除空目录。

## 执行流程

1. **并行扫描**：用 Bash + Grep 并行执行检查项 1-5 和 7（各项独立），检查项 6 随机抽样
2. **汇总报告**：输出结构化报告到对话
3. **用 AskUserQuestion 让用户选择后续动作**

## 报告格式

```markdown
# Vault Lint Report — {date}

## Summary
| 检查项 | 数量 | 状态 |
|--------|------|------|
| 笔记断链 | X | {ok / warning} |
| 附件断链 | X | {ok / warning} |
| Orphan 笔记 | X | {ok / warning} |
| 孤立 Source | X | {ok / warning} |
| 过期 Uncertain | X | {ok / warning} |
| 未计划的 MOC Gap | X | {ok / warning} |
| Frontmatter 不完整 | X/10 | {ok / warning} |
| 不规范目录 | X | {ok / warning} |

## 详情

### 笔记断链
| 断链目标 | 引用来源（示例） |
|----------|-----------------|

### 附件断链
| 断链文件 | 引用来源（示例） | 建议 |
|----------|-----------------|------|

### Orphan 笔记
| 笔记 | 建议 MOC |
|------|----------|

### 孤立 Source
| Source | 建议 |
|--------|------|

### 过期 Uncertain (>30 天)
| 笔记 | 创建日期 | 天数 | 建议 |
|------|----------|------|------|

### 未计划的 MOC Gap
| MOC | Gap 描述 |
|-----|----------|

### Frontmatter 不完整
| 笔记 | 缺失字段 |
|------|----------|

### 不规范目录
| 目录 | 建议 |
|------|------|
```

## 后续动作

报告输出后，用 AskUserQuestion 提供选项：
- **批量修复 orphan**：自动把 orphan 笔记添加到推荐的 MOC 的 Unsorted section
- **把问题加入 Backlog**：在 Backlog.md 添加对应待办
- **只看报告**：不做任何修改

## 约束

- **只读分析**——不自动修改任何笔记，所有修改需要用户确认
- 每个检查项独立执行，某项失败不影响其他项
- Vault 路径硬编码为 Second Brain 工作目录（当前 cwd）
- 使用 Glob/Grep 工具处理文件扫描，Bash 仅用于 find/date 等系统命令——避免中文文件名 shell 展开问题
