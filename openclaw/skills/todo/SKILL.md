---
name: todo
description: Use when user wants to manage TODO items - adding tasks, listing pending items, marking done, removing, or searching. Triggers on /todo command or TODO-related requests.
command-dispatch: tool
user-invocable: true
---

# TODO Management Skill

Quick TODO list management via Telegram bot commands.

## 执行规则

1. **必须回复用户** - 这是用户主动发起的命令，执行后**必须**发送可见的回复。绝对不能回复 NO_REPLY。
2. **操作后展示完整列表** - 每次增删改操作后，先确认操作（如 ✅ 已添加：xxx），再展示完整的 TODO 列表
3. **直接操作 TODO.md** - 读取和编辑 `~/.openclaw/workspace/TODO.md`，无需外部脚本

## Work Rules

1. **TODO 文档位置：** `~/.openclaw/workspace/TODO.md` （本地 Markdown 文件）

2. **保持简洁：** 只记录任务和原始链接

3. **当可以获取文档内容时** - 按 bullet 总结文章要点和结论，列在对应的 TODO 下面

4. **保留原始链接** - 即使已总结过也不要删除，因为可能还需要查看完整内容

5. **不要随意修改已稳定的文档结构**

## Commands

### List TODOs (default)
```
/todo              # Show list
/todo list
/todo l            (abbreviation)
```

Shows all pending TODO items with line numbers.

**列表格式规则：**
- 每个条目显示序号和标题
- 如果条目包含链接（markdown link 或纯 URL），必须在标题后附上链接，方便用户直接点击
- 格式示例：`1. 标题 链接` 或 `1. [标题](链接)`
- 已完成的条目用 ~~删除线~~ + ✅ 标记，统一放在列表最后的「已完成」区域
- 列表顺序：先显示所有待办，最后显示已完成

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

### 已完成条目管理
- 标记完成时，在条目末尾追加完成日期注释：`<!-- done:2026-02-16 -->`
- list 输出时，已完成条目统一放在列表最后
- 每次 list 时检查已完成条目的完成日期，超过 7 天的从 TODO.md 中删除
- 删除时静默处理，不需要通知用户
