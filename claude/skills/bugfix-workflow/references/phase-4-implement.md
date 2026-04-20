# Phase 4: Implement

Read TodoWrite to recover: fix path (simple/complex), execution mode choice, branch mode and base branch.

## Simple Fix Path (fix_path=simple)

Invoke Skill `superpowers:test-driven-development` with the root cause context from TodoWrite.

Follow the TDD cycle exactly:
1. **RED:** Write a regression test that reproduces the bug. Run it — it should fail.
2. **GREEN:** Write the minimal fix to make the test pass. Run it — it should pass.
3. **REFACTOR:** Clean up if needed. All tests stay green.
4. **Commit** the regression test and fix.

If the fix is more involved than expected (touches 3+ files or requires architectural changes), pause and use AskUserQuestion:
- Question: "This fix is more complex than expected. Switch to planned approach?"
- Options: "Continue with TDD (Recommended)", "Switch to plan-first approach"

If "Switch to plan-first approach": Go to Phase 3 (write a plan), then return to Phase 4 with subagent-driven execution.

## Complex Fix Path (fix_path=complex)

### Execution Mode Gate (mandatory)

If the execution mode was NOT recorded in Phase 3 (e.g., because planning was skipped or the skill didn't present the choice), you MUST ask the user now via AskUserQuestion:
- Question: "选择实施模式？"
- Options: "Subagent-Driven (Recommended) — 每个 Task 由独立 subagent 执行，可并行处理，带 two-stage review", "Inline Execution — 在当前会话中顺序执行所有任务，每个 checkpoint 确认"

Record the choice in TodoWrite before proceeding. Do NOT assume a default — execution mode MUST be an explicit user choice.

Based on the execution mode chosen:

- **If Subagent-Driven:** Invoke Skill `superpowers:subagent-driven-development`. Follow the skill exactly.
- **If Inline Execution:** Invoke Skill `superpowers:executing-plans`. Follow the skill exactly.

**Important:** Both skills will attempt to invoke `superpowers:finishing-a-development-branch` at the end. Do NOT follow that final step — instead proceed to Phase 5.

## Context Protection & Compact

Before suggesting compact, ensure:
1. TodoWrite has all task statuses updated
2. Note the base branch name for later use

Then suggest: **"Implementation complete. Consider running `/compact` before verification — progress is tracked in TodoWrite and git history. After compact, I'll recover context from TodoWrite + git log."**

Announce: **"Phase 4 complete — fix implemented. Returning to state machine for Gate 4."**

Return to the state machine SKILL.md for Gate 4.
