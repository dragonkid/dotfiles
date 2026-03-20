---
name: x-bookmark-sync
description: >
  Sync X (Twitter) bookmarks to Obsidian vault as searchable Markdown notes,
  with optional bookmark removal after sync. Uses tweety library with cookie-based auth (no API key needed).
  Use when: user says "sync bookmarks", "同步书签", "拉取推特书签", "sync my X bookmarks",
  "pull twitter bookmarks to obsidian", "bookmark sync", "书签同步到 obsidian",
  or wants to batch-save their X bookmarks into their knowledge base.
  Also triggers when user wants to remove processed bookmarks from X after saving.
user-invocable: true
---

# X Bookmark Sync

Fetch X/Twitter bookmarks, convert to Obsidian-compatible Markdown, save to vault, optionally remove from X.

## Dependencies

- **tweety** (https://github.com/mahrtayyab/tweety) — Twitter GraphQL scraper, cookie-based auth
- Install: `pip install tweety-ns`

## Configuration

Session file: `~/.x-bookmark-sync/session.tw_session`
Config file: `~/.x-bookmark-sync/config.json`

```json
{
  "vault_path": "~/Documents/second-brain",
  "clippings_dir": "Clippings",
  "attachments_dir": "Attachments",
  "download_media": false,
  "pages": 5
}
```

## Authentication

tweety supports three auth methods, tried in this order:

### 1. Existing session (preferred, zero-effort after first login)

tweety's `FileSession` persists cookies to `~/.x-bookmark-sync/session.tw_session`.
After first successful auth, subsequent runs reconnect automatically.

```python
from tweety import Twitter
app = Twitter("~/.x-bookmark-sync/session")
await app.connect()  # reuses saved session
```

### 2. Cookie string (from browser)

User exports cookies from browser (Cookie Editor extension or DevTools).
Only `auth_token` and `ct0` are required.

```python
await app.load_cookies("auth_token=xxx; ct0=yyy")
```

### 3. auth_token only (simplest manual setup)

User copies just the `auth_token` value from browser cookies.
tweety auto-fetches `ct0`.

```python
await app.load_auth_token("your_auth_token_here")
```

### First-time setup flow

If no session file exists, ask the user which method they prefer using AskUserQuestion:
- "Paste cookie string" — run `load_cookies()`
- "Paste auth_token only" — run `load_auth_token()`
- "Login with username/password" — run `start(username, password)`

After successful auth, the session is saved automatically for future use.

## Workflow

### Step 1: Load config and authenticate

```python
import json, os, asyncio
from tweety import Twitter

CONFIG_DIR = os.path.expanduser("~/.x-bookmark-sync")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")
SESSION_NAME = os.path.join(CONFIG_DIR, "session")

os.makedirs(CONFIG_DIR, exist_ok=True)

# Load or create config
defaults = {
    "vault_path": "~/Documents/second-brain",
    "clippings_dir": "Clippings",
    "attachments_dir": "Attachments",
    "download_media": False,
    "pages": 5
}
if os.path.exists(CONFIG_FILE):
    with open(CONFIG_FILE) as f:
        config = {**defaults, **json.load(f)}
else:
    config = defaults
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)

app = Twitter(SESSION_NAME)
```

### Step 2: Fetch bookmarks

```python
bookmarks = await app.get_bookmarks(pages=config["pages"])
```

Each bookmark is a `Tweet` object with attributes:
- `id`, `text`, `created_on` (datetime)
- `author` — `User` object with `.name`, `.username`
- `media` — list of media objects with `.media_url`, `.type`
- `threads` — thread context if reply
- `url` — tweet URL

### Step 3: Write Markdown files

For each bookmark, generate a Markdown file matching the existing obsidian-clipper format.

**Staging rule**: Write to staging dir first, then copy to vault (prevents Obsidian sync conflicts):

```python
STAGING = os.path.expanduser("~/.x-bookmark-sync/staging")
VAULT = os.path.expanduser(config["vault_path"])
CLIP_DIR = os.path.join(VAULT, config["clippings_dir"])
```

**Frontmatter** (must match vault conventions):

```yaml
---
title: "<first 60 chars of tweet text or 'Tweet by @username'>"
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

**Body format**:

```markdown
> <full tweet text>

— [@username](https://x.com/username), YYYY-MM-DD HH:MM

<if media and download_media=false>
## Media
- ![img](https://pbs.twimg.com/media/xxx.jpg)

<if media and download_media=true>
## Media
![[<title>/img-1.jpg]]

<if thread context>
## Thread Context
> <parent tweet text>
— @parent_username
```

**Filename**: `@<username> - <tweet_id>.md`
Use tweet ID in filename to guarantee uniqueness and enable idempotent re-runs.

### Step 4: Download media (if enabled)

```python
if config["download_media"]:
    attach_dir = os.path.join(VAULT, config["attachments_dir"], title)
    os.makedirs(attach_dir, exist_ok=True)
    # Download each media item via curl or httpx
```

### Step 5: Ask whether to remove bookmarks

After all files are written, use AskUserQuestion to ask whether to remove the synced bookmarks from X.
Default option is "Remove" (first in list):

```
AskUserQuestion:
  question: "已同步 N 条书签到 Clippings/，是否从 X 移除这些书签？"
  header: "书签清理"
  options:
    - label: "移除 (Recommended)"
      description: "从 X 删除已同步的书签，保持书签列表干净"
    - label: "保留"
      description: "书签保留在 X 上，下次同步会跳过已存在的"
```

If user chooses "移除":

```python
removed = 0
for tweet in synced_tweets:
    await app.delete_bookmark_tweet(tweet.id)
    removed += 1
```

### Step 6: Report

```
Synced N bookmarks to Clippings/
- N new files written
- N skipped (already exist)
- N media downloaded (if applicable)
- N bookmarks removed from X (if applicable)
```

## User Intent Mapping

Claude should infer these settings from natural language context:

| User says | Action |
|-----------|--------|
| "同步书签" / "sync bookmarks" | Default: 5 pages, no media download |
| "把图片也下载下来" / "download images too" | Set `download_media = True` |
| "只拉最近的" / "just the latest" | Set `pages = 1` |
| "全部同步" / "sync everything" | Set `pages = 20` (or higher) |

If ambiguous, use AskUserQuestion to clarify.

## Idempotency

The filename includes tweet ID, so re-running the sync skips already-saved bookmarks.
Check `os.path.exists()` before writing each file.

## Error Handling

- **Auth expired**: If `connect()` fails, use AskUserQuestion to ask the user to re-authenticate (same options as first-time setup: paste cookie / paste auth_token / login with password)
- **Rate limited**: tweety handles rate limits with configurable `wait_time`; default 2s between pages
- **Write failure**: If any file write fails, do NOT proceed to bookmark removal
- **Partial sync**: Track which tweets were successfully written; only remove those specific bookmarks
