# Phase 2: Branch Setup

Use AskUserQuestion to ask:
- Question: "How to isolate this feature work?"
- Options: "Create worktree (Recommended)", "Create feature branch"

## If worktree:

Invoke Skill `superpowers:using-git-worktrees`. Follow the skill exactly.

Record `BRANCH_MODE=worktree` and the base branch name in TodoWrite.

## If feature branch:

Create and switch to a new branch from the current HEAD:

```bash
# Derive branch name from feature request (kebab-case, max 50 chars)
# e.g., "Add OAuth2 login" -> feat/add-oauth2-login
git checkout -b feat/<feature-slug>
```

Record `BRANCH_MODE=branch` and the base branch name (the branch you were on before switching) in TodoWrite.

Announce: **"Phase 2 complete. Returning to state machine for Phase 3."**

Return to the state machine SKILL.md.
