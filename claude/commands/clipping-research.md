# /clipping-research — 六维深入理解框架

对指定的 clippings 进行深度阅读和调研，输出结构化理解到对话上下文。不写 vault，不做 decompose。

**定位**：三步流水线的第二步。
1. `obsidian-deep-research "处理 clippings"` → 聚簇扫描，用户选择一簇
2. **`/clipping-research <文件列表>`** → 六维深入理解（本 command）
3. `obsidian-deep-research "decompose 上面的内容"` → 从上下文 decompose

## 输入

`$ARGUMENTS` 为以下之一：
- 文件路径列表（空格分隔）：`Clippings/xxx.md Clippings/yyy.md`
- 主题关键词：`harness engineering`（自动搜索未处理的相关 clippings）

如果是关键词，先用 Grep 在 `Clippings/` 和 `10-Inbox/Clippings/` 中搜索匹配文件，展示候选列表让用户确认。

## 执行流程

### Step 1: 深入理解（Comprehend）

逐篇读取所有 clippings，提取：

| 文件 | 主题 | 关键声明 | 引用的外部来源 |
|------|------|----------|----------------|

然后追溯 top 3-5 个外部来源：
- 用 `mcp__exa__web_search_exa` 搜索原始来源
- 用 `defuddle` 或 `WebFetch` 读取原文
- 对比 clipping 与原文的差异：是否过度简化？遗漏了哪些关键 nuance？

输出：核心概念图谱 + 已验证/未验证的声明清单。

### Step 2: 具体案例理解（Ground）

用行业实际案例辅助理解抽象概念：

1. **优先使用 clipping 中提到的案例**（如 OpenAI Codex、Stripe Minions）——搜索这些案例的一手资料
2. **补充搜索**同领域其他团队/项目的实践案例（`mcp__exa__web_search_exa`）
3. 对每个案例提取：背景、做法、结果、可复用的模式

案例的价值在于把抽象概念锚定到具体实践，帮助判断 clipping 中的观点是否有广泛适用性。

### Step 3: 最佳实践查找（Validate）

查找行业/社区是否已形成共识：

- `mcp__exa__web_search_exa` 搜索 "best practices" + 主题关键词
- 可选：`/last30days` 查社区信号（X、HN、Reddit 近期讨论）
- 查找相关 GitHub 项目/框架

输出三类信号：
- **共识点** — 多个独立来源验证的观点
- **争议点** — 来源之间有分歧
- **空白点** — 无人讨论（可能是 clipping 独创或过于小众）

### Step 4: 领域定位（Contextualize）

在更大的知识领域中定位这个话题：

- **前置概念**：这个话题建立在哪些已有概念之上？
- **相邻领域**：和哪些看似不同但有关联的领域有交叉？
- **演变趋势**：之前的范式是什么？当前处于什么阶段？可能演变成什么？
- **vault 关联**：用 `obsidian search` 检查 vault 中是否已有相关笔记，标注重叠和增量

这一步帮助理解 clipping 的观点在领域演进中的位置，避免孤立理解。

### Step 5: 反面审视（Challenge）

主动寻找反对观点和局限性，避免确认偏差：

- 谁在反对这个观点？理由是什么？
- 在什么条件下这个观点不成立？
- 文章中是否有逻辑跳跃或未说明的假设？
- 数据是否 cherry-picked？是否存在幸存者偏差？

搜索反对观点时，用 `mcp__exa__web_search_exa` 搜索 "criticism" / "limitations" / "problems with" + 主题关键词。

### Step 6: 关键数据校验（Quantify）

提取并验证文章中的量化数据：

| 数据点 | 来源 | 验证状态 |
|--------|------|----------|
| 同一模型换 harness，42% → 78% | Nate B Jones | ✅ 已追溯到原始来源 |
| LangChain 52.8% → 66.5% | LangChain blog | ⚠️ 仅在 clipping 中出现 |
| ... | ... | ❌ 与原始来源不一致 |

验证状态：
- ✅ 已追溯到原始来源并确认
- ⚠️ 仅在 clipping 中出现，未找到原始来源
- ❌ 与原始来源数据不一致

检查数据之间是否自洽。

## 输出格式

所有内容输出到对话上下文，使用以下结构：

```
## 理解：{主题}

### 核心概念（Comprehend）
{概念图谱、原文对比发现}

### 行业案例（Ground）
{案例分析，每个案例：背景→做法→结果→模式}

### 最佳实践与共识（Validate）
{共识点 / 争议点 / 空白点}

### 领域定位与演变（Contextualize）
{前置概念 / 相邻领域 / 演变趋势 / vault 关联}

### 反对观点与局限（Challenge）
{反对声音 / 适用边界 / 逻辑检验}

### 关键数据（Quantify）
{数据表 + 验证状态}

### 知识 gap
{本次调研未能回答的问题，建议后续方向}
```

## 关键约束

- **不写 vault** — 所有内容留在对话上下文，供后续 decompose 使用
- **不提出 decompose 方案** — 那是 obsidian-deep-research 的职责
- **只负责"理解"，不负责"组织"** — 理解层和组织层分离是这个流水线的核心设计
- 每个 step 完成后简要报告进度，全部完成后输出完整结构化理解
