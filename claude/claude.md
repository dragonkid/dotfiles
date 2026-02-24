# Claude Code Instructions

## Task Execution (CRITICAL)
- Write minimal solutions: implement only what's explicitly requested
- Prioritize simplicity over abstraction
- After code changes, check if related files need updates: README, install scripts, Makefile, CLAUDE.md
- No "helpful" additions: refactoring, extra tests, documentation updates, or code cleanup
- No "while I'm here" changes
- When tempted to do extra work: ask "Should I also...?" instead
- Before presenting solution: verify each change was explicitly requested

## Planning and Confirmation
- For complex tasks (multiple files, architectural changes, >50 lines):
  1. Present complete plan FIRST
  2. Wait for explicit approval before coding
  3. Use plan mode (/plan) when uncertain about approach
- Before starting implementation, confirm:
  - Target database/framework if relevant
  - Exact scope (which files, which sections)
  - Output format preferences
- When uncertain: ask clarifying questions upfront, don't make assumptions

**When I say "给我计划", "设计方案", "怎么实现":**
- STOP immediately, do NOT start implementing
- Present COMPLETE plan with:
  * All files to be modified (with paths)
  * Specific changes for each file
  * Tradeoffs between approaches
  * Potential risks
- WAIT for explicit approval ("开始实现", "执行", "proceed")
- Violation: I will interrupt immediately, wasting time

## Batch Operations (CRITICAL)

For bulk changes (translations, formatting, mass refactoring):
- Read ENTIRE file content first (one Read operation)
- Process ALL changes in memory (single operation)
- Write complete result in ONE Write operation
- NEVER use sequential Edit operations

Examples:
- Translation: Read → translate all in memory → Write (1 operation)
- Formatting: Read → format all in memory → Write (1 operation)

**Key Principle**: Batch operations = Read Once + Write Once, never sequential edits

## Tool Selection
1. File operations: Read, Edit, Grep, Glob (not bash)
2. Web search: mgrep --web preferred, WebSearch as fallback
3. Documentation lookup: context7 MCP server
4. Parallelize independent operations
5. Read files before editing

## Uncertainty Handling (CRITICAL)
- NEVER assert something is wrong/nonexistent without verifying first
- When uncertain: search codebase, query docs (context7), or web search to verify
- If still uncertain after verification: explicitly state uncertainty and ask the user
- NEVER make changes based on unverified assumptions

## Decision Principle (CRITICAL)
- When presenting multiple options: research best practices first, mark the recommended option, and explain why
- ALWAYS use `AskUserQuestion` tool when presenting options or asking for decisions, so the user can select directly instead of typing
- NEVER list options as plain text (numbered lists, bullet points, "Option A / Option B") — if the user needs to choose, it MUST go through `AskUserQuestion`
- The ONLY exception: explaining steps in a plan or tutorial where no user decision is needed

WRONG (plain text options):
```
Here are three approaches:
1. Use Redis
2. Use Memcached
3. Use in-memory cache
Which do you prefer?
```

RIGHT: call `AskUserQuestion` with the options as structured choices

## Response Style
- Concise: omit filler and unnecessary explanation
- Factual: prioritize accuracy over agreement
- Plain text: omit emojis unless requested
