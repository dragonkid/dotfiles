---
name: x-bookmark-digest
description: >
  Review and digest X (Twitter) bookmarks — rank by engagement, deep-research interesting ones,
  and save findings to Obsidian vault. Extracts cookies via agent-browser CLI, calls X GraphQL API
  directly with httpx (no API key needed). Use when: user says "digest bookmarks", "消化书签",
  "review my bookmarks", "处理推特书签", "sync bookmarks", "同步书签", "拉取推特书签",
  "bookmark digest", "看看书签", "书签消化", or wants to process their X bookmarks into
  their knowledge base with research and analysis.
user-invocable: true
---

# X Bookmark Digest

Fetch X/Twitter bookmarks, rank by engagement, deep-research interesting ones, and save findings to vault.

## Dependencies

- **httpx** — async HTTP client (usually pre-installed with Python 3.11+)
- Install if missing: `pip3 install httpx`
- **agent-browser** — browser automation CLI (`brew install agent-browser`)
- No X API key or third-party scraper library needed

## Configuration

Cookie cache: `~/.x-bookmark-sync/cookies.json`
State file: `~/.x-bookmark-sync/state.json`
Config file: `~/.x-bookmark-sync/config.json`

```json
{
  "vault_path": "~/Documents/second-brain",
  "clippings_dir": "Clippings",
  "attachments_dir": "Attachments",
  "download_media": false
}
```

## Authentication

Use agent-browser CLI to extract cookies from the user's browser.
The user must be logged in to x.com in Chrome. No manual cookie copying needed.

### Cookie extraction flow

**If cached state exists and is valid**, load it directly:

```bash
# Check if state file exists
test -f ~/.x-bookmark-sync/state.json && echo "state exists"
```

**If no state or cookies expired (401/403)**, extract from Chrome:

1. **Connect to the user's Chrome and navigate to x.com**:

```bash
agent-browser --auto-connect open https://x.com
```

2. **Extract cookies** — agent-browser reads all cookies including HttpOnly:

```bash
agent-browser cookies
# → JSON array of all cookies for the current page
# → parse out auth_token and ct0 values
```

3. **Save state for future sessions**:

```bash
agent-browser state save ~/.x-bookmark-sync/state.json
```

4. **Cache the extracted cookies** to `~/.x-bookmark-sync/cookies.json`.

### If Chrome is not running or auto-connect fails

Use AskUserQuestion:
```
question: "需要从浏览器获取 X 登录态，请打开 Chrome 并登录 x.com，然后告诉我"
options:
  - "已登录，继续"
  - "取消"
```

Then retry `agent-browser --auto-connect open https://x.com`.

### If cookies expired (API returns 401/403)

1. Connect to Chrome and reload x.com to refresh cookies:

```bash
agent-browser --auto-connect open https://x.com
agent-browser cookies
```

2. Update cached state and cookies:

```bash
agent-browser state save ~/.x-bookmark-sync/state.json
```

3. If still failing, use AskUserQuestion to ask user to re-login in browser.

## Workflow

### Step 1: Extract cookies and prepare

Extract cookies from browser using the flow above. Build the request headers:

```python
cookies = {"auth_token": "<extracted>", "ct0": "<extracted>"}
headers = {
    "authorization": "Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA",
    "x-csrf-token": cookies["ct0"],
    "x-twitter-auth-type": "OAuth2Session",
    "x-twitter-active-user": "yes",
    "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36",
}
```

The Bearer token above is X's public client-side token (not a secret — it's embedded in the web app JS).

### Step 2: Fetch and rank bookmarks

Fetch page 1 (no cursor):

```
GET https://x.com/i/api/graphql/bN6kl72VsPDRIGxDIhVu7A/Bookmarks
params: variables={"count":20, "includePromotedContent":false}, features={...}
```

After fetching, compute a weighted engagement score for each bookmark and sort descending:

```
score = likes + retweets * 3 + replies * 2
```

### Step 3: Present ranked list and process one by one

First show the Top 10 ranked overview so the user sees the full picture:

```
书签热度排行 (Top 10):

 #  Score  Author         Date        Content
 1  14268  @hasantoxr     02-01       Claude-Mem 持久化记忆...
 2  12872  @virattt       02-06       Dexter 金融分析工具...
 ...
```

Then process bookmarks one by one in rank order (highest score first). For each:

```
**#1** · **@username** · YYYY-MM-DD · Score: N
<2-3 sentence summary capturing: what the tweet is about, key claims/numbers, and why it's notable>
- Likes: N · RT: N · Replies: N
- Media: N photos, N videos (or "none")
- Link: https://x.com/username/status/tweet_id
```

The summary should be informative enough for the user to decide without opening the link.
Include specific details: project names, star counts, key metrics, tools mentioned.
Bad: "Claude Code 持久化记忆插件" (too terse, no context)
Good: "Claude-Mem 给 Claude Code 加持久化跨 session 记忆，声称减少 95% token 用量、20 倍 tool call 上限。10k+ likes，100% 开源。"

Use AskUserQuestion:

```
AskUserQuestion:
  question: "处理这条书签？(#1/10)"
  header: "@username"
  options:
    - label: "深入了解 (Recommended)"
      description: "调研 tweet 内容，分析后保存到 vault 并从 X 移除"
    - label: "跳过"
      description: "保留在 X，不处理"
    - label: "不感兴趣"
      description: "不保存，直接从 X 移除"
    - label: "停止"
      description: "结束处理，剩余书签留在 X"
```

Based on user choice:
- **深入了解**: Trigger the deep-research workflow (see Step 3a below), then save via obsidian-capture + remove from X
- **跳过**: Do nothing, move to next bookmark
- **不感兴趣**: Remove from X without saving
- **停止**: End the loop, remaining bookmarks stay in X

### Step 3a: Deep research workflow (for "深入了解")

When user selects "深入了解", use the `deep-research` skill to investigate the tweet content:

1. **Extract research topic** from the tweet: project names, tools, claims, URLs mentioned
2. **Invoke deep-research** with a focused query based on the tweet content
   - e.g., for a tweet about "Dexter" → research "Dexter finance AI tool GitHub features architecture"
   - Include any URLs from the tweet as starting points
3. **Present findings** to the user as a concise research summary
4. **Save via obsidian-capture**:
   - If the topic needs further exploration → save to `Clippings/` (stays in inbox for future processing)
   - If the research is comprehensive enough → save to an appropriate topic directory (e.g., `Projects/`, `Tools/`, `Reference/`)
   - Let obsidian-capture decide the best location based on content type
5. **Remove the bookmark** from X after successful save

After processing Top 10 (or all selected removals done), fetch page 1 again.
Repeat the rank-and-process cycle until: user chooses "停止", or page returns empty.

### Step 4: Write Markdown (for synced bookmarks)

**Staging rule**: Write to `~/.x-bookmark-sync/staging/` first, then copy to vault.

**Frontmatter** (matches vault conventions from obsidian-clipper):

```yaml
---
title: "<first 60 chars of tweet text>"
source: "https://x.com/<username>/status/<tweet_id>"
author:
  - "@<username>"
date: YYYY-MM-DD
tags:
  - clippings
  - source/clipping
  - x-bookmark
---
```

**Body**:

```markdown
> <full tweet text>

--- [@username](https://x.com/username), YYYY-MM-DD HH:MM

## Media
![img](https://pbs.twimg.com/media/xxx.jpg)
[video](https://video.twimg.com/...)
```

**Filename**: `@<username> - <tweet_id>.md`
Tweet ID in filename ensures uniqueness and idempotent re-runs.

### Step 5: Remove bookmark immediately after write

When user chooses "同步", remove the bookmark right after the file is written.
Since we always fetch page 1 (no cursor), removal naturally advances the list.

```
POST https://x.com/i/api/graphql/Wlmlj2-xzyS1GN3a6cj-mQ/DeleteBookmark
json: {"variables": {"tweet_id": "<id>"}, "queryId": "Wlmlj2-xzyS1GN3a6cj-mQ"}
```

### Step 6: Report

After all bookmarks processed (or user chose "停止"):

```
处理完成
- N 条已深入调研并保存到 vault
- N 条不感兴趣（已从 X 移除）
- N 条跳过（保留在 X）
- N 条未处理（提前停止）
```

## Script

Deterministic logic is bundled in `scripts/bookmark.py` with three subcommands.
Claude extracts cookies via agent-browser, then calls the script for API/file operations:

```bash
SKILL_DIR="<path to x-bookmark-sync skill>"
COOKIES='{"auth_token":"...","ct0":"..."}'

# Fetch page 1 → JSON array of tweets
python3 "$SKILL_DIR/scripts/bookmark.py" fetch --cookies "$COOKIES"

# Write one tweet to vault → {"status":"written","path":"..."}
python3 "$SKILL_DIR/scripts/bookmark.py" write --tweet '<tweet_json>'

# Remove one bookmark → {"status":"removed","tweet_id":"..."}
python3 "$SKILL_DIR/scripts/bookmark.py" remove --cookies "$COOKIES" --tweet-id "123456"
```

All output is JSON. Claude parses the output, presents summaries, and drives the interactive loop.

## User Intent Mapping

| User says | Action |
|-----------|--------|
| "同步书签" / "sync bookmarks" | Start interactive bookmark review loop |
| "把图片也下载下来" / "download images too" | Set download_media = True |

If ambiguous, use AskUserQuestion to clarify.

## Idempotency

Filename includes tweet ID — re-running skips already-saved bookmarks.
Check `os.path.exists()` before writing each file.

## Error Handling

- **Chrome not running / auto-connect fails**: AskUserQuestion — ask user to open Chrome with x.com
- **Cookies expired (401/403)**: Re-extract from Chrome via agent-browser, ask user to re-login if needed
- **Rate limited (429)**: Read `x-rate-limit-reset` header, wait, retry
- **Write failure**: Do NOT proceed to bookmark removal
- **Partial sync**: Track which tweets were written; only remove those specific bookmarks
