---
name: obsidian-search
description: Search Obsidian vault and answer questions using vault knowledge. Triggers on /search command, vault search requests, or when user asks questions that might be answered by their existing notes.
user-invocable: true
---

# Obsidian Vault Search

Search and answer from the Obsidian vault at `~/Documents/second-brain`.

Read `references/vault-rules.md` for vault conventions.

## Workflow

1. **语义搜索（优先）**：用 ChromaDB 索引搜索
   ```bash
   python3 ~/.openclaw/workspace/scripts/vault_search.py "<query>" --top 5
   ```
   - 若索引不存在或报错，提示用户先运行 `/obsidian_index` 建立索引
   - 降级方案：`grep -r -l -i "<terms>" ~/Documents/second-brain/ --include="*.md"` excluding `.obsidian/` and `.claude/`

2. Read top matching notes (up to 5)，获取完整内容

3. For each match, show:
   - File path (relative to vault root)
   - Key relevant excerpt (2-3 lines)

4. Synthesize a comprehensive answer citing notes with `[[wikilinks]]`

5. If information is sparse, note what's missing and suggest using `/research` to explore the topic

## Command

```
/search <query>
```

If no query provided, ask what to search for.
