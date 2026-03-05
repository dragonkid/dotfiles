#!/bin/bash

# PreToolUse hook for WebSearch: block if mgrep --web hasn't been tried yet,
# or allow fallback if mgrep was recently attempted and failed.

# Read stdin for transcript_path
INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  # Can't check transcript, allow WebSearch as fallback
  exit 0
fi

# Check if mgrep --web was called recently (last 20 lines of transcript)
# Look for Bash tool_use with mgrep --web in command, followed by an error result
MGREP_TRIED=$(tail -40 "$TRANSCRIPT" | grep -c 'mgrep --web\|mgrep .*--web')

if [ "$MGREP_TRIED" -gt 0 ]; then
  # mgrep was attempted, allow WebSearch fallback
  exit 0
fi

# mgrep not tried yet, block WebSearch
echo "Try 'mgrep --web' first. WebSearch is only allowed as fallback when mgrep fails or returns no results." >&2
exit 2
