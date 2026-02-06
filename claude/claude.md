# Claude Code Instructions

## Task Execution
- Apply best practices for all code and recommendations
- Write minimal solutions: implement only what's explicitly requested
- Prioritize simplicity over abstraction
- After code changes, check if related files need updates: README, install scripts, Makefile

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

## Planning and Confirmation (BLOCKING REQUIREMENT)

**When I say "给我计划", "设计方案", "怎么实现":**
- STOP immediately, do NOT start implementing
- Present COMPLETE plan with:
  * All files to be modified (with paths)
  * Specific changes for each file
  * Tradeoffs between approaches
  * Potential risks
- WAIT for explicit approval ("开始实现", "执行", "proceed")
- Violation: I will interrupt immediately, wasting time

**Recommended workflows:**
- For creative/design work: Use `/brainstorming` skill (explores requirements, presents incremental design)
- For implementation planning: Use `/writing-plans` skill (creates detailed step-by-step plan)
- For TDD: Use `/test-driven-development` skill (enforces test-first discipline)

## Scope Control (CRITICAL)
- Implement ONLY what's explicitly requested
- No "helpful" additions: refactoring, extra tests, documentation updates, or code cleanup
- No "while I'm here" changes
- When tempted to do extra work: ask "Should I also...?" instead
- Before presenting solution: verify each change was explicitly requested

## Git
- Commit only when explicitly requested
- Use conventional commit format (feat:, fix:, docs:, refactor:)
- Focus commit messages on "what" and "why"
- Omit Co-Authored-By lines from commit messages

## Code Output
- Exclude comments, docstrings, and type annotations unless requested
- Flag security vulnerabilities immediately
- Use secure patterns: parameterized queries, boundary validation
- Exclude secrets from commits (.env, credentials, API keys)

## Batch Operations (CRITICAL)

For bulk changes (translations, formatting, mass refactoring):
- Read ENTIRE file content first (one Read operation)
- Process ALL changes in memory (single operation)
- Write complete result in ONE Write operation
- NEVER use sequential Edit operations

Examples:
- Translation: Read → translate all in memory → Write (1 operation)
- Formatting: Read → format all in memory → Write (1 operation)
- Refactoring: Read → refactor all in memory → Write (1 operation)

❌ WRONG: 26+ Edit calls for translation
✅ CORRECT: 1 Read → process → 1 Write

**Key Principle**: Batch operations = Read Once + Write Once, never sequential edits

## Database Operations
- Use context7 to query database-specific syntax (VARCHAR/String handling varies by database)
- Don't assume PostgreSQL/MySQL patterns apply universally
- Detailed workflow: `/guide database-mcp`

## Testing Requirements
- Match exact exception types from production code
  - Verify imports (RpcError vs AioRpcError)
  - Check exception attributes exist (_debug_error_string, etc.)
- Match existing test patterns:
  - Read similar test files first
  - Use same mock object patterns
  - Follow same assertion style
- Run tests before claiming success: pytest tests/ -v
- For retry/error handling logic: test with actual production exception types

## Tool Selection
1. File operations: Read, Edit, mgrep, Glob (not bash)
2. Web search: mgrep --web preferred, WebSearch as fallback
3. Documentation lookup: context7 MCP server
4. Parallelize independent operations
5. Read files before editing

## Response Style
- Concise: omit filler and unnecessary explanation
- Factual: prioritize accuracy over agreement
- Plain text: omit emojis unless requested

## Plugin Ecosystem Integration

**Reference**: Use `/guide plugins` for complete plugin list and decision tree, `/guide workflow` for workflow patterns
