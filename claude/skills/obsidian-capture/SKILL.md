---
name: obsidian-capture
description: >
  Save content to Obsidian vault — from conversations, URLs, or batch-process existing Clippings.
  The unified entry point for writing anything into the knowledge base. Use this skill when the user
  wants to capture conversation insights to notes, clip/summarize a web article, process their
  Clippings inbox, or save any content to Obsidian. Triggers on: "记录到 obsidian", "保存到笔记",
  "capture this", "总结到笔记", "clip this", "save to vault", "/capture", "处理 clippings",
  "review clippings", "保存到 obsidian", or when the user shares a URL and wants it saved to their
  knowledge base. Also triggers on "记一下", "存下来", "写到笔记里" in the context of vault operations.
user-invocable: true
---

# Obsidian Capture

Save content to `~/Documents/second-brain` — the unified write entry point for the vault.

Read `~/Documents/second-brain/CLAUDE.md` for vault conventions before first write.

## Mode Detection

Determine mode from user input:

| Input | Mode |
|-------|------|
| `/capture` (no args) | **Conversation** — extract from current chat |
| `/capture <topic hint>` | **Conversation** — focused extraction |
| `/capture <url>` | **URL** — fetch and process web content |
| `/capture review` | **Batch** — iterate through Clippings/ |

## Mode 1: Conversation Capture

Extract insights from the current conversation and save as a structured note.

### Step 1: Draft

- Identify the core topic from recent conversation
- Determine target directory (see Folder Mapping below)
- Draft a structured note:
  - Frontmatter: `date`, `tags`, `aliases`
  - Body: concise summary with key points, code examples if relevant
  - `## Related` section (populated after search in Step 2)
- Present to user: proposed title, target path, brief outline
- Wait for confirmation

### Step 2: Find Related Notes

Search vault for overlapping content:

```
Grep pattern="<topic keywords>" path="~/Documents/second-brain" glob="*.md"
```

If related notes found, present each with options:
- **Merge** — combine new content into existing note (don't create new file)
- **Cross-link** — keep both, add `[[wikilinks]]` in both directions
- **Skip** — no action for this note

Wait for user response before modifying anything.

### Step 3: Write

- If merge: append to existing note under new section or integrated into structure
- Otherwise: create new note at target path
- For cross-linked notes: add `[[new-note]]` to their `## Related` section, add `[[existing-note]]` to new note
- Update the matching MOC (append to `## Unsorted` section)

## Mode 2: URL Capture

Fetch web content and save to vault.

### Step 1: Fetch

Use Exa crawling MCP or WebFetch to get article content:

```
mcp__exa__crawling_exa url="<url>" maxCharacters=10000
```

If Exa fails, fall back to WebFetch. Extract: title, author, date, full text.

### Step 2: Choose Processing Depth

Present options to user:
- **Clip** — faithful Markdown conversion, save to `Clippings/` (quick, preserves original)
- **Summarize** — structured summary in domain folder + original in `Clippings/` (deeper processing)

### Step 3a: Clip Path

Convert article to clean Markdown:

```yaml
---
title: "<title>"
source: "<url>"
author:
  - "<author>"
date: YYYY-MM-DD
tags:
  - clippings
---
```

- Clean Markdown with proper headings, lists, code blocks
- Strip ads, promotional content, "follow me" sections
- Save to `Clippings/<title>.md`

### Step 3b: Summarize Path

Generate structured summary, then follow Steps 2-3 from Conversation Capture mode (find related notes, handle merge/link, write to domain folder, update MOC).

Additionally create a Clipping note as reference:

**Domain note** → `<folder>/<optimized-title>.md`
```yaml
---
date: YYYY-MM-DD
tags: [status/seed, source/clipping, type/<inferred>]
aliases: []
---
```

**Clipping note** → `Clippings/<title>.md`
```yaml
---
title: "<original title>"
source: "<url>"
author: ["<author>"]
date: YYYY-MM-DD
tags: [clippings]
---
```
Brief summary paragraph + `## Related` linking to domain note.

**Title optimization:** Create concise, descriptive, searchable titles. Avoid catchy original titles — focus on clarity.

## Mode 3: Batch Clippings Review

Iterate through `Clippings/` one by one, processing unread clippings.

### Per-file Flow

1. **Read** the clipping file
2. **Preview** — present to user:
   - Source link (from frontmatter)
   - Content structure overview
   - Core topic and key insights
   - Practical value assessment
3. **User decides** (via AskUserQuestion):
   - **Summarize** → generate full summary, then follow summarize path (Step 3b from URL mode)
   - **Skip** → keep file, move to next
   - **Skip and delete** → remove clipping file, move to next
4. If summarize chosen and saved, ask: "Delete original Clipping?"
5. Ask: "Continue to next?" or "Stop"

### Which files to process

- Read all `.md` files in `Clippings/`
- Skip files that already have a corresponding domain note (check if any note in domain folders links back to this clipping via `[[wikilink]]`)
- Process in chronological order (oldest first, by `date` in frontmatter)

## Shared Logic

### Folder Mapping

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
| Runbooks, operational guides | `Runbooks/` |
| Other / unclear | Ask user |

Excluded directories (never save to): `Attachments/`, `Excalidraw/`, `Interview/`, `Jobs/`, `Personal/`, `Templates/`

### MOC Update

After creating a domain note:
1. Find the matching MOC from vault CLAUDE.md's existing MOC list
2. Append the new note to `## Unsorted` section
3. If no matching MOC exists, skip

### Duplicate Check

Before writing, search target directory for files with similar names or overlapping content.
If found, present options: merge into existing, or save as new file.

### Note Quality

The target reader is "future self who has forgotten all context." Every note should be self-contained enough to be useful months later:

- Technical decisions: include the problem, alternatives considered, final choice with rationale
- Data and numbers: include source and meaning (no naked numbers without context)
- Prefer over-explaining "why" to writing bare conclusions

### Language

Match the language of the source content. For conversation capture, match the conversation language (typically Chinese).

## Command

```
/capture                    # From conversation
/capture <topic hint>       # Focused conversation extraction
/capture <url>              # Clip or summarize URL
/capture review             # Batch process Clippings/
```
