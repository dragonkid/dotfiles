---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git push:*), AskUserQuestion
description: Create a git commit, then optionally push
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Based on the above changes, create a single git commit. Stage and create the commit in a single message.

After the commit succeeds, use AskUserQuestion to ask whether to push (default: Push). Then push if confirmed.
