---
name: obsidian-capture
description: Capture conversation topics as structured Obsidian notes. Triggers on /capture command, or when user says "记录到 obsidian", "总结到笔记", "保存到笔记", "capture this". Extracts the current discussion topic, creates a note with frontmatter and Related links, checks for existing related notes to merge or cross-link, and updates relevant MOC files.
user-invocable: true
---

# Obsidian Capture

Summarize a conversation topic into a structured Obsidian note at `~/Documents/second-brain`.

Read `~/Documents/second-brain/CLAUDE.md` for vault conventions.

## Workflow

### ⚠️ Vault 文件写入规则
所有 vault 文件的创建和编辑必须通过 staging 目录中转（`~/.openclaw/workspace/.vault-staging/`）：
1. 编辑已有文件：先 `cp` 到 staging，编辑完再 `cp` 回 vault
2. 创建新文件：先在 staging 写好完整内容，再一次性 `cp` 到 vault
3. 禁止直接在 vault 目录内多次写入同一文件

### 1. Extract & Draft

- Identify the core topic from recent conversation context
- Draft a structured note:
  - Frontmatter: `date`, `tags`, `aliases`
  - Body: concise summary with key points, code examples if relevant
  - `## Related` section with wikilinks to known related concepts
- Determine target directory from `CLAUDE.md` mapping
- Show the user: proposed title, target path, and brief outline
- Wait for confirmation before proceeding

### 2. Search for Existing Related Notes

Search vault for notes that overlap or relate to the topic:

```bash
python3 ~/.openclaw/workspace/scripts/vault_search.py "<topic keywords>" --top 5
```

Fallback if index unavailable:
```bash
grep -r -l -i "<terms>" ~/Documents/second-brain/ --include="*.md" | grep -v '.obsidian/' | grep -v '.claude/'
```

If related notes found, present them to the user with inline buttons:

- For each candidate, show: note name, why it's related (one line)
- Options per candidate:
  - **合并** — merge new content into existing note
  - **互链** — add wikilinks in both directions
  - **跳过** — no action for this note

**Wait for user response before modifying any existing notes.**

If no related notes found, skip to step 3.

### 3. Write Note

- If user chose "合并": append new content to the existing note (under a new section or integrated into existing structure), do NOT create a new file
- Otherwise: create the new note at the determined path

### 4. Update Links

- For notes user chose "互链": add `[[new-note]]` to their `## Related` section (create section if missing), and add `[[existing-note]]` to the new note's Related
- Find the matching MOC file from `CLAUDE.md`
- Append the new note entry to the appropriate section in the MOC
- If no matching MOC exists, skip MOC update

## Command

```
/capture [optional topic hint]
```

If topic hint provided, use it to focus extraction. Otherwise infer from recent conversation.

## Rules

- Never modify existing notes without explicit user approval
- Keep notes concise — one idea per note, not a conversation dump
- Use the same language as the conversation (typically Chinese)
- Preserve existing note structure when merging
- Avoid duplicate entries in MOC and Related sections
