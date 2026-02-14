---
description: Search Obsidian vault and answer questions using vault knowledge
---

Search and answer from the Obsidian vault at ~/Documents/second-brain.

Query: $ARGUMENTS

Steps:
1. Use mgrep to search all .md files in ~/Documents/second-brain for content related to the query
2. Read the top matching notes (up to 5)
3. For each match, show:
   - File path (relative to vault root)
   - Key relevant excerpt
4. Synthesize a comprehensive answer based on the vault's knowledge, citing notes with [[wikilinks]]
5. If relevant information is sparse, note what's missing and suggest using /obsidian-research to research the topic

If $ARGUMENTS is empty, ask what the user wants to search for.
