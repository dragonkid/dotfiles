# Vault Rules Reference

Vault path: `~/Documents/second-brain`

## Frontmatter

All new notes:

```yaml
---
date: YYYY-MM-DD
tags: []
aliases: []
---
```

Clippings also include: `title`, `source`, `author`, `published`, `created`, `description`.

## Tag Taxonomy

Metadata dimensions only, NOT topic classification (folders handle that).

| Category | Tags | Purpose |
|----------|------|---------|
| Status | `#status/seed`, `#status/growing`, `#status/evergreen` | Note maturity |
| Source | `#source/clipping`, `#source/original`, `#source/research` | Content origin |
| Type | `#type/how-to`, `#type/concept`, `#type/comparison`, `#type/log` | Note format |

Rules: `kebab-case`, nested tags, frontmatter placement, total unique tags < 50.

## Linking

- `[[wikilink]]` format for all internal links
- Link when meaningful semantic relationship exists
- Do NOT create redundant backlinks (Obsidian handles reverse navigation)
- `## Related` section at END of each note:
  ```markdown
  ## Related
  - [[other-note]] - brief description
  ```

## MOC (Map of Content)

- Create MOC when 6+ related notes exist
- Add new notes to relevant MOC's `## Unsorted` section
- A note can appear in multiple MOCs

Existing MOCs:
- `LLM/LLM MOC.md`
- `Quantative/Quantative MOC.md`
- `Web3/Web3 MOC.md`
- `Tech Design/Tech Design MOC.md`

## Folder Structure

- `Attachments/` - Images and files
- `Big Data/` - Flink, Spark
- `Bookshelf/` - Book summaries
- `Clippings/` - Web clippings (doubles as Inbox)
- `Excalidraw/` - Diagrams
- `Interview/` - Interview prep
- `Jobs/` - Work notes
- `LLM/` - AI/ML topics
- `Personal/` - Personal docs
- `Quantative/` - Trading, arbitrage
- `Research/` - Research output
- `Security/` - Security topics
- `Tech Design/` - DB, system design
- `Templates/` - Do NOT edit
- `Tools/` - Tool docs
- `Web3/` - Blockchain topics
