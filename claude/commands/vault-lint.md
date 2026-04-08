---
name: vault-lint
description: "Vault 健康检查：扫描 orphan 笔记、过期 uncertain、孤立 source、MOC gap 与 Backlog 不一致、断链等问题。当用户说 'vault lint'、'检查 vault'、'vault 健康'、'有哪些笔记需要清理'、'vault 有什么问题' 时触发。"
---

# /vault-lint — Vault 健康检查

灵感来源：Karpathy LLM Wiki 的 Lint 操作——定期检查知识库的一致性、完整性和健康度。

Vault 像代码库一样会积累技术债：orphan 笔记没人引用、uncertain 知识长期不晋升、MOC 标记了 gap 但 Backlog 没有对应计划。Lint 的目的是暴露这些问题，让用户决定如何处理。

## 检查项

按严重程度排序，并行执行所有检查。

### 1. 断链（Broken Links）

扫描全 vault `[[wikilink]]`，检查目标文件是否存在。断链说明引用了不存在的笔记（拼写错误或被删除）。

方法：用 Grep 提取所有 `[[...]]`，去重后用 Glob 检查文件是否存在。如果 vault 超过 300 个笔记，只扫描 `30-Notes/` 和 `40-Maps/`。

### 2. Orphan 笔记（未被任何 MOC 引用）

扫描 `30-Notes/` 下所有 PN-/HYP-/ENT-/CMP- 文件，检查 `40-Maps/` 中是否有文件通过 `[[filename]]` 引用了它。

未被 MOC 引用的笔记是孤岛——存在但不可通过 MOC 导航发现，违反 Zettelkasten "每个笔记至少属于一个上下文"的原则。

修复方向：基于笔记的 tags 和 `up` 字段推荐最合适的 MOC，或建议创建新 MOC。

### 3. 孤立 Source（未被任何 PN/ENT/CMP 引用）

扫描 `20-Sources/SRC-*.md`，检查 `30-Notes/` 中是否有文件引用了它。

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

## 执行流程

1. **并行扫描**：用 Bash + Grep 并行执行检查项 1-5（各项独立），检查项 6 随机抽样
2. **汇总报告**：输出结构化报告到对话
3. **用 AskUserQuestion 让用户选择后续动作**

## 报告格式

```markdown
# Vault Lint Report — {date}

## Summary
| 检查项 | 数量 | 状态 |
|--------|------|------|
| 断链 | X | {ok / warning} |
| Orphan 笔记 | X | {ok / warning} |
| 孤立 Source | X | {ok / warning} |
| 过期 Uncertain | X | {ok / warning} |
| 未计划的 MOC Gap | X | {ok / warning} |
| Frontmatter 不完整 | X/10 | {ok / warning} |

## 详情

### Orphan 笔记
| 笔记 | Tags | 建议 MOC |
|------|------|----------|

### 孤立 Source
| Source | 建议 |
|--------|------|

### 过期 Uncertain (>30 天)
| 笔记 | 创建日期 | 建议 |
|------|----------|------|

### 未计划的 MOC Gap
| MOC | Gap 描述 | 建议 |
|-----|----------|------|

### 断链
| 文件 | 断链目标 |
|------|----------|

### Frontmatter 不完整
| 笔记 | 缺失字段 |
|------|----------|
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
