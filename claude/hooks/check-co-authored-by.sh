#!/bin/bash

# Get the command from Claude tool input
COMMAND=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.command' 2>/dev/null)

# Check if this is a git commit command
if echo "$COMMAND" | grep -q "git commit"; then
    # Check if the commit message contains Co-Authored-By
    if echo "$COMMAND" | grep -qi "Co-Authored-By"; then
        # Block the commit
        cat <<EOF
{
  "decision": "block",
  "reason": "❌ **Co-Authored-By not allowed**\n\nYour global CLAUDE.md specifies:\n> Omit Co-Authored-By lines from commit messages\n\nPlease remove the Co-Authored-By line from the commit message."
}
EOF
        exit 0
    fi
fi

# Approve all other operations
echo '{"decision": "approve"}'
exit 0
