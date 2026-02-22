---
name: obsidian-summary
description: Summarize documents (URLs, text, or existing Clippings) and save to Obsidian vault. Triggers on /summary command, document summary requests, URL processing for knowledge base, or when user shares an article/link to process into notes.
user-invocable: true
---

# Document Summary → Obsidian

Summarize external content and save structured notes to `~/Documents/second-brain`.

Read `references/vault-rules.md` before writing any notes.

## Workflow

### Phase 1: Quick Preview

1. Fetch content from URL (`web_fetch`) or read provided text / existing Clipping
2. Present a detailed preview including:
   - Source link (original URL from frontmatter)
   - Content structure overview (major sections/chapters)
   - Core topic and thesis
   - Key insights, techniques, or unique angles
   - Practical value / relevance / target audience
   - Length/depth assessment
3. Present three options via inline buttons:
   - **继续** → Phase 2
   - **跳过** → keep Clipping, move to next
   - **跳过并删除** → delete Clipping file, move to next

### Phase 2: Full Summary Preview

On "继续", generate and display the complete structured summary in chat so the user can review the content in detail. This serves both as a learning/reading step and a preview of what will be saved.

After displaying, present inline buttons:
   - **保存** → Phase 3 (write to vault)
   - **跳过** → discard summary, keep Clipping, move to next
   - **跳过并删除** → discard summary, delete Clipping, move to next

### Phase 3: Save to Vault

Before writing, search the target folder and related MOC for existing notes with overlapping content:
- Use grep to find notes with similar keywords/topics
- If related notes found, present options per note via inline buttons:
  - **合并** → merge new content into existing note (append new sections, deduplicate)
  - **关联** → keep both, add `[[wikilinks]]` in both directions
  - **跳过** → no relationship
- If no related notes found, create new note directly.

On "保存", write two notes:

**A. Domain note** → `<folder>/<optimized-title>.md`

```yaml
---
date: YYYY-MM-DD
tags: [status/seed, source/clipping, type/<inferred>]
aliases: []
---
```

- Structured summary with sections, tables, key concepts
- `## Related` section with `[[wikilinks]]` to relevant vault notes and source Clipping

**B. Clipping note** (only if source is a URL) → `Clippings/<title>.md`

```yaml
---
title: "..."
source: "URL"
author: ["..."]
created: YYYY-MM-DD
description: "..."
tags: [clippings]
---
```

- Brief summary paragraph
- `## Related` linking to domain note

**Title optimization:** Create concise, descriptive title. Avoid catchy original titles. Focus on clarity and searchability.

### Phase 4: Update MOC

Add domain note to relevant MOC's `## Unsorted` section. Create a new heading if a clear category exists.

### Phase 5: Confirm

Report file paths and MOC update. Keep it brief.

## Folder Mapping

| Domain | Folder |
|--------|--------|
| AI, LLM, RAG, Transformer, Agent | `LLM/` |
| Trading, quant, arbitrage, on-chain | `Quantative/` |
| Blockchain, Solana, DeFi, Web3 | `Web3/` |
| Database, system design, infra | `Tech Design/` |
| Big data, Flink, Spark | `Big Data/` |
| Security | `Security/` |
| Tools, dev tools | `Tools/` |
| Books, reading | `Bookshelf/` |
| Other / unclear | Ask user |

Ignored dirs (never save to): `Attachments/`, `Excalidraw/`, `Interview/`, `Jobs/`, `Personal/`

## Duplicate Check

Before saving, search target directory for existing files with similar names. If found, ask user: merge or save as new file.

## Sequential Review Mode

`/summary` with no args → iterate through `Clippings/` one by one. For each file: present bullet points → user decides (save / skip) → proceed to next file.

After each file is processed (saved, skipped, or deleted), present inline buttons:
- **继续下一篇** → proceed to next Clipping
- **结束** → stop review

## Auto-trigger

In the "AI 工作台" topic 3 chat, if the user sends a message containing only a URL (no other text), automatically trigger Phase 1 (fetch + quick preview) without requiring `/summary`.

## Command

```
/summary <url-or-text>    # Summarize and save
/summary                  # Review unprocessed Clippings
```
