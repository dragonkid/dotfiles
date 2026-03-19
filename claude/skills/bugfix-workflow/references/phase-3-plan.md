# Phase 3: Plan

## Document Output

Plans are saved in the project repo:

```
DOCS_ROOT = docs/superpowers/
```

If `docs/superpowers/` does not exist, create it (`mkdir -p docs/superpowers/{specs,plans}`).

### Vault Sync

After creating or updating any document in `DOCS_ROOT`, use AskUserQuestion to ask:
- Question: "同步此文档到 Obsidian vault？"
- Options: "Yes — sync to vault", "No — skip"

If yes: copy the file to `~/Documents/second-brain/Jobs/{project_name}/` where `{project_name}` is derived from `basename $(git rev-parse --show-toplevel)`. Create the directory if it doesn't exist.

---

## Step 0: Reuse Discovery

Before writing the plan, invoke Skill `everything-claude-code:search-first` with the root cause description as context. Feed findings into the plan — reference existing code rather than proposing new implementations of already-available functionality.

## Step 1: Write the Plan

Invoke Skill `superpowers:writing-plans`.

Follow the skill exactly. It will:
- Create a detailed implementation plan based on the Phase 1 diagnosis
- Structure tasks with TDD steps (write test -> verify fail -> implement -> verify pass -> commit)
- Save the plan to `docs/superpowers/plans/YYYY-MM-DD-<bug-summary>.md`
- Present the execution mode choice at the end:
  1. **Subagent-Driven** (recommended) — fresh subagent per task with two-stage review
  2. **Inline Execution** — execute tasks in this session with checkpoints

Record the user's execution mode choice for Phase 4.

## Context Protection & Compact

Before suggesting compact, ensure:
1. Plan file is saved to `docs/superpowers/`
2. TodoWrite records: root cause, BRANCH_MODE (branch/worktree), base branch name, execution mode choice, current phase

Then suggest: **"The diagnosis and planning phases used significant context. Consider running `/compact` now — all decisions are persisted in TodoWrite and docs/superpowers/. After compact, I'll recover context by reading those files."**

Announce: **"Phase 3 complete — plan saved. Returning to state machine for Gate 3."**

Return to the state machine SKILL.md for Gate 3.
