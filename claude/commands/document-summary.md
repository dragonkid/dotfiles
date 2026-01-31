---
name: document-summarizer
description: Use ONLY when user provides EXTERNAL text, article content, or webpage URL and explicitly asks to create a summary or extract key points. Never use for code, skill files, or documentation analysis.
---

## Overview

Generate structured, concise summaries of text content or webpages with a two-phase workflow that prioritizes user confirmation before generating full summaries.

## When to Use

-   User provides external article/document text and asks for a summary
-   User provides a webpage URL and requests a summary
-   User wants to extract key points from article/news/blog content
-   User explicitly says "summarize this article/text/content" with non-code content

## When NOT to Use

-   User asks about code, skill files, or technical documentation
-   User wants to debug, analyze, or examine files
-   User asks to check or review code/skills/configuration
-   The input is code, markdown documentation, or skill files

## Summary Workflow

```
Input Text or URL
    ↓
Determine Input Type
    ↓
Process Content (URL: fetch if tool available, else ask user to paste/path / Text: direct)
    ↓
Generate Quick Preview (bullet points only)
    ↓
Show Preview → Ask: Save needed?
    ↓ NO              ↓ YES
End             Generate Full Summary (points + detailed + conclusions)
                    ↓
                 Show Full Summary → Ask: Confirm save?
                    ↓ NO              ↓ YES
                 End              Scan Target Root Directory
                                      ↓
                                   Show Available Subdirectories
                                      ↓
                                   Ask: Select existing or enter new name?
                                      ↓
                                   Build Full Path
                                      ↓
                                   Generate Filename: {Title}.md
                                      ↓
                                   Check for Duplicates
                                      ↓ None
                                   Save File
                                      ↓ Duplicate
                                   Ask: Merge content?
                                      ↓ YES           ↓ NO
                                   Merge Content    Use Timestamped Name
                                      ↓               ↓
                                   Save File       Save File
```

## Input Processing

### Text Input

Process directly with summary generation.

### URL Input

**If a web fetch/reader tool is available** :

-   Use it with: `url`, `return_format: "markdown"`, `retain_images: false`, `timeout: 20`.

**If in Claude Code or no web reader tool is available (tool missing / call fails):**

-   Do **not** retry the tool. Immediately use the fallback:
    1. Say: "当前环境无法直接抓取网页。请把要总结的全文粘贴到对话里，或告诉我本地文件的路径，我根据内容生成总结。"
    2. Wait for the user to paste content or provide a file path.
    3. If they provide a path, read the file with the Read tool; if they paste text, use it directly.
    4. Then continue with Phase 1 (Quick Preview) as usual.

## Two-Phase Summary Workflow

### Phase 1: Quick Preview

Generate concise bullet points preview and ask if saving is needed.

```markdown
# [Document Title]

## Core Points

-   Point 1
-   Point 2
-   Point 3

---

**Source**: [URL or "User-provided text"]
**Preview Time**: [Timestamp]
```

**After showing preview:** 在此处必须输出一句明确的问题给用户，并等待用户回复后再继续下一步。
Ask: "这个总结需要保存吗？"

-   **NO**: End workflow
-   **YES**: Proceed to Phase 2

### Phase 2: Full Summary

Generate complete summary only after user confirms save is needed.

```markdown
# [Document Title]

## Core Points

-   Point 1
-   Point 2
-   Point 3

## Detailed Summary

[Section-by-section summary preserving key details and context]

## Key Conclusions

[Main conclusions, insights, and actionable takeaways]

---

**Source**: [URL or "User-provided text"]
**Summary Time**: [Timestamp]
```

**After showing full summary:** 在此处必须输出一句明确的问题给用户，并等待用户回复后再继续下一步。
Ask: "确认要保存吗？"

-   **NO**: End workflow
-   **YES**: Proceed to Save Workflow

## Save Workflow

### Fixed Root Path

```
/Users/dragonkid/Library/CloudStorage/GoogleDrive-idragonkid@gmail.com/My Drive/Second Brain
```

### Ignored Directories

Filter out these subdirectories when scanning:

-   `Attachments/`
-   `Bookshelf/`
-   `Clippings/`
-   `Excalidraw/`
-   `Interview/`
-   `Jobs/`
-   `Personal/`

### Step 1: Scan Available Subdirectories

Use Bash to scan root directory and filter ignored directories:

```bash
for dir in "/Users/dragonkid/Library/CloudStorage/GoogleDrive-idragonkid@gmail.com/My Drive/Second Brain"/*/; do
  basename "$dir"
done | grep -v -E "^(Attachments|Bookshelf|Clippings|Excalidraw|Interview|Jobs|Personal)$"
```

Display results as numbered list:

```
Available directories:
1. Quantative
2. LLM
3. [Other directories...]
```

### Step 2: Ask for Directory Selection

在此处必须输出一句明确的问题给用户，并等待用户回复后再继续下一步。
Ask: "选择现有目录（输入数字或名称）或输入新目录名？"

### Step 3: Build Full Path

Construct target path:

```
{ROOT_PATH}/{USER_SELECTED_DIRECTORY}
```

### Step 4: Generate Filename

Default filename: `{Document Title}.md`

**Title Optimization:**
- Create a concise,概括性 title that captures the essence of the document
- Avoid using the original article's catchy or lengthy title
- Focus on clarity and searchability
- Examples:
  - Original: "Skills商店来了：5万人在用的Top 10热门Skills，我帮你试了一遍"
  - Optimized: "Claude-Skills-应用商店实用指南" or "Claude Skills 生态与实践"

Clean filename:

-   Remove special characters: `/ \ : * ? " < > |`
-   Replace spaces with hyphens or remove
-   Preserve Chinese characters
-   Limit length to reasonable size (avoid overly long filenames)

### Step 5: Check for Duplicates

Use Glob to check for existing files:

```
- pattern: "{filename}.md"
- path: "{target_directory}"
```

### Step 6: Handle Conflicts

**If no duplicate exists:**
Save directly to target path.

**If duplicate exists:** 在此处必须输出一句明确的问题给用户，并等待用户回复后再继续下一步。
Ask: "发现已存在 `{filename}.md`，是否要将新总结追加到原文件？"

Options:

-   **Merge** (合并): Append new summary to existing file
-   **New file** (另存为新文件): Use `{Title}-{timestamp}.md`

**Merge strategy:**
Add separator and new summary at end of existing file:

```markdown
---

# [Updated Document Title] - [New Date]

[New summary content]
```

### Step 7: Save File

Use Write tool:

```
- file_path: "{full_path}/{filename}.md"
- content: [generated summary or merged content]
```

## Quick Reference

| Input Type   | Processing Method                                                                |
| ------------ | -------------------------------------------------------------------------------- |
| Text snippet | Direct summarization                                                             |
| URL          | Use web reader if available; else ask user to paste content or provide file path |

| User Response      | Action                   |
| ------------------ | ------------------------ |
| "不需要" (Phase 1) | End workflow             |
| "需要" (Phase 1)   | Generate full summary    |
| "不确认" (Phase 2) | End workflow             |
| "确认" (Phase 2)   | Proceed to save workflow |

| File Status      | Action                  |
| ---------------- | ----------------------- |
| No duplicate     | Save directly           |
| Duplicate exists | Ask merge/skip choice   |
| Merge selected   | Append to existing file |
| Skip selected    | Use timestamped name    |

## Common Mistakes

-   **Calling non-existent web tool**: If web fetch/reader fails or is missing, switch to fallback (ask user to paste or provide path); do not retry or hang.
-   **Skipping Phase 1 preview**: Always show quick preview before generating full summary
-   **Not asking for confirmation**: Ask at both Phase 1 (save needed?) and Phase 2 (confirm save?)
-   **Skipping directory selection**: Always show available directories and ask user to choose
-   **Forgetting to filter ignored directories**: Always exclude Attachments/Bookshelf/Clippings/Excalidraw/Interview/Jobs/Personal
-   **Not checking duplicates**: Always check for existing files before writing
-   **Using wrong root path**: Always use the fixed Second Brain path, never ask user for save location
-   **Auto-saving without confirmation**: Never save without explicit user confirmation at both phases
