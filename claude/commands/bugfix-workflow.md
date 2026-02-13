---
description: "End-to-end bugfix: diagnose → plan (optional) → fix → review → ship"
argument-hint: "Bug description (e.g., 'Empty email accepted in registration form' or 'API returns 500 on concurrent requests')"
---

# Bugfix Workflow

You are orchestrating a complete bugfix pipeline. Execute the phases below in order. Each phase uses a specific skill — invoke it via the Skill tool and follow it exactly.

**Bug report:** $ARGUMENTS

## Document Output

Plans (if written) are saved outside the project repo:

```
DOCS_ROOT = ~/Documents/second-brain/jobs/{project_name}
```

`{project_name}` is derived from `basename $(git rev-parse --show-toplevel)`. If `DOCS_ROOT` does not exist, inform the user and ask whether to create it or specify an alternative path.

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

## Phase 2: Worktree Setup

Use AskUserQuestion to ask:
- Question: "Create a git worktree for isolated development?"
- Options: "Skip — work on current branch" (first/default), "Create worktree"

- **If skip:** Continue on the current branch.
- **If create worktree:** Invoke Skill `superpowers:using-git-worktrees`. Follow the skill exactly.

Announce: **"Phase 2 complete. Moving to Phase 3."**

---

## Phase 3: Plan (conditional)

**If user chose "Simple fix" in Phase 1:** Skip this phase entirely. Announce: **"Phase 3 skipped — simple fix. Moving to Phase 4."**

**If user chose "Complex fix" in Phase 1:**

Invoke Skill `superpowers:writing-plans`.

Follow the skill exactly. It will:
- Create a detailed implementation plan based on the Phase 1 diagnosis
- Structure tasks with TDD steps (write test → verify fail → implement → verify pass → commit)
- Save the plan to `DOCS_ROOT/YYYY-MM-DD-<bug-summary>.md`
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
1. Plan file is saved to `DOCS_ROOT`
2. TodoWrite records: root cause, worktree choice, execution mode choice, current phase

Then suggest: **"The diagnosis and planning phases used significant context. Consider running `/compact` now — all decisions are persisted in TodoWrite and DOCS_ROOT. After compact, I'll recover context by reading those files."**

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

### Step 1: Verification Loop

Invoke Skill `verification-loop`.

Follow the skill exactly — run all 6 verification phases (build, types, lint, tests, security, diff) and produce the VERIFICATION REPORT.

If any phase fails, fix issues before proceeding.

### Step 2: Security Review

Invoke Skill `everything-claude-code:security-review`.

Follow the skill exactly — run through the security checklist relevant to the changes made.

Fix any critical security issues found.

### Step 3: Code Review

Invoke Skill `superpowers:requesting-code-review`.

Follow the skill exactly — dispatch the code-reviewer subagent to review the fix against the root cause diagnosis (and plan, if one was written).

Fix any Critical or Important issues found.

### Gate

Use AskUserQuestion to confirm:
- Question: "Verification, security review, and code review complete. Ship this fix?"
- Options: "Continue to ship", "Fix issues first", "Stop workflow"

If "Fix issues first": address remaining issues, then re-run the failing verification steps.
If "Stop workflow": end here.

### Step 4: Update Project Context

If the fix revealed undocumented architectural patterns, failure modes, or conventions worth recording, update the project's CLAUDE.md to reflect them. Only update sections that are factually outdated — do not rewrite unchanged sections.

Announce: **"Phase 5 complete — verified and reviewed. Moving to Phase 6."**

---

## Phase 6: Ship

Invoke Skill `superpowers:finishing-a-development-branch`.

Follow the skill exactly. It will:
1. Verify tests pass
2. Present 4 options: merge locally / push + PR / keep as-is / discard
3. Execute the chosen option
4. Clean up worktree if applicable

Announce: **"Bugfix workflow complete."**
