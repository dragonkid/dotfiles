---
name: x-bookmark-sync
description: >
  Sync X (Twitter) bookmarks to Obsidian vault as searchable Markdown notes,
  with optional bookmark removal after sync. Extracts cookies from browser via agent-browser CLI,
  then calls X GraphQL API directly with httpx (no API key needed).
  Use when: user says "sync bookmarks", "同步书签", "拉取推特书签", "sync my X bookmarks",
  "pull twitter bookmarks to obsidian", "bookmark sync", "书签同步到 obsidian",
  or wants to batch-save their X bookmarks into their knowledge base.
  Also triggers when user wants to remove processed bookmarks from X after saving.
user-invocable: true
---

# X Bookmark Sync

Fetch X/Twitter bookmarks, convert to Obsidian-compatible Markdown, save to vault, optionally remove from X.

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

### Step 2: Fetch page 1, process, repeat

Always fetch page 1 (no cursor). When a bookmark is synced and removed from X,
it disappears from the list and the next bookmark naturally moves up.
This eliminates cursor management entirely.

```
GET https://x.com/i/api/graphql/bN6kl72VsPDRIGxDIhVu7A/Bookmarks
params: variables={"count":20, "includePromotedContent":false}, features={...}
```

After processing a page, fetch page 1 again (processed bookmarks have been removed, remaining shift up).
Stop when: user chooses "停止", or page returns empty (no more bookmarks).

### Step 3: Interactive per-bookmark review

Within each page, process bookmarks one by one. For each bookmark, present a summary as bullet points:

```
**@username** · YYYY-MM-DD
- <one-line summary of tweet content>
- Likes: N · Retweets: N · Replies: N
- Media: N photos, N videos (or "none")
- Links: <expanded URLs if any>
```

Then use AskUserQuestion to let the user decide:

```
AskUserQuestion:
  question: "同步这条书签？"
  header: "@username"
  options:
    - label: "同步 (Recommended)"
      description: "保存到 Clippings/ 并从 X 移除书签"
    - label: "不感兴趣"
      description: "不保存，直接从 X 移除"
    - label: "停止"
      description: "结束处理，剩余书签留在 X"
```

Based on user choice:
- **同步**: Write Markdown to vault + remove from X
- **不感兴趣**: Remove from X without saving
- **停止**: End the loop, remaining bookmarks stay in X

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
- N 条已同步到 Clippings/
- N 条不感兴趣（已从 X 移除）
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
