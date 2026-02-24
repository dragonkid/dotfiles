---
name: iterative-debug-workflow
description: Use when debugging, testing API endpoints, or in iterative code-test-fix cycles. Symptoms include heavy Bash usage, repeated curl calls, consecutive Edit streaks, or alternating between code changes and test runs.
---

# Iterative Debug Workflow

Debug and test sessions follow a distinct pattern: heavy Bash usage, repeated API testing with curl, and consecutive Edit streaks. Recognize this mode and optimize for it.

## Quick Reference

| Phase | Pattern | Tools |
|-------|---------|-------|
| Investigate | Run commands, check logs | Bash, Read |
| Fix | Consecutive edits to related files | Edit (streaks of 3-10) |
| Verify | Run tests, hit endpoints | Bash (pytest, curl, make) |
| Confirm | Check with user before continuing | AskUserQuestion |

## Core Pattern

```
Bash (investigate) → Edit streak (fix) → Bash (verify) → AskUserQuestion (confirm)
                        ↑                                         |
                        └─────────────────────────────────────────┘
```

## API Testing with Curl

When testing endpoints iteratively:
- Use `curl -s` for clean output
- Pipe JSON responses through formatting when needed
- Vary payloads systematically to test edge cases
- Keep the endpoint URL consistent, change only the body

## Edit Streaks

During fix phases, consecutive Edit calls are expected (up to 10 in a row). This is normal for:
- Fixing the same bug across multiple files
- Updating schemas + handlers + tests together
- Applying a pattern change across related code

For bulk changes to a **single** file, prefer Read-once → Write-once over sequential Edits.

## When NOT to Use

- Single-file, single-edit fixes — no iteration needed
- Pure exploration tasks — use Task[Explore] instead
- Documentation-only changes — no verify loop needed
