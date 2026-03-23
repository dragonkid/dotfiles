---
name: x-bookmark-digest
description: >
  Review and digest X (Twitter) bookmarks — rank by engagement, show content summaries,
  and let user decide which to keep or remove. Extracts cookies via agent-browser CLI, calls
  X GraphQL API directly with httpx (no API key needed). Use when: user says "digest bookmarks",
  "消化书签", "review my bookmarks", "处理推特书签", "sync bookmarks", "同步书签", "拉取推特书签",
  "bookmark digest", "看看书签", "书签消化", or wants to review their X bookmarks.
user-invocable: true
---

# X Bookmark Digest

Fetch X/Twitter bookmarks, rank by engagement, show content summaries, let user triage.

## Dependencies

- **httpx** — async HTTP client (usually pre-installed with Python 3.11+)
- Install if missing: `pip3 install httpx`
- **agent-browser** — browser automation CLI (`brew install agent-browser`)
- No X API key or third-party scraper library needed

## Configuration

Cookie cache: `~/.x-bookmark-sync/cookies.json`
Config file: `~/.x-bookmark-sync/config.json`

## Authentication

Use agent-browser CLI to extract cookies from the user's browser.
The user must be logged in to x.com in Chrome. No manual cookie copying needed.

### Cookie extraction flow

**If cached cookies exist**, try them first. If API returns 401/403, re-extract.

**Extract from Chrome:**

```bash
agent-browser --auto-connect open https://x.com
agent-browser cookies
# → parse out auth_token and ct0 values
```

Cache to `~/.x-bookmark-sync/cookies.json`.

If Chrome not running, use AskUserQuestion to ask user to open Chrome and login to x.com.

## Workflow

### Step 1: Extract cookies and prepare

Extract cookies using the flow above. Build request headers:

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

Compute weighted engagement score and sort descending:

```
score = likes + retweets * 3 + replies * 2
```

### Step 3: Present Top 3 and let user pick

Show the Top 3 with rich content summaries:

```
**#1 @username** · YYYY-MM-DD · Score: N
<content summary — see guidelines below>
Likes: N · RT: N · Replies: N
<original post URL>
```

Then use AskUserQuestion:

```
AskUserQuestion:
  question: "选择要查看的书签"
  header: "Top 3"
  options:
    - label: "#1 @username - <short label>"
      description: "Score: N · <one-line highlight>"
    - label: "#2 @username - <short label>"
      description: "Score: N · <one-line highlight>"
    - label: "#3 @username - <short label>"
      description: "Score: N · <one-line highlight>"
    - label: "停止"
      description: "结束处理，剩余书签留在 X"
```

### Step 4: Show detailed content and ask to delete or keep

When user picks a bookmark, show the full content summary (for article tweets, fetch via agent-browser first).
Then use AskUserQuestion:

```
AskUserQuestion:
  question: "这条书签怎么处理？"
  header: "@username"
  options:
    - label: "已了解，删除书签"
      description: "内容已消化，从 X 移除"
    - label: "保留在 X"
      description: "以后再看，回到列表"
    - label: "不感兴趣，删除"
      description: "不需要，直接从 X 移除"
```

- **已了解，删除书签**: Remove from X via API, return to list
- **保留在 X**: Do nothing, return to list
- **不感兴趣，删除**: Remove from X via API, return to list

After processing, fetch page 1 again (deleted bookmarks gone, remaining shift up),
re-rank, and show next Top 3. Repeat until user chooses "停止" or no bookmarks remain.

### Step 5: Report and suggest next steps

After all bookmarks processed (or user chose "停止"):

```
处理完成
- N 条已了解并删除
- N 条不感兴趣（已删除）
- N 条保留在 X
- N 条未处理（提前停止）

如果对某个话题感兴趣，可以：
- /deep-research <topic> — 深入调研
- /obsidian-deep-research <topic> — 调研并整理到 vault
```

## Content Summary Guidelines

The summary should focus on WHAT the post says, not how popular it is.
Engagement stats are shown separately — the summary is about content.

Bad: "阿川的 AI thinking 长文，6.8k likes，是近期最热门的中文 AI 深度分析之一" (says nothing about the content)
OK but too brief: "Dexter 定位是 OpenClaw + Claude Code for finance，可以自动寻找低估股票、拆解财务数据、生成投资论文。全部开源。"
Good: "Dexter 是一个开源的 AI 金融研究工具，基于 OpenClaw 和 Claude Code 构建。核心功能是自动化股票研究流程：用 AI agent 筛选低估股票、自动拉取并拆解公司财报（收入、利润率、现金流等）、最终将分析结果整理成结构化的投资论文。整个过程从数据获取到报告生成全自动，适合个人投资者做基本面研究。GitHub 10k stars，附带演示视频。"

**For article-link tweets** (text is just `http://x.com/i/article/...` with no description):
X articles require JS rendering. Use agent-browser to fetch the actual content:

```bash
agent-browser --auto-connect open <article_url>
agent-browser snapshot
```

Extract the article title and body from the snapshot, then write a proper content summary.
If agent-browser fails, fall back to: "X Article by @username — 需要打开链接查看内容"

## Bookmark Removal API

```
POST https://x.com/i/api/graphql/Wlmlj2-xzyS1GN3a6cj-mQ/DeleteBookmark
json: {"variables": {"tweet_id": "<id>"}, "queryId": "Wlmlj2-xzyS1GN3a6cj-mQ"}
```

## Script

Deterministic logic is bundled in `scripts/bookmark.py`:

```bash
SKILL_DIR="<path to x-bookmark-digest skill>"
COOKIES='{"auth_token":"...","ct0":"..."}'

# Fetch page 1 → JSON array of tweets
python3 "$SKILL_DIR/scripts/bookmark.py" fetch --cookies "$COOKIES"

# Remove one bookmark → {"status":"removed","tweet_id":"..."}
python3 "$SKILL_DIR/scripts/bookmark.py" remove --cookies "$COOKIES" --tweet-id "123456"
```

## Error Handling

- **Chrome not running / auto-connect fails**: AskUserQuestion — ask user to open Chrome with x.com
- **Cookies expired (401/403)**: Re-extract from Chrome via agent-browser
- **Rate limited (429)**: Read `x-rate-limit-reset` header, wait, retry
