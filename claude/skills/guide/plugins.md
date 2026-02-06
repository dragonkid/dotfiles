# Complete Guide to 17-Plugin Ecosystem

## Quick Decision Tree

| I want to... | Use |
|--------------|-----|
| Design new feature | `/brainstorming` |
| Write implementation plan | `/writing-plans` |
| Start coding | `/test-driven-development` or `/tdd-workflow` |
| Debug issues | `/systematic-debugging` |
| Review code | `/requesting-code-review` or `/code-review` |
| Query database docs | context7 (resolve-library-id → query-docs) |
| Search web | `mgrep --web --answer "query"` |
| Search local code | `mgrep "term"` |
| Optimize database | `/postgres-patterns` or `/clickhouse-io` |
| Create frontend UI | `/frontend-design` |
| Commit code | `/commit` or `/commit-push-pr` |
| Technical research | `/research-staged` |

## Core Plugin Categories

### 1. Workflow Management (Superpowers - 13 skills)

Complete process support from design to delivery.

**Skills**:
- `/brainstorming` - Creative design exploration, requirements understanding
- `/writing-plans` - Create detailed implementation plans
- `/test-driven-development` - Enforce TDD workflow
- `/systematic-debugging` - Systematic debugging methodology
- `/requesting-code-review` - Request code review
- `/verification-before-completion` - Pre-completion verification
- `/using-git-worktrees` - Git worktree management
- `/executing-plans` - Execute implementation plans
- `/finishing-a-development-branch` - Finish development branch
- `/receiving-code-review` - Receive code review feedback
- `/writing-skills` - Write new skills
- `/dispatching-parallel-agents` - Parallel agent dispatching
- `/subagent-driven-development` - Subagent-driven development

### 2. Tech Stack Specialists (Everything-Claude-Code - 14 skills)

Best practices and pattern libraries for specific tech stacks.

**Skills**:
- `/postgres-patterns` - PostgreSQL/Supabase database patterns
- `/clickhouse-io` - ClickHouse analytical database
- `/frontend-patterns` - React/Next.js frontend patterns
- `/backend-patterns` - Node.js/Express backend patterns
- `/security-review` - Security review checklist
- `/coding-standards` - TypeScript/JavaScript coding standards
- `/tdd-workflow` - TDD workflow (80%+ coverage)
- `/continuous-learning` - Continuous learning pattern extraction
- `/continuous-learning-v2` - Instinct-based learning system
- `/iterative-retrieval` - Progressive context retrieval
- `/eval-harness` - Evaluation framework
- `/strategic-compact` - Strategic context compaction
- `/e2e` - Playwright E2E testing
- `/plan` - Implementation plan creation

### 3. Search & Documentation (mgrep + context7)

**mgrep commands**:
- `mgrep --web --answer "query"` - Web search with summarized answer
- `mgrep "search term"` - Local code semantic search

**context7 workflow**:
1. `resolve-library-id` - Find library's Context7 ID
2. `query-docs` - Query library docs and code examples

**Supported database documentation**:
- StarRocks: `/websites/starrocks_io`
- ClickHouse: `/clickhouse/clickhouse-docs`
- PostgreSQL, MySQL, and other mainstream databases

### 4. Code Quality Assurance

**Plugins**:
- **code-review** - `/code-review`
- **pr-review-toolkit** - PR review toolkit (multiple specialized agents)
- **code-simplifier** - Automatic code simplification
- **security-guidance** - Security reminder hooks
- **typescript-lsp** - TypeScript type checking
- **pyright-lsp** - Python type checking

### 5. Specialized Feature Plugins

**frontend-design**:
- `/frontend-design` - Generate high-quality, distinctive frontend interfaces
- Supports React, Vue, HTML/CSS

**commit-commands**:
- `/commit` - Create git commit
- `/commit-push-pr` - Commit and create PR
- `/clean_gone` - Clean up deleted remote branches

**hookify**:
- `/hookify` - Create hooks to prevent unwanted behaviors
- `/list` - List all hookify rules
- `/configure` - Configure hookify rules

**feature-dev**:
- `/feature-dev` - Feature development assistant

## Common Task Plugin Combinations

### Add User Authentication

```
1. /brainstorming → Confirm auth approach (JWT vs Session)
2. /security-review → Security checklist
3. /test-driven-development → TDD implementation
4. /verification-before-completion → Verification
5. /requesting-code-review → Review
```

### Database Performance Optimization

```
1. /postgres-patterns → Query optimization patterns
2. context7 query-docs → Query specific syntax
3. /test-driven-development → Test-driven optimization
```

### Create New API Endpoint

```
1. /brainstorming → Design API structure
2. /backend-patterns → API design best practices
3. /security-review → API security check
4. /test-driven-development → TDD implementation
```

### Frontend Component Development

```
1. /frontend-design → Generate component code
2. /frontend-patterns → Apply best practices
3. /test-driven-development → E2E testing
```

## Workflow Patterns

See `/guide workflow` for detailed workflow patterns.
