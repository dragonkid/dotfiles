# Phase 3: Plan

Read TodoWrite to recover: refactor_mode, test baseline, branch mode, base branch from previous phases.

**This phase only runs if `refactor_mode=complex`.**

## Step 0: Reuse Discovery

Before writing the plan, invoke Skill `everything-claude-code:search-first` with the refactoring goal as context. Feed findings into the plan — reference existing code rather than proposing new implementations of already-available functionality.

## Step 1: Write the Plan

Invoke Skill `superpowers:writing-plans`.

Follow the skill exactly. It will:
- Create a detailed refactoring plan with incremental steps
- Each step must preserve behavior — all existing tests pass after every step
- Save the plan to `docs/superpowers/plans/YYYY-MM-DD-<refactor-summary>.md`
- Present the execution mode choice at the end:
  1. **Subagent-Driven** (recommended) — fresh subagent per task with two-stage review
  2. **Inline Execution** — execute tasks in this session with checkpoints

Record the user's execution mode choice for Phase 4.

## Context Protection & Compact

Before suggesting compact, ensure:
1. Plan file is saved to `docs/superpowers/`
2. TodoWrite records: test baseline, affected files, BRANCH_MODE (branch/worktree), base branch name, execution mode choice, current phase

Then suggest: **"The scope analysis and planning phases used significant context. Consider running `/compact` now — all decisions are persisted in TodoWrite and docs/superpowers/. After compact, I'll recover context by reading those files."**

Announce: **"Phase 3 complete — plan saved. Returning to state machine for Gate 3."**

Return to the state machine SKILL.md for Gate 3.
