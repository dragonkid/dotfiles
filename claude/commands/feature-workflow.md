---
description: "End-to-end feature development: brainstorm → plan → implement → review → ship"
argument-hint: "Feature description (e.g., 'Add OAuth2 login with JWT refresh tokens')"
---

# Feature Workflow

You are orchestrating a complete feature development pipeline. Execute the phases below in order. Each phase uses a specific skill — invoke it via the Skill tool and follow it exactly.

**Feature request:** $ARGUMENTS

## Document Output

All design documents and implementation plans are saved in the project repo:

```
DOCS_ROOT = .plan/
```

If `.plan/` does not exist, create it (`mkdir -p .plan`).

### Vault Sync

After creating or updating any document in `DOCS_ROOT`, ask:
- Question: "同步此文档到 Obsidian vault？"
- Options: "Yes — sync to vault", "No — skip"

If yes: copy the file to `~/Documents/second-brain/Jobs/{project_name}/` where `{project_name}` is derived from `basename $(git rev-parse --show-toplevel)`. Create the directory if it doesn't exist.

---

## Phase 1: Brainstorm (skippable)

Use AskUserQuestion to ask:
- Question: "How would you like to start?"
- Options: "Brainstorm from scratch", "I have a design — skip to planning"

### If brainstorming:

Invoke Skill `superpowers:brainstorming` with the feature request above as context.

**Context hint:** Project architecture and conventions are already loaded from the project's CLAUDE.md. Use that as your starting point — only explore areas where CLAUDE.md lacks sufficient detail for the feature.

Follow the skill exactly. It will:
- Explore the codebase and ask questions one at a time
- Propose 2-3 approaches with trade-offs
- Present the design in sections for incremental validation
- Write the validated design to `.plan/YYYY-MM-DD-<topic>-design.md`

When brainstorming completes and the design document is saved, announce:
**"Phase 1 complete — design document saved. Moving to Phase 2."**

### If skipping:

Ask the user for the design document path or description, then proceed directly to Phase 2.

---

## Phase 2: Branch Setup

Use AskUserQuestion to ask:
- Question: "How to isolate this feature work?"
- Options: "Create feature branch (Recommended)", "Create worktree"

### If feature branch:

Create and switch to a new branch from the current HEAD:

```bash
# Derive branch name from feature request (kebab-case, max 50 chars)
# e.g., "Add OAuth2 login" → feat/add-oauth2-login
git checkout -b feat/<feature-slug>
```

Record `BRANCH_MODE=branch` and the base branch name (the branch you were on before switching) for Phase 6.

### If worktree:

Invoke Skill `superpowers:using-git-worktrees`. Follow the skill exactly.

Record `BRANCH_MODE=worktree` for Phase 6.

Announce: **"Phase 2 complete. Moving to Phase 3."**

---

## Phase 3: Plan

Invoke Skill `superpowers:writing-plans`.

Follow the skill exactly. It will:
- Create a detailed implementation plan based on the Phase 1 design
- Structure tasks with TDD steps (write test → verify fail → implement → verify pass → commit)
- Save the plan to `.plan/YYYY-MM-DD-<feature-name>.md`
- Present the execution mode choice at the end:
  1. **Subagent-Driven** (this session) — fresh subagent per task with two-stage review
  2. **Parallel Session** (separate session) — batch execution with checkpoints

Use AskUserQuestion to confirm:
- Question: "Plan is ready. Proceed to implementation?"
- Options: "Start implementation", "Revise plan", "Stop workflow"

If "Revise plan": go back to writing-plans skill to iterate.
If "Stop workflow": end here.

Remember the user's execution mode choice for Phase 4.

### Context Protection & Compact

Before suggesting compact, ensure:
1. Design document and plan file are saved to `.plan/`
2. TodoWrite records: BRANCH_MODE (branch/worktree), base branch name, execution mode choice, current phase

Then suggest: **"The brainstorm and planning phases used significant context. Consider running `/compact` now — all decisions are persisted in .plan/ and TodoWrite. After compact, I'll recover context by reading those files."**

Announce: **"Phase 3 complete — plan saved. Moving to Phase 4."**

---

## Phase 4: Implement

Based on the execution mode chosen in Phase 3:

- **If Subagent-Driven:** Invoke Skill `superpowers:subagent-driven-development`. Follow the skill exactly.
- **If Parallel Session:** Invoke Skill `superpowers:executing-plans`. Follow the skill exactly.

**Important:** Both skills will attempt to invoke `superpowers:finishing-a-development-branch` at the end. Do NOT follow that final step — instead proceed to Phase 5.

### Context Protection & Compact

Before suggesting compact, ensure:
1. TodoWrite has all task statuses updated
2. Note the base branch name for later use

Then suggest: **"Implementation complete. Consider running `/compact` before verification — progress is tracked in TodoWrite and git history. After compact, I'll recover context from TodoWrite + git log + .plan/."**

Announce: **"Phase 4 complete — implementation done. Moving to Phase 5."**

---

## Phase 5: Verify & Review

### Step 1: Scope Analysis — Determine Review Matrix

Before dispatching any reviewers, analyze the change scope to build the full review list.

```bash
# Collect scope signals (run in main session, fast)
BASE=$(git merge-base HEAD <BASE_BRANCH>)
CHANGED_DIRS=$(git diff --name-only $BASE..HEAD | cut -d/ -f1-2 | sort -u | wc -l)
HAS_GO=$(test -f go.mod && echo yes || echo no)
HAS_PYTHON=$(test -f pyproject.toml -o -f setup.py -o -f requirements.txt && echo yes || echo no)
TESTS_CHANGED=$(git diff --name-only $BASE..HEAD | grep -c '_test\.\|\.test\.\|test_\|_spec\.' || true)
```

**Replace `<BASE_BRANCH>`** with the actual base branch name recorded in Phase 2.

Build the agent list:

| Agent | Condition | Always/Conditional |
|-------|-----------|-------------------|
| Verification loop | Always | Always |
| Security review | Always | Always |
| Code review | Always | Always |
| Architecture review | CHANGED_DIRS >= 3 | Conditional |
| Go review | HAS_GO = yes | Conditional |
| Python review | HAS_PYTHON = yes | Conditional |
| Test coverage analysis | TESTS_CHANGED > 0 or no tests exist for changed code | Conditional |

Announce which agents will be dispatched (e.g., "Dispatching 5 parallel reviewers: verification, security, code, architecture, test coverage").

### Step 2: Dispatch All Reviews in Parallel

Dispatch every agent from the matrix in a **single parallel batch**:

**Always:**
```
Agent(description="Run verification loop",
      subagent_type="general-purpose",
      prompt="Run the verification loop for this project.
        Invoke Skill `verification-loop`. Follow it exactly — run all 6 phases
        (build, types, lint, tests, security, diff). Return the full VERIFICATION REPORT
        with PASS/FAIL for each phase.")

Agent(description="Run security review",
      subagent_type="everything-claude-code:security-reviewer",
      prompt="Security review on this branch's changes.
        Use `git diff $(git merge-base HEAD <BASE_BRANCH>)..HEAD` to scope changes.
        Focus on: hardcoded secrets, input validation, injection, auth/authz, OWASP Top 10.
        Return structured findings with severity levels.")

Agent(description="Run code review",
      subagent_type="superpowers:code-reviewer",
      prompt="Review the implementation on this branch against the plan.
        Use `git diff $(git merge-base HEAD <BASE_BRANCH>)..HEAD` for all changes.
        Read the plan from .plan/ directory for context.
        Evaluate: correctness, plan alignment, code quality, test coverage.
        Return findings as Critical / Important / Minor.")
```

**Conditional (include only if condition met):**
```
Agent(description="Run architecture review",
      subagent_type="everything-claude-code:architect",
      prompt="Architecture review of this branch's changes.
        Use `git diff $(git merge-base HEAD <BASE_BRANCH>)..HEAD` for all changes.
        Evaluate: module boundaries, coupling direction, dependency hygiene,
        interface design, separation of concerns.
        Return findings as Critical / Important / Minor.")

Agent(description="Run Go review",
      subagent_type="everything-claude-code:go-reviewer",
      prompt="Go-specific review of this branch's changes.
        Run go vet, staticcheck. Check for: idiomatic Go, concurrency safety,
        error wrapping, race conditions, goroutine leaks.
        Return findings as Critical / Important / Minor.")

Agent(description="Run Python review",
      subagent_type="everything-claude-code:python-reviewer",
      prompt="Python-specific review of this branch's changes.
        Run ruff, mypy, bandit. Check for: PEP 8, type hints, Pythonic idioms,
        security, mutable defaults, bare excepts.
        Return findings as Critical / Important / Minor.")

Agent(description="Run test coverage analysis",
      subagent_type="pr-review-toolkit:pr-test-analyzer",
      prompt="Analyze test coverage quality for this branch's changes.
        Use `git diff $(git merge-base HEAD <BASE_BRANCH>)..HEAD` for all changes.
        Focus on: behavioral coverage (not line coverage), critical gaps,
        test-vs-implementation coupling. Rate criticality 1-10.
        Return findings with gap descriptions.")
```

### Step 3: Collect and Act on Findings

When all agents return, consolidate results into a summary table:

```
| Agent              | Status | Critical | Important | Minor |
|--------------------|--------|----------|-----------|-------|
| Verification       | PASS   | 0        | -         | -     |
| Security           | PASS   | 0        | 1         | 2     |
| Code Review        | PASS   | 0        | 2         | 3     |
| Architecture       | PASS   | 0        | 0         | 1     |
| ...                |        |          |           |       |
```

**Fix priority:** Critical (all agents) > Important (all agents) > Minor (skip unless trivial).

If fixes were needed, re-run only the affected agent(s) to confirm.

### Step 4: Update Project Docs

Check if the following files need updates based on the changes made:
- **CLAUDE.md**: New modules, patterns, commands, or architectural changes
- **README.md**: New features, usage examples, configuration options, API endpoints
- **Makefile**: New commands, updated targets, new dependencies
- **Install scripts**: New dependencies, setup steps, environment variables
- **Other project docs**: CHANGELOG, API docs, deployment guides, docker-compose, etc.

For each file: read current content, compare against actual changes, update only what is factually outdated or missing. Do not rewrite unchanged sections.

### Gate

Use AskUserQuestion to confirm:
- Question: "All reviews complete. Ship this feature?"
- Options: "Continue to ship", "Fix issues first", "Stop workflow"

If "Fix issues first": address remaining issues, then re-run the failing verification steps.
If "Stop workflow": end here.

### CHECKPOINT — Do NOT announce phase complete until ALL items are confirmed:
- [ ] Step 1: Scope analysis done, review matrix determined
- [ ] Step 2: All agents dispatched and returned
- [ ] Step 3: All Critical/Important findings resolved
- [ ] Step 4: Project docs checked and updated if needed
- [ ] Gate: User confirmed to ship

If any item is unchecked, go back and complete it now.

Announce: **"Phase 5 complete — verified and reviewed. Moving to Phase 6."**

---

## Phase 6: Ship

Invoke Skill `superpowers:finishing-a-development-branch`.

Follow the skill exactly. It will:
1. Verify tests pass
2. Present 4 options: merge locally / push + PR / keep as-is / discard
3. Execute the chosen option
4. Clean up worktree if applicable

**Default recommendation:** When presenting the 4 options, recommend "Push and create a Pull Request" as the default choice — this is the safest integration path since it allows code review before merging.

Announce: **"Feature workflow complete."**
