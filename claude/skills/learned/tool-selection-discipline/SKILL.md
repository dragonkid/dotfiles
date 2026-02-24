---
name: tool-selection-discipline
description: Use when choosing between Bash and dedicated tools (Glob, Read, Grep, Task) for file operations, directory listing, or codebase exploration. Symptoms include reaching for ls, grep, or find in Bash when specialized tools exist.
---

# Tool Selection Discipline

Choose the right tool for the job. Specialized tools are faster, permission-aware, and return structured results. Bash is for commands that have no dedicated tool equivalent.

## Quick Reference

| Task | Wrong | Right |
|------|-------|-------|
| List directory contents | `Bash ls` | Glob `**/*` |
| Search file contents | `Bash grep/rg` | Grep tool |
| Find files by pattern | `Bash find` | Glob tool |
| Read file contents | `Bash cat/head/tail` | Read tool |
| Open-ended code exploration | Sequential Glob+Grep | Task[Explore] agent |

## Core Pattern

```
Before issuing Bash: "Does a dedicated tool handle this?"
  Yes → Use it (Glob, Grep, Read, Task[Explore])
  No  → Use Bash (git, make, curl, pip, docker, etc.)
```

## When Bash IS Correct

- Git operations (`git status`, `git commit`, `git -C`)
- Build/test commands (`make`, `pytest`, `ruff`)
- API testing (`curl`)
- Package management (`pip`, `uv`, `npm`)
- Any command without a dedicated tool equivalent

## When NOT to Use

- You need unix metadata (permissions, timestamps, ownership) — `Bash ls -la` is appropriate
- Complex piped commands that combine multiple operations — Bash may be more efficient
- You're already in a Bash-heavy debug session running sequential commands

## Common Mistakes

- Using `Bash ls` to check if files exist (use Glob)
- Using `Bash grep -r` to search code (use Grep tool — respects .gitignore, returns structured results)
- Running multiple sequential Glob/Grep when a single Task[Explore] agent would be more effective
- Forgetting that Read must precede Edit (always Read a file before editing it)
