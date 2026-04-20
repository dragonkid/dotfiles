# Phase 2: Branch Setup

Use AskUserQuestion to ask:
- Question: "How to isolate this bugfix work?"
- Options: "Create worktree (Recommended)", "Create fix branch"

## If worktree:

Invoke Skill `superpowers:using-git-worktrees`. Follow the skill exactly.

Record `BRANCH_MODE=worktree` and the base branch name in TodoWrite.

## If fix branch:

**Always fetch and rebase the source branch before creating a new branch.** This ensures the new branch starts from the latest code, avoiding merge conflicts and stale-code issues downstream.

```bash
# 1. Determine the source branch (main/master/develop, or a feature branch the user specifies)
SOURCE_BRANCH=<source-branch>

# 2. Fetch latest and rebase
git fetch origin $SOURCE_BRANCH
git checkout $SOURCE_BRANCH
git pull --rebase origin $SOURCE_BRANCH

# 3. Create the fix branch from the updated source
# Derive branch name from bug report (kebab-case, max 50 chars)
# e.g., "Empty email accepted" -> fix/empty-email-accepted
git checkout -b fix/<bug-slug>
```

If the user specifies a non-default source branch, use that instead of main/master. Ask if unsure.

Record `BRANCH_MODE=branch` and the base branch name (the branch you were on before switching) in TodoWrite.

Announce: **"Phase 2 complete. Returning to state machine for Phase 3."**

Return to the state machine SKILL.md.
