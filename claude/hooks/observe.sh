#!/bin/bash
# Continuous Learning v2 - Observation Hook (fixed version)
#
# Fix: original uses triple-quoted shell variable to pass JSON to python3,
# which breaks on inputs containing single quotes. This version pipes via stdin.
#
# v2: merged 3 python3 calls into 1, removed dead observer signal code,
# fixed shell variable embedding in write phase.
#
# Source: everything-claude-code plugin continuous-learning-v2/hooks/observe.sh

set -e

CONFIG_DIR="${HOME}/.claude/homunculus"
OBSERVATIONS_FILE="${CONFIG_DIR}/observations.jsonl"
MAX_FILE_SIZE_MB=10

mkdir -p "$CONFIG_DIR"

# Skip if disabled
if [ -f "$CONFIG_DIR/disabled" ]; then
  exit 0
fi

# Read JSON from stdin (Claude Code hook format)
INPUT_JSON=$(cat)

if [ -z "$INPUT_JSON" ]; then
  exit 0
fi

# Archive if file too large
if [ -f "$OBSERVATIONS_FILE" ]; then
  file_size_mb=$(du -m "$OBSERVATIONS_FILE" 2>/dev/null | cut -f1)
  if [ "${file_size_mb:-0}" -ge "$MAX_FILE_SIZE_MB" ]; then
    archive_dir="${CONFIG_DIR}/observations.archive"
    mkdir -p "$archive_dir"
    mv "$OBSERVATIONS_FILE" "$archive_dir/observations-$(date +%Y%m%d-%H%M%S).jsonl"
  fi
fi

# Single python3 call: parse input, build observation, write to file
echo "$INPUT_JSON" | python3 -c '
import json, sys
from datetime import datetime, timezone

obs_file = sys.argv[1]
raw = sys.stdin.read()
timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

try:
    data = json.loads(raw)

    hook_type = data.get("hook_type", data.get("hook_event_name", "unknown"))
    tool_name = data.get("tool_name", data.get("tool", "unknown"))
    tool_input = data.get("tool_input", data.get("input", {}))
    tool_output = data.get("tool_output", data.get("output", ""))
    session_id = data.get("session_id", "unknown")

    if isinstance(tool_input, dict):
        tool_input_str = json.dumps(tool_input)[:5000]
    else:
        tool_input_str = str(tool_input)[:5000]

    if isinstance(tool_output, dict):
        tool_output_str = json.dumps(tool_output)[:5000]
    else:
        tool_output_str = str(tool_output)[:5000]

    event = "tool_start" if "Pre" in hook_type else "tool_complete"

    observation = {
        "timestamp": timestamp,
        "event": event,
        "tool": tool_name,
        "session": session_id
    }

    if event == "tool_start" and tool_input_str:
        observation["input"] = tool_input_str
    if event == "tool_complete" and tool_output_str:
        observation["output"] = tool_output_str

    with open(obs_file, "a") as f:
        f.write(json.dumps(observation) + "\n")

except Exception as e:
    with open(obs_file, "a") as f:
        f.write(json.dumps({
            "timestamp": timestamp,
            "event": "parse_error",
            "raw": raw[:1000],
            "error": str(e)
        }) + "\n")
' "$OBSERVATIONS_FILE"

exit 0
