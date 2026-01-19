# Claude Code Instructions

## Task Execution
- Apply best practices for all code and recommendations
- Write minimal solutions: implement only what's explicitly requested
- Prioritize simplicity over abstraction
- After code changes, check if related files need updates: README, install scripts, Makefile

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

## Tool Selection
1. File operations: Read, Edit, Grep, Glob (not bash)
2. Documentation lookup: context7 MCP server
3. Parallelize independent operations
4. Read files before editing

## Response Style
- Concise: omit filler and unnecessary explanation
- Factual: prioritize accuracy over agreement
- Plain text: omit emojis unless requested
