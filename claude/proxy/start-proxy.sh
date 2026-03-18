#!/bin/bash
# Start Bedrock model proxy if not already running.
# Called from zshrc before Claude Code env setup.

PROXY_PORT="${BEDROCK_PROXY_PORT:-8099}"
PROXY_SCRIPT="$HOME/.claude/proxy/bedrock-model-proxy.mjs"
PROXY_PID_FILE="/tmp/bedrock-model-proxy.pid"
PROXY_LOG="/tmp/bedrock-model-proxy.log"

# Check if proxy is already running
if [ -f "$PROXY_PID_FILE" ]; then
  PID=$(cat "$PROXY_PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    return 0 2>/dev/null || exit 0
  fi
  rm -f "$PROXY_PID_FILE"
fi

# Only start if upstream is configured
if [ -z "$BEDROCK_UPSTREAM_URL" ]; then
  return 0 2>/dev/null || exit 0
fi

nohup node "$PROXY_SCRIPT" --port "$PROXY_PORT" --upstream "$BEDROCK_UPSTREAM_URL" \
  >> "$PROXY_LOG" 2>&1 &
echo $! > "$PROXY_PID_FILE"

# Wait briefly for proxy to start
sleep 0.3
