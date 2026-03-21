---
name: obsidian-search
description: >
  Search Obsidian vault and answer questions using vault knowledge. Use this skill whenever
  the user asks about their notes, wants to find information in their vault, or asks questions
  that could be answered by their existing knowledge base. Triggers on: "笔记里有没有",
  "vault 里关于", "我之前记过", "search my notes", "check my vault", "有没有相关笔记",
  "obsidian search", or any question where the user's personal notes might contain the answer.
  Also use when the user references their "second brain" or asks about topics they've previously
  studied/clipped/researched.
user-invocable: true
---

# Obsidian Vault Search

Search `~/Documents/second-brain` and answer questions based on vault content.

## Workflow

### 1. Query Rewriting

The user's natural language question needs to become effective search terms.

- Strip conversational wrappers ("笔记里有没有...", "帮我查一下", "有没有...的信息")
- Keep core nouns, proper nouns, and technical terms
- Add synonyms and English/Chinese equivalents (e.g., "写入行数" → also try "Rows/s", "TPS", "throughput")

**Example:**
- User: "笔记里有 lindorm 每秒写入行数信息么？"
- Search terms: "lindorm 写入行数", "lindorm Rows/s", "lindorm TPS throughput"

### 2. Search

Run multiple Grep searches in parallel with different term combinations:

```
Grep pattern="<term1>" path="~/Documents/second-brain" glob="*.md"
Grep pattern="<term2>" path="~/Documents/second-brain" glob="*.md"
```

Exclude non-content directories: skip results from `.obsidian/`, `Templates/`, `Excalidraw/`.

If Grep finds too many results, narrow with Glob for specific filenames first, then read the most relevant files.

If zero results, try:
- Broader terms (remove qualifiers)
- English↔Chinese equivalents
- Related concepts

### 3. Read and Synthesize

Read the top 3-5 most relevant files. Synthesize an answer that:

- Directly answers the user's question
- Cites source notes using `[[wikilinks]]`
- Quotes key passages when helpful
- Notes if the information might be outdated (check `date` in frontmatter)

### 4. Report

If vault contains relevant information: answer the question with citations.
If nothing found: say so clearly, and suggest the user might want to research the topic (they can use `/deep-research`).

## Command

```
/obsidian-search <query>
```

If no query provided, ask what to search for.

## Vault Reference

- Path: `~/Documents/second-brain`
- Format: Markdown with YAML frontmatter
- Links: `[[wikilink]]` format
- Read `~/Documents/second-brain/CLAUDE.md` for full vault conventions if needed
