---
name: obsidian-summary
description: Summarize documents (URLs, text, or existing Clippings) and save to Obsidian vault. Triggers on document summary requests, URL processing for knowledge base, /summary command, or when user shares an article/link to process into notes.
---

# Document Summary → Obsidian

Summarize external content and save structured notes to `~/Documents/second-brain`.

Read `references/vault-rules.md` before writing any notes.

## Workflow

### Phase 1: Quick Preview

1. Fetch content from URL (`web_fetch`) or read provided text / existing Clipping
2. Present 3-5 bullet points:
   - Core topic and thesis
   - Key insights or techniques
   - Practical value / relevance
   - Freshness assessment
3. Ask: "需要保存吗？"
4. User says skip → stop. User confirms → Phase 2.

### Phase 2: Full Summary + Save

On confirmation, generate two notes:

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

### Phase 3: Update MOC

Add domain note to relevant MOC's `## Unsorted` section. Create a new heading if a clear category exists.

### Phase 4: Confirm

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

## Batch Mode

`/summary` with no args → iterate through `Clippings/`, present bullet points per file, user decides: process or skip.

## Command

```
/summary <url-or-text>    # Summarize and save
/summary                  # Review unprocessed Clippings
```
