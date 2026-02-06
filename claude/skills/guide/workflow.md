# Workflow Optimization Guide

Optimization recommendations and best practices.

## Core Principles

### 1. Plan Before Implementation

**Rules**:
- Use explicit trigger words: "give me a plan", "design approach"
- Use `/brainstorming` skill for creative exploration
- Use `/writing-plans` skill for detailed planning

**Examples**:
```
❌ Wrong: "Help me add user authentication"
   → Starts implementing immediately

✅ Correct: "Give me a complete plan for adding user authentication"
   → Provides plan first, waits for approval

✅ Better: "/brainstorming user authentication feature"
   → Systematically explores requirements and design
```

### 2. Batch Operations

**Pattern**:
```
1. Read entire file (1 operation)
2. Process all changes in memory
3. Write complete result (1 operation)
```

**Apply to**:
- File translation
- Code formatting
- Bulk refactoring
- Large-scale find and replace

### 3. Staged Research

**Use `/research-staged` for research tasks**:
```
→ Stage 1: Scope Definition WAIT
→ Stage 2: Initial Survey WAIT
→ Stage 3: Deep Analysis WAIT
→ Stage 4: Documentation
```

### 4. Test-Driven Development

**Use TDD skills**:
- `/test-driven-development` (superpowers)
- `/tdd-workflow` (everything-claude-code)

**Workflow**:
1. Write tests (see them fail first)
2. Implement code
3. Tests pass
4. Refactor

### 5. Multi-Layer Code Review

**Review mechanisms**:
- `/requesting-code-review` (superpowers) - Request review
- `/code-review` (official plugin) - Execute review
- `pr-review-toolkit` - PR-specific review

### 6. Database Syntax Verification

**Rules**:
- Use `/postgres-patterns` or `/clickhouse-io` skills
- Use context7 to query database documentation
- Don't assume syntax compatibility across databases

## Daily Workflows

### Starting Work

```
1. Check TODO or issues
2. /brainstorming <feature>
3. /writing-plans
4. Start implementation after approval
```

### Implementing Features

```
1. /using-git-worktrees (create isolated environment)
2. /test-driven-development (TDD implementation)
3. /security-review (if sensitive features)
```

### Completing Work

```
1. /verification-before-completion
2. /requesting-code-review
3. /commit-push-pr
```

## Quick Reference

### When to use plan mode?

- Multi-file modifications
- Architecture changes
- >50 lines of code
- When unsure of best approach

### When to use skills?

Almost always! Skills provide structured processes.

### Efficiency rules

1. Use the right skill (don't do manually)
2. Batch operations use Read-Write pattern
3. Plan first, avoid rework
4. Use context7 to query docs instead of guessing

## Workflow Pattern Quick Reference

| Task Type | Recommended Workflow |
|-----------|---------------------|
| New feature development | brainstorming → writing-plans → test-driven-development → security-review → verification-before-completion → requesting-code-review → commit-push-pr |
| Database work | context7 resolve-library-id → query-docs → postgres-patterns/clickhouse-io → test-driven-development |
| Technical research | research-staged (4 stages) → mgrep --web --answer → document to Obsidian |
| Batch operations | Read entire file → process in memory → Write once |
| Frontend development | brainstorming → frontend-design → frontend-patterns → test-driven-development (E2E) |
