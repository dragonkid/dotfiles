---
name: todo
description: Use when user wants to manage TODO items - adding tasks, listing pending items, marking done, removing, or searching. Triggers on /todo command or TODO-related requests.
command-dispatch: tool
user-invocable: true
---

# TODO Management Skill

Quick TODO list management via Telegram bot commands.

## Work Rules

1. **TODO 文档位置：** `~/.openclaw/workspace/TODO.md` （本地 Markdown 文件）

2. **保持简洁：** 只记录任务和原始链接

3. **当可以获取文档内容时** - 按 bullet 总结文章要点和结论，列在对应的 TODO 下面

4. **保留原始链接** - 即使已总结过也不要删除，因为可能还需要查看完整内容

5. **不要随意修改已稳定的文档结构**

6. **新增待办事项时自动调研** - 当用户添加新的待办事项时，自动进行相关调研并将结果添加到对应事项下面

## Commands

### List TODOs (default)
```
/todo              # Show list
/todo list
/todo l            (abbreviation)
```

Shows all pending TODO items with line numbers.

**Default:** Empty `/todo` shows the list.

### Add TODO
```
/todo add <description>
/todo a <description>      (abbreviation)
```

Adds a new TODO item. If the item looks like it needs research (contains URLs, mentions technologies, etc.), automatically research and add context.

**Note:** `/todo <something>` without a recognized subcommand will also add (for quick entry).

### Search TODOs
```
/todo search <keyword>
/todo s <keyword>     (abbreviation)
```

Search TODOs by keyword (case-insensitive).

### Complete TODO
```
/todo done <number>           # Single item
/todo done 1,3,5             # Multiple items (comma-separated)
/todo done <partial text>    # Fuzzy match
/todo d <...>                # Abbreviation
```

Marks TODO(s) as complete. Supports:
- Line number: `/todo done 3`
- Multiple: `/todo done 1,3,5`
- Fuzzy text: `/todo done 探索` (shows matches if ambiguous)

### Remove TODO
```
/todo remove <number>         # Single item
/todo rm 1,3,5               # Multiple items
/todo del <partial text>     # Fuzzy match
/todo r <...>                # Abbreviation
```

Removes TODO(s) entirely. Supports same matching as `done`.

## Features

### Smart Matching
- **By number:** `/todo done 3` - exact line
- **By text:** `/todo done 探索` - fuzzy search
- **Disambiguation:** Shows matches if multiple items found

### Auto-Research
When adding a TODO, auto-research if:
- Contains a URL
- Mentions specific technologies/tools
- User explicitly requests research

Otherwise, just add the raw item quickly.
