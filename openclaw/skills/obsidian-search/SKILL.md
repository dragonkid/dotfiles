---
name: obsidian-search
description: Search Obsidian vault and answer questions using vault knowledge. Triggers on /search command, vault search requests, or when user asks questions that might be answered by their existing notes.
user-invocable: true
---

# Obsidian Vault Search

Search and answer from the Obsidian vault at `~/Documents/second-brain`.

Read `references/vault-rules.md` for vault conventions.

## Workflow

1. Search all `.md` files in `~/Documents/second-brain` for content related to the query
   - Use `grep -r -l -i "<terms>" ~/Documents/second-brain/ --include="*.md"` excluding `.obsidian/` and `.claude/`
   - Try multiple search terms (synonyms, Chinese/English variants)
2. Read top matching notes (up to 5)
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
