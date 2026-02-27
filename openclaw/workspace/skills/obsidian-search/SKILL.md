---
name: obsidian-search
description: Search Obsidian vault and answer questions using vault knowledge. Triggers on /obsidian_search or /search command, vault search requests, or when user asks questions that might be answered by their existing notes.
user-invocable: true
---

# Obsidian Vault Search

Search and answer from the Obsidian vault at `~/Documents/second-brain`.

## 强制规则

**每次调用必须执行 `vault_search.py`**，禁止直接用已有上下文或记忆回答，即使问题与之前相同。

## Workflow

1. **Query 改写**：将用户的自然语言问题改写为搜索关键词，规则：
   - 去掉口语化包装（"笔记里有...么"、"有没有...的信息"、"帮我查一下"等）
   - 保留核心实词和专有名词
   - 补充同义词/英文对照（如 "写入行数" → 加上 "Rows/s TPS"）
   - 示例："笔记里有 lindorm 每秒写入行数信息么？" → "lindorm 写入行数 Rows/s TPS 每秒写入"

2. **语义搜索**（用改写后的 query）：
   ```bash
   python3 ~/.openclaw/workspace/scripts/vault_search.py "<query>" --top 5
   ```
   - 若索引不存在或报错，提示用户先运行 `/obsidian_index` 建立索引
   - 降级方案：`grep -r -l -i "<terms>" ~/Documents/second-brain/ --include="*.md"`（排除 `.obsidian/` 和 `.claude/`）

3. **综合回答**：基于搜索结果回答，引用笔记用 `[[wikilinks]]`

4. **发送图片**：如果回答的信息来源于图片分析结果，必须同时发送原始图片：
   - `cp` 图片到 `~/.openclaw/workspace/.vault-staging/<name>.png`（文件名空格替换为下划线）
   - 用 message 工具发送，**`threadId` 从 `conversation_label` 中提取**（如 `topic:7` → `threadId=7`，无 topic 则不传）

## Command

```
/obsidian_search <query>
```

If no query provided, ask what to search for.
