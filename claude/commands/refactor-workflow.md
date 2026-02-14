---
description: "End-to-end refactoring: scope analysis → baseline → plan (optional) → execute → cleanup → review → ship"
argument-hint: "Refactoring goal (e.g., 'Extract auth logic into separate module' or 'Reduce coupling between order and payment services')"
---

# Refactor Workflow

You are orchestrating a complete refactoring pipeline. The core constraint: **behavior must not change — only structure improves.** Execute the phases below in order. Each phase uses a specific skill — invoke it via the Skill tool and follow it exactly.

**Refactoring goal:** $ARGUMENTS

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

## Phase 1: Scope & Baseline

### Step 1: Discover Affected Code

**Context hint:** Project architecture and conventions are already loaded from the project's CLAUDE.md. Use that as your starting point — only explore areas where CLAUDE.md lacks sufficient detail for the refactoring.

Invoke Skill `everything-claude-code:iterative-retrieval` with the refactoring goal above as context.

Follow the skill exactly — progressively refine searches (max 3 cycles) to find all files and dependencies affected by this refactoring: target files, consumers, related tests, downstream imports.

### Step 2: Establish Test Baseline

Run the project's existing test suite and record the baseline:
- Total tests and pass count
- Coverage percentage (if available)
- Build status

If test coverage for the affected code is insufficient (key paths untested), invoke Skill `superpowers:test-driven-development` to write characterization tests that capture the current behavior before any structural changes.

**Critical:** All existing tests must pass before proceeding. If any fail, fix them first — do not refactor broken code.

### Step 3: Record Baseline

Record the following in TodoWrite:
- Test baseline (pass count, coverage %)
- Affected files and their dependents
- Current code smells or structural issues identified

Then use AskUserQuestion to ask:
- Question: "Scope analysis complete. How should we proceed?"
- Options: "Simple refactor — proceed directly" (first/default), "Complex refactor — write a plan first", "Brainstorm refactoring approaches", "Stop workflow"

**If "Simple refactor":** Skip Phase 3. Proceed to Phase 2, then Phase 4.
**If "Complex refactor":** Proceed to Phase 2, then Phase 3 (plan), then Phase 4.
**If "Brainstorm refactoring approaches":** Invoke Skill `superpowers:brainstorming` with the scope analysis context. When brainstorming completes, return to this gate and ask again (excluding the brainstorm option).
**If "Stop workflow":** End here.

Remember the user's choice for Phase 4.

Announce: **"Phase 1 complete — scope analyzed and baseline established. Moving to Phase 2."**

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

**If user chose "Simple refactor" in Phase 1:** Skip this phase entirely. Announce: **"Phase 3 skipped — simple refactor. Moving to Phase 4."**

**If user chose "Complex refactor" in Phase 1:**

Invoke Skill `superpowers:writing-plans`.

Follow the skill exactly. It will:
- Create a detailed refactoring plan with incremental steps
- Each step must preserve behavior — all existing tests pass after every step
- Save the plan to `.plan/YYYY-MM-DD-<refactor-summary>.md`
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
2. TodoWrite records: test baseline, affected files, execution mode choice, current phase

Then suggest: **"The scope analysis and planning phases used significant context. Consider running `/compact` now — all decisions are persisted in TodoWrite and .plan/. After compact, I'll recover context by reading those files."**

Announce: **"Phase 3 complete — plan saved. Moving to Phase 4."**

---

## Phase 4: Execute

### Simple Refactor Path (user chose "Simple refactor" in Phase 1)

Execute the refactoring incrementally:
1. Make one structural change at a time
2. After each change, run the full test suite — all existing tests must pass
3. If any test fails, revert the last change and rethink the approach
4. Commit after each successful step

If the refactoring is more involved than expected (touches 5+ files or requires interface changes), pause and ask:
- Question: "This refactor is more complex than expected. Switch to planned approach?"
- Options: "Continue incrementally" (first/default), "Switch to plan-first approach"

If "Switch to plan-first approach": Go to Phase 3 (write a plan), then return to Phase 4 with subagent-driven execution.

### Complex Refactor Path (user chose "Complex refactor" in Phase 1)

Based on the execution mode chosen in Phase 3:

- **If Subagent-Driven:** Invoke Skill `superpowers:subagent-driven-development`. Follow the skill exactly.
- **If Parallel Session:** Invoke Skill `superpowers:executing-plans`. Follow the skill exactly.

**Important:** Both skills will attempt to invoke `superpowers:finishing-a-development-branch` at the end. Do NOT follow that final step — instead proceed to Phase 5.

### Context Protection & Compact

Before suggesting compact, ensure:
1. TodoWrite has all task statuses updated
2. Note the base branch name for later use

Then suggest: **"Refactoring complete. Consider running `/compact` before cleanup and verification — progress is tracked in TodoWrite and git history. After compact, I'll recover context from TodoWrite + git log."**

Announce: **"Phase 4 complete — refactoring done. Moving to Phase 5."**

---

## Phase 5: Cleanup

Use the Task tool to dispatch the `refactor-cleaner` agent:

```
Task(subagent_type="refactor-cleaner", prompt="Analyze the codebase for dead code, unused exports, and unused dependencies created by the recent refactoring. Follow your safety checklist: grep for references, check dynamic imports, review git history, and test after each removal batch.")
```

Review the agent's findings. If it identifies safe removals, let it proceed. For risky removals, verify manually before approving.

Announce: **"Phase 5 complete — cleanup done. Moving to Phase 6."**

---

## Phase 6: Verify & Review

### Step 1: Verification Loop

Invoke Skill `verification-loop`.

Follow the skill exactly — run all 6 verification phases (build, types, lint, tests, security, diff) and produce the VERIFICATION REPORT.

**Critical for refactoring:** Compare test results against the Phase 1 baseline recorded in TodoWrite. All previously passing tests must still pass. Coverage must not decrease.

If any phase fails, fix issues before proceeding.

### Step 2: Security Review

Invoke Skill `everything-claude-code:security-review`.

Follow the skill exactly — run through the security checklist relevant to the changes made.

Fix any critical security issues found.

### Step 3: Code Review

Invoke Skill `superpowers:requesting-code-review`.

Follow the skill exactly — dispatch the code-reviewer subagent to review the refactoring. The review should confirm:
- Behavior is preserved (no functional changes)
- Code quality has improved (the refactoring achieved its goal)
- No regressions introduced

Fix any Critical or Important issues found.

### Gate

Use AskUserQuestion to confirm:
- Question: "Verification, security review, and code review complete. Ship this refactor?"
- Options: "Continue to ship", "Fix issues first", "Stop workflow"

If "Fix issues first": address remaining issues, then re-run the failing verification steps.
If "Stop workflow": end here.

### Step 4: Update Project Context

If the refactoring changed module boundaries, file organization, or architectural patterns documented in the project's CLAUDE.md, update it to reflect the new structure. Only update sections that are factually outdated — do not rewrite unchanged sections.

Announce: **"Phase 6 complete — verified and reviewed. Moving to Phase 7."**

---

## Phase 7: Ship

Invoke Skill `superpowers:finishing-a-development-branch`.

Follow the skill exactly. It will:
1. Verify tests pass
2. Present 4 options: merge locally / push + PR / keep as-is / discard
3. Execute the chosen option
4. Clean up worktree if applicable

Announce: **"Refactor workflow complete."**
