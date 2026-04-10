---
name: grok-query
description: >
  Query X's Grok AI through agent-browser to get real-time analysis powered by X's
  live post data. Use this skill whenever the user wants to ask Grok a question, get Grok's
  opinion, leverage X/Twitter discussion data for analysis, or when the user says
  "ask Grok", "Grok 怎么看", "用 Grok 查一下", "问问 Grok", "Grok 分析",
  "帮我问 Grok", or references getting AI analysis that specifically needs X/Twitter's
  real-time post data. This skill is distinct from web search — Grok has access to
  live X posts and discussions that web search tools cannot reach.
allowed-tools: Bash(agent-browser:*), Bash(npx agent-browser:*)
---

# Grok Query via agent-browser

Query X's Grok AI through browser automation to get analysis backed by real-time X post data.

Grok has direct access to X/Twitter's full post corpus — trending discussions, sentiment shifts,
community reactions, breaking narratives. For crypto sentiment, breaking news reactions,
community FUD/FOMO analysis, or any topic where X discussions are the primary signal,
Grok provides data that web search tools cannot reach.

## Prerequisites

- User's Chrome must have remote debugging enabled (`chrome://inspect/#remote-debugging` checkbox)
  and be logged into X
- agent-browser CLI must be installed

## Workflow

### Step 1: Establish CDP connection

Chrome 144+ shows an "Allow remote debugging?" dialog on every new CDP WebSocket connection.
Never use `--auto-connect open <url>` — it bundles connection + navigation, and if the user
is slow to click Allow, agent-browser times out and retries, stacking dialogs that make
buttons appear unresponsive.

**Always connect separately first**, then navigate:

```bash
WS_PATH=$(sed -n '2p' ~/Library/Application\ Support/Google/Chrome/DevToolsActivePort)
agent-browser connect "ws://127.0.0.1:9222${WS_PATH}"
```

The user clicks Allow on Chrome's dialog. Once `connect` succeeds, all subsequent commands
in this session work without further dialogs.

### Step 2: Open Grok in a new tab

Always open a new tab for each query — this preserves the user's existing tabs and allows
clean cleanup after extraction.

```bash
agent-browser tab new "https://x.com/i/grok"
agent-browser wait --load networkidle
```

To resume a previous conversation:
```bash
agent-browser tab new "https://x.com/i/grok?conversation=<ID>"
agent-browser wait --load networkidle
```

### Step 3: Submit the question

Snapshot to find the input field, fill it, then **re-snapshot to find the submit button**.

Refs shift after fill — the ref you found before filling will point to a different element
after. This is the most common source of bugs: clicking "专家" instead of "问 Grok 问题"
because you used a stale ref.

```bash
# Find input, fill question
agent-browser snapshot -i -c | grep -E "textbox"
agent-browser fill @<input-ref> "<question>"
# MUST re-snapshot — refs have changed
agent-browser snapshot -i -c | grep -E "button.*(问|Grok 问题|submit)"
# Scroll into view and click — sometimes the button is obscured
agent-browser scrollintoview @<submit-ref>
agent-browser click @<submit-ref>
```

Do not press Enter — Grok's input intercepts it for newlines.

### Step 4: Wait for completion, then extract

Don't use keyword detection ("思考"/"Thinking") — these words can appear in Grok's
response text or cited tweets and cause the poll to never exit.

Instead, use **content stabilization**: poll until two consecutive reads return the same
content, meaning Grok has finished writing.

```bash
sleep 10
PREV=""
for i in $(seq 1 24); do
  CURR=$(agent-browser eval --stdin 2>&1 <<'JSEOF'
(() => (document.querySelector('main')?.innerText || '').length.toString())()
JSEOF
  )
  if [ -n "$PREV" ] && [ "$CURR" = "$PREV" ]; then
    echo "Content stabilized at poll $i (length: $CURR)"
    break
  fi
  PREV="$CURR"
  sleep 5
done
```

Then extract the full response:

```bash
agent-browser eval --stdin <<'JSEOF'
(() => {
  const main = document.querySelector('main');
  return main ? main.innerText : 'ERROR: main element not found';
})()
JSEOF
```

If the response seems truncated (ends mid-sentence), scroll down and re-extract:
```bash
agent-browser scroll down 5000
sleep 2
# re-run the eval above
```

### Step 5: Record conversation ID and close the tab

```bash
agent-browser eval --stdin <<'JSEOF'
(() => window.location.href)()
JSEOF
```

Save the conversation ID from `x.com/i/grok?conversation=<ID>` — use it for follow-ups
instead of starting new conversations.

Close only the Grok tab (not the entire browser session):

```bash
agent-browser tab close
```

This leaves the CDP connection alive and the user's other tabs untouched. Use
`agent-browser close` only when you're done with all browser automation for the session.

## Formatting the Response

The raw `main.innerText` includes sidebar navigation mixed in. Clean it up:

1. The Grok response starts after the user's question text (which appears first)
2. It ends before the source counts (e.g., "8 网页") and suggested follow-up prompts
3. Strip lines that are clearly navigation: "主页", "探索", "通知", "聊天", "Grok",
   "书签", "创作者工作室", "Premium", "个人资料", "更多", "发帖", "DragonKid",
   "@username", "查看新帖子", "专家"
4. Preserve structure (headings, bullets, bold, tables)
5. Note cited sources (X post count + web page count shown at end)
6. Add a note that this is Grok's analysis based on X data as of the current date

## Follow-up Questions

To continue in the same conversation:
1. Establish connection (Step 1)
2. `agent-browser tab new "https://x.com/i/grok?conversation=<ID>"`
3. Same fill → re-snapshot → click submit flow
4. Extract and format response the same way
5. `agent-browser tab close` when done

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Dialog buttons unresponsive | Multiple dialogs stacked — `agent-browser close`, then reconnect with Step 1 |
| Connection timeout | Verify `chrome://inspect/#remote-debugging` checkbox is enabled |
| DevToolsActivePort not found | Chrome not running or remote debugging not enabled |
| Clicked wrong button | Refs shifted after fill — always re-snapshot before clicking |
| Poll loop never exits | Content length stabilization should handle this; if not, increase sleep interval |
| Partial/truncated response | Scroll down 5000px then re-extract |
| Empty main.innerText | Page still loading — `agent-browser wait --load networkidle` then retry |
| Lost conversation | Use saved conversation ID, or click "聊天历史记录" button |
