# Phase 2: Branch Setup

Use AskUserQuestion to ask:
- Question: "How to isolate this refactoring work?"
- Options: "Create worktree (Recommended)", "Create refactor branch"

## If worktree:

Invoke Skill `superpowers:using-git-worktrees`. Follow the skill exactly.

Record `BRANCH_MODE=worktree` and the base branch name in TodoWrite.

## If refactor branch:

Create and switch to a new branch from the current HEAD:

```bash
# Derive branch name from refactoring goal (kebab-case, max 50 chars)
# e.g., "Extract auth logic" -> refactor/extract-auth-logic
git checkout -b refactor/<refactor-slug>
```

Record `BRANCH_MODE=branch` and the base branch name (the branch you were on before switching) in TodoWrite.

Announce: **"Phase 2 complete. Returning to state machine."**

Return to the state machine SKILL.md.
