---
name: obsidian-link
description: Analyze an Obsidian note and find related notes to suggest wikilinks. Triggers on /link command, or when user asks to find connections between notes or improve note linking.
user-invocable: true
---

# Obsidian Link Finder

Analyze a note and suggest `[[wikilinks]]` to related notes in `~/Documents/second-brain`.

Read `~/Documents/second-brain/CLAUDE.md` for linking conventions.

## Workflow

### ⚠️ Vault 文件写入规则
编辑 vault 文件必须通过 staging 目录中转（`~/.openclaw/workspace/.vault-staging/`）：
先 `cp` 到 staging，编辑完再 `cp` 回 vault。禁止直接在 vault 目录内多次写入同一文件。

1. Read the target note
2. Extract key topics, terms, and concepts
3. Search the vault for notes containing related content:
   - `grep -r -l -i "<term>" ~/Documents/second-brain/ --include="*.md"` excluding `.obsidian/`, `.claude/`
   - Try multiple terms and synonyms
4. For each related note found, present:
   - File path (relative to vault root)
   - Why it's related (one line)
   - Suggested `[[wikilink]]` text
5. Ask user which links to add
6. Insert approved links into `## Related` section at end of the note
   - If `## Related` already exists, append to it (avoid duplicates)
   - If not, create it

## Command

```
/link <note-path>
```

Path can be relative to vault root or absolute. If relative, resolve from `~/Documents/second-brain`.

If no path provided, ask which note to analyze.
