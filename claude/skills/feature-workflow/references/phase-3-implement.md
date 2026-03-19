# Phase 3: Implement

Read TodoWrite to recover: execution mode choice from Phase 2, branch mode and base branch from Phase 1.

Based on the execution mode chosen in Phase 2:

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
