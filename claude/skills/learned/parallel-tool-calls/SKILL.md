---
name: parallel-tool-calls
description: Use when making multiple independent tool calls (Read, Glob, WebFetch, Bash) that don't depend on each other's results. Symptoms include sequential Read chains, batch file exploration, multi-URL research phases.
---

# Parallel Tool Calls

## Overview

Independent tool calls should be batched in a single message, not called sequentially.

## Quick Reference

| Pattern | Sequential (slow) | Parallel (fast) |
|---------|-------------------|-----------------|
| Read multiple files | Read A → Read B → Read C | Read A + Read B + Read C (one message) |
| Glob then read results | Glob → Read → Read | Glob → Read A + Read B (one message) |
| Fetch multiple URLs | WebFetch → WebFetch | WebFetch A + WebFetch B (one message) |
| Independent Bash | Bash → Bash → Bash | Bash A + Bash B + Bash C (one message) |

## Core Pattern

Before calling tools, ask: does this call depend on a previous call's result?

- **No dependency** → batch in same message
- **Has dependency** → call sequentially

```
# BAD: sequential when files are known
Read("src/auth.ts")          # message 1
Read("src/auth.test.ts")     # message 2
Read("src/types.ts")         # message 3

# GOOD: parallel when files are known
Read("src/auth.ts") + Read("src/auth.test.ts") + Read("src/types.ts")  # message 1
```

## Common Sequences to Parallelize

1. **Glob → parallel Reads**: after Glob returns file list, Read all matches in one message
2. **Research phase**: multiple WebFetch calls to different URLs
3. **Verification**: checking multiple files for a pattern (parallel Grep or Read)
4. **Setup checks**: `git status` + `git log` + `git diff` in one message

## When NOT to Parallelize

- Result of call A determines parameters of call B
- Exploring iteratively (don't know next file until reading current one)
- Write operations that must be ordered
