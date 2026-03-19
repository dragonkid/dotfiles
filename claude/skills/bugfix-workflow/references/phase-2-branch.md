# Phase 2: Branch Setup

Use AskUserQuestion to ask:
- Question: "How to isolate this bugfix work?"
- Options: "Create worktree (Recommended)", "Create fix branch"

## If worktree:

Invoke Skill `superpowers:using-git-worktrees`. Follow the skill exactly.

Record `BRANCH_MODE=worktree` and the base branch name in TodoWrite.

## If fix branch:

Create and switch to a new branch from the current HEAD:

```bash
# Derive branch name from bug report (kebab-case, max 50 chars)
# e.g., "Empty email accepted" -> fix/empty-email-accepted
git checkout -b fix/<bug-slug>
```

Record `BRANCH_MODE=branch` and the base branch name (the branch you were on before switching) in TodoWrite.

Announce: **"Phase 2 complete. Returning to state machine for Phase 3."**

Return to the state machine SKILL.md.
