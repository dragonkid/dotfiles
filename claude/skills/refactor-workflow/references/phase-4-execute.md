# Phase 4: Execute

Read TodoWrite to recover: refactor_mode, execution_mode, test baseline, branch mode, base branch from previous phases.

## Simple Refactor Path (`refactor_mode=simple`)

Execute the refactoring incrementally:
1. Make one structural change at a time
2. After each change, run the full test suite — all existing tests must pass
3. If any test fails, revert the last change and rethink the approach
4. Commit after each successful step

If the refactoring is more involved than expected (touches 5+ files or requires interface changes), pause and use AskUserQuestion to ask:
- Question: "This refactor is more complex than expected. Switch to planned approach?"
- Options: "Continue incrementally (Recommended)", "Switch to plan-first approach"

If "Switch to plan-first approach": Go to Phase 3 (write a plan), then return to Phase 4 with subagent-driven execution.

## Complex Refactor Path (`refactor_mode=complex`)

### Execution Mode Gate (mandatory)

If the execution mode was NOT recorded in Phase 3 (e.g., because planning was skipped or the skill didn't present the choice), you MUST ask the user now via AskUserQuestion:
- Question: "选择实施模式？"
- Options: "Subagent-Driven (Recommended) — 每个 Task 由独立 subagent 执行，可并行处理，带 two-stage review", "Inline Execution — 在当前会话中顺序执行所有任务，每个 checkpoint 确认"

Record the choice in TodoWrite before proceeding. Do NOT assume a default — execution mode MUST be an explicit user choice.

Based on the execution mode chosen:

- **If Subagent-Driven:** Invoke Skill `superpowers:subagent-driven-development`. Follow the skill exactly.
- **If Inline Execution:** Invoke Skill `superpowers:executing-plans`. Follow the skill exactly.

**Important:** Both skills will attempt to invoke `superpowers:finishing-a-development-branch` at the end. Do NOT follow that final step — instead return to the state machine for Gate 4.

## Context Protection & Compact

Before suggesting compact, ensure:
1. TodoWrite has all task statuses updated
2. Note the base branch name for later use

Then suggest: **"Refactoring complete. Consider running `/compact` before cleanup and verification — progress is tracked in TodoWrite and git history. After compact, I'll recover context from TodoWrite + git log."**

Announce: **"Phase 4 complete — refactoring done. Returning to state machine for Gate 4."**

Return to the state machine SKILL.md for Gate 4.
