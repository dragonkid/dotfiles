#!/bin/bash
# Check if project CLAUDE.md is stale based on commits since last update.
# Runs as a SessionStart hook. Outputs a reminder if threshold exceeded.

set -e

COMMIT_THRESHOLD=10

# Must be in a git repo
git rev-parse --show-toplevel >/dev/null 2>&1 || exit 0

REPO_ROOT=$(git rev-parse --show-toplevel)
CLAUDE_MD="${REPO_ROOT}/CLAUDE.md"

# Only check if project has a CLAUDE.md
[ -f "$CLAUDE_MD" ] || exit 0

# Get last commit that touched CLAUDE.md
last_update=$(git log -1 --format=%ct -- "$CLAUDE_MD" 2>/dev/null)

# If CLAUDE.md is untracked or has no git history, skip
[ -z "$last_update" ] && exit 0

# Find the commit that last touched CLAUDE.md
last_update_ref=$(git log -1 --format=%H -- "$CLAUDE_MD" 2>/dev/null)

# Count commits since last CLAUDE.md update
commits_since=$(git rev-list --count "${last_update_ref}..HEAD" 2>/dev/null || echo 0)

# Detect structural changes: new dirs, entry/config/schema files
structural_changes=$(git diff --diff-filter=A --name-only "${last_update_ref}..HEAD" 2>/dev/null \
  | grep -cE '(/$|/[^/]+/$|main\.|index\.|app\.|routes\.|schema\.|migrate|Makefile|Dockerfile|docker-compose|\.env\.example)' || true)

reasons=""
if [ "$commits_since" -ge "$COMMIT_THRESHOLD" ]; then
  reasons="${commits_since} commits since last update"
fi
if [ "${structural_changes:-0}" -gt 0 ]; then
  [ -n "$reasons" ] && reasons="${reasons}, "
  reasons="${reasons}${structural_changes} structural changes (new dirs/entry files/schemas)"
fi

if [ -n "$reasons" ]; then
  echo "CLAUDE.md may be stale: ${reasons}. Consider running /update-project-context"
fi

exit 0
