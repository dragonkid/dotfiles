#!/bin/bash
# Block git commit commands that contain Co-Authored-By lines.
# Runs as PreToolUse hook on Bash tool calls.

# Read tool input from stdin (Claude Code hook format)
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Check if this is a git commit command with Co-Authored-By
if echo "$COMMAND" | grep -q "git commit"; then
    if echo "$COMMAND" | grep -qi "Co-Authored-By:"; then
        cat <<EOF
{
  "decision": "block",
  "reason": "Co-Authored-By not allowed. Your CLAUDE.md specifies: Omit Co-Authored-By lines from commit messages."
}
EOF
        exit 0
    fi
fi
