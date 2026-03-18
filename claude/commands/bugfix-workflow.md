---
description: "End-to-end bugfix: diagnose → plan (optional) → fix → review → ship"
argument-hint: "Bug description (e.g., 'Empty email accepted in registration form' or 'API returns 500 on concurrent requests')"
---

# Bugfix Workflow

You are orchestrating a complete bugfix pipeline. Execute the phases below in order. Each phase uses a specific skill — invoke it via the Skill tool and follow it exactly.

**Bug report:** $ARGUMENTS

## Document Output

Plans (if written) are saved in the project repo:

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

## Phase 1: Diagnose

### Step 1: Gather Context

**Context hint:** Project architecture and conventions are already loaded from the project's CLAUDE.md. Use that as your starting point — only explore areas where CLAUDE.md lacks sufficient detail for the bug.

Invoke Skill `everything-claude-code:iterative-retrieval` with the bug report above as context.

Follow the skill exactly — progressively refine searches (max 3 cycles) to find the relevant code paths, files, and dependencies related to the bug.

### Step 2: Root Cause Analysis

Invoke Skill `superpowers:systematic-debugging` with the bug report and gathered context.

Follow the skill exactly. It will:
- Investigate root cause before proposing any fix
- Analyze patterns by comparing working vs broken code
- Form and test hypotheses with minimal changes
- Identify the root cause and affected code paths

The skill has built-in gates: no fixes before root cause investigation is complete. If 3+ fix attempts fail, the skill will stop and discuss architecture.

When diagnosis completes, record the following in TodoWrite:
- Root cause description (1-2 sentences)
- Affected files and code paths
- Confirmed hypothesis

Then use AskUserQuestion to ask:
- Question: "Root cause identified. How should we proceed?"
- Options: "Simple fix — proceed to TDD" (first/default), "Complex fix — write a plan first", "Brainstorm fix approaches", "Stop workflow"

**If "Simple fix":** Skip Phase 3. Proceed to Phase 2, then Phase 4 (TDD).
**If "Complex fix":** Proceed to Phase 2, then Phase 3 (plan), then Phase 4 (subagent-driven).
**If "Brainstorm fix approaches":** Invoke Skill `superpowers:brainstorming` with the root cause context. When brainstorming completes, return to this gate and ask again (excluding the brainstorm option).
**If "Stop workflow":** End here.

Remember the user's choice for Phase 4.

Announce: **"Phase 1 complete — root cause identified. Moving to Phase 2."**

---

## Phase 2: Branch Setup

Use AskUserQuestion to ask:
- Question: "How to isolate this bugfix work?"
- Options: "Create fix branch (Recommended)", "Create worktree"

### If fix branch:

Create and switch to a new branch from the current HEAD:

```bash
# Derive branch name from bug report (kebab-case, max 50 chars)
# e.g., "Empty email accepted" → fix/empty-email-accepted
git checkout -b fix/<bug-slug>
```

Record `BRANCH_MODE=branch` and the base branch name (the branch you were on before switching) for Phase 6.

### If worktree:

Invoke Skill `superpowers:using-git-worktrees`. Follow the skill exactly.

Record `BRANCH_MODE=worktree` for Phase 6.

Announce: **"Phase 2 complete. Moving to Phase 3."**

---

## Phase 3: Plan (conditional)

**If user chose "Simple fix" in Phase 1:** Skip this phase entirely. Announce: **"Phase 3 skipped — simple fix. Moving to Phase 4."**

**If user chose "Complex fix" in Phase 1:**

### Step 0: Reuse Discovery

Before writing the plan, scan the codebase for existing utilities, helpers, and patterns that the fix could leverage — this prevents the plan from proposing new code that duplicates what already exists.

Dispatch a Task agent:

```
Agent(description="Scan for reusable code",
      subagent_type="general-purpose",
      prompt="Search the codebase for existing utilities, helpers, shared modules,
        and established patterns relevant to this bug fix: [root cause description].
        Look in: utility directories, shared modules, files adjacent to the
        affected code paths, and common helper locations.
        For each finding, report: file path, function/module name, what it does,
        and how it could apply to the fix.
        Return a structured list of reusable code.")
```

Feed these findings into the plan — reference existing code rather than proposing new implementations of already-available functionality.

### Step 1: Write the Plan

Invoke Skill `superpowers:writing-plans`.

Follow the skill exactly. It will:
- Create a detailed implementation plan based on the Phase 1 diagnosis
- Structure tasks with TDD steps (write test → verify fail → implement → verify pass → commit)
- Save the plan to `.plan/YYYY-MM-DD-<bug-summary>.md`
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
1. Plan file is saved to `.plan/`
2. TodoWrite records: root cause, BRANCH_MODE (branch/worktree), base branch name, execution mode choice, current phase

Then suggest: **"The diagnosis and planning phases used significant context. Consider running `/compact` now — all decisions are persisted in TodoWrite and .plan/. After compact, I'll recover context by reading those files."**

Announce: **"Phase 3 complete — plan saved. Moving to Phase 4."**

---

## Phase 4: Implement

### Simple Fix Path (user chose "Simple fix" in Phase 1)

Invoke Skill `superpowers:test-driven-development` with the root cause context from TodoWrite.

Follow the TDD cycle exactly:
1. **RED:** Write a regression test that reproduces the bug. Run it — it should fail.
2. **GREEN:** Write the minimal fix to make the test pass. Run it — it should pass.
3. **REFACTOR:** Clean up if needed. All tests stay green.
4. **Commit** the regression test and fix.

If the fix is more involved than expected (touches 3+ files or requires architectural changes), pause and ask:
- Question: "This fix is more complex than expected. Switch to planned approach?"
- Options: "Continue with TDD" (first/default), "Switch to plan-first approach"

If "Switch to plan-first approach": Go to Phase 3 (write a plan), then return to Phase 4 with subagent-driven execution.

### Complex Fix Path (user chose "Complex fix" in Phase 1)

Based on the execution mode chosen in Phase 3:

- **If Subagent-Driven:** Invoke Skill `superpowers:subagent-driven-development`. Follow the skill exactly.
- **If Parallel Session:** Invoke Skill `superpowers:executing-plans`. Follow the skill exactly.

**Important:** Both skills will attempt to invoke `superpowers:finishing-a-development-branch` at the end. Do NOT follow that final step — instead proceed to Phase 5.

### Context Protection & Compact

Before suggesting compact, ensure:
1. TodoWrite has all task statuses updated
2. Note the base branch name for later use

Then suggest: **"Implementation complete. Consider running `/compact` before verification — progress is tracked in TodoWrite and git history. After compact, I'll recover context from TodoWrite + git log."**

Announce: **"Phase 4 complete — fix implemented. Moving to Phase 5."**

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
| Simplify review | Always | Always |
| Architecture review | CHANGED_DIRS >= 3 | Conditional |
| Go review | HAS_GO = yes | Conditional |
| Python review | HAS_PYTHON = yes | Conditional |
| Test coverage analysis | TESTS_CHANGED > 0 or no tests exist for changed code | Conditional |

Announce which agents will be dispatched.

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
      prompt="Review the fix on this branch against the root cause diagnosis.
        Use `git diff $(git merge-base HEAD <BASE_BRANCH>)..HEAD` for all changes.
        Read the plan from .plan/ directory and root cause from TodoWrite for context.
        Evaluate: correctness, root cause addressed, no regressions, code quality.
        Return findings as Critical / Important / Minor.")

Agent(description="Run simplify review",
      subagent_type="general-purpose",
      prompt="Review-only simplify analysis on this branch's changes.
        Use `git diff $(git merge-base HEAD <BASE_BRANCH>)..HEAD` to scope changes.
        Analyze three dimensions:
        1. CODE REUSE: Search for existing utilities/helpers in the codebase that could
           replace newly written code. Flag duplicated functionality and inline logic
           that has existing helpers.
        2. CODE QUALITY: Check for redundant state, parameter sprawl, copy-paste with
           slight variation, leaky abstractions, stringly-typed code, unnecessary nesting.
        3. EFFICIENCY: Check for unnecessary work (redundant computations, duplicate API
           calls, N+1 patterns), missed concurrency, hot-path bloat, recurring no-op
           updates, unbounded data structures, overly broad operations.
        IMPORTANT: Report findings ONLY — do NOT modify any code.
        Return findings as Critical / Important / Minor for each dimension.")
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
| ...                |        |          |           |       |
```

**Fix priority:** Critical (all agents) > Important (all agents) > Minor (skip unless trivial).

If fixes were needed, re-run only the affected agent(s) to confirm.

### Step 4: Update Project Docs

Check if the following files need updates based on the changes made:
- **CLAUDE.md**: New patterns, failure modes, or conventions discovered during the fix
- **README.md**: New features, usage examples, configuration options, API endpoints
- **Makefile**: New commands, updated targets, new dependencies
- **Install scripts**: New dependencies, setup steps, environment variables
- **Other project docs**: CHANGELOG, API docs, deployment guides, docker-compose, etc.

For each file: read current content, compare against actual changes, update only what is factually outdated or missing. Do not rewrite unchanged sections.

### Gate

Use AskUserQuestion to confirm:
- Question: "All reviews complete. Ship this fix?"
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

Announce: **"Bugfix workflow complete."**
