#!/bin/bash

# Remind Claude to try mgrep before WebSearch
echo "⚠️ **Web Search Protocol Check**"
echo ""
echo "You are about to use WebSearch."
echo ""
echo "✓ If you already tried 'mgrep --web --answer' and it failed/no results: proceed"
echo "✗ If you haven't tried mgrep yet: use mgrep first, then fallback to WebSearch"
echo ""
echo "(This is a reminder, not a block. WebSearch will execute after this message.)"

# Exit 0 to allow the operation (just a warning, not blocking)
exit 0
