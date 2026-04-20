# Phase 3: Implement

Read TodoWrite to recover: execution mode choice from Phase 2, branch mode and base branch from Phase 1.

## Execution Mode Gate (mandatory)

If the execution mode was NOT recorded in Phase 2 (e.g., because brainstorming/writing-plans was skipped or the skill didn't present the choice), you MUST ask the user now via AskUserQuestion:
- Question: "选择实施模式？"
- Options: "Subagent-Driven (Recommended) — 每个 Task 由独立 subagent 执行，可并行处理，带 two-stage review", "Inline Execution — 在当前会话中顺序执行所有任务，每个 checkpoint 确认"

Record the choice in TodoWrite before proceeding. Do NOT assume a default — execution mode MUST be an explicit user choice.

## Execute

Based on the execution mode chosen:

- **If Subagent-Driven:** Invoke Skill `superpowers:subagent-driven-development`. Follow the skill exactly.
- **If Inline Execution:** Invoke Skill `superpowers:executing-plans`. Follow the skill exactly.

**Important:** Both skills will attempt to invoke `superpowers:finishing-a-development-branch` at the end. Do NOT follow that final step — instead return to the state machine for Gate 3.

## Context Protection & Compact

Before suggesting compact, ensure:
1. TodoWrite has all task statuses updated
2. Note the base branch name for later use

Then suggest: **"Implementation complete. Consider running `/compact` before verification — progress is tracked in TodoWrite and git history. After compact, I'll recover context from TodoWrite + git log + docs/superpowers/."**

Announce: **"Phase 3 complete — implementation done. Returning to state machine for Gate 3."**

Return to the state machine SKILL.md for Gate 3.
