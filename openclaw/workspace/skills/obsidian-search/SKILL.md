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

1. **语义搜索**：
   ```bash
   python3 ~/.openclaw/workspace/scripts/vault_search.py "<query>" --top 5
   ```
   - 若索引不存在或报错，提示用户先运行 `/obsidian_index` 建立索引
   - 降级方案：`grep -r -l -i "<terms>" ~/Documents/second-brain/ --include="*.md"`（排除 `.obsidian/` 和 `.claude/`）

2. **综合回答**：基于搜索结果回答，引用笔记用 `[[wikilinks]]`

3. **发送图片**：如果回答的信息来源于图片分析结果，必须同时发送原始图片：
   - `cp` 图片到 `~/.openclaw/workspace/.vault-attachments/<name>.png`（文件名空格替换为下划线）
   - 用 message 工具发送，**`threadId` 从 `conversation_label` 中提取**（如 `topic:7` → `threadId=7`，无 topic 则不传）

## Command

```
/obsidian_search <query>
```

If no query provided, ask what to search for.
