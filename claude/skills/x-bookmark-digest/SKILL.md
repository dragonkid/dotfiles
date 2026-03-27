---
name: x-bookmark-digest
description: >
  Batch-fetch all X (Twitter) bookmarks, save each as a CLIP note in the Obsidian vault
  (10-Inbox/Clippings/), then delete saved bookmarks from X. Extracts cookies via
  agent-browser CLI, calls X GraphQL API directly with httpx (no API key needed).
  Use when: user says "digest bookmarks", "消化书签", "review my bookmarks",
  "处理推特书签", "sync bookmarks", "同步书签", "拉取推特书签", "bookmark digest",
  "看看书签", "书签消化", or wants to review/archive their X bookmarks.
user-invocable: true
---

# X Bookmark Digest

Batch-fetch all X bookmarks, save as CLIP notes to vault, delete saved ones from X.

## Dependencies

- **httpx** — async HTTP client (usually pre-installed with Python 3.11+)
- Install if missing: `pip3 install httpx`
- **agent-browser** — browser automation CLI (`brew install agent-browser`)
- No X API key or third-party scraper library needed

## Configuration

Cookie cache: `~/.x-bookmark-sync/cookies.json`

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

### Step 1: Authenticate

Extract cookies using the flow above.

### Step 2: Fetch ALL bookmarks (paginated)

```bash
SKILL_DIR="<path to x-bookmark-digest skill>"
COOKIES=$(cat ~/.x-bookmark-sync/cookies.json)
python3 "$SKILL_DIR/scripts/bookmark.py" fetch --cookies "$COOKIES"
```

The script automatically paginates through all pages (20 per page) and outputs a single JSON array of all bookmarks. Each tweet object contains: `id`, `text`, `username`, `name`, `date_compact`, `time`, `url`, `media`, `likes`, `retweets`, `replies`.

Print a progress line: "Fetched N bookmarks total."

### Step 3: Crawl article content

Identify article tweets — those where `text` matches `x.com/i/article/...` (the entire text is just an article URL with no other content).

For each article tweet, extract the FULL article body text using agent-browser's JS eval:

```bash
agent-browser --auto-connect open <article_url>
sleep 3
agent-browser eval 'document.querySelector("main").innerText'
```

This returns the complete article text (title + body + author info). The output includes some UI noise (follower counts, button labels) — that's fine, preserve the full text verbatim in the CLIP note. The content is what matters for later decomposition.

If `eval` returns empty or the page shows only a loading spinner, retry once with a longer wait (`sleep 5`). If still empty, set the content to:

```
⚠️ **Gap**: X Article 内容未提取，需打开链接查看
<article_url>
```

### Step 4: Batch write CLIP notes to vault

For each bookmark, generate a content slug (kebab-case, English, describing the topic — e.g. `generative-tui-json-render`, `karpathy-autoresearch-overview`, `openclaw-beginner-guide`). Then write:

```bash
python3 "$SKILL_DIR/scripts/bookmark.py" write \
  --tweet '<tweet JSON>' \
  --slug '<content-slug>' \
  --vault '~/Documents/second-brain' \
  --article-content '<article body text>'   # only for article tweets
```

The script writes CLIP notes to `10-Inbox/Clippings/` with this format:

**Filename**: `CLIP-YYYYMMDD-{slug}.md`

**Frontmatter** (obsidian-deep-research CLIP template):

```yaml
---
tags:
  - type/clipping
  - source/x-bookmark
created: YYYY-MM-DD HH:mm
source_tool: x-bookmark-digest
source_query: ""
processed: false
up: []
---
```

**Body**:

```markdown
> [@username](tweet_url), YYYY-MM-DD HH:mm

{tweet text or article content}

## Media
![img](photo_url)
[video](video_url)
```

Track results in two lists:
- `saved[]` — tweets successfully written (status: "written")
- `skipped[]` — tweets that already exist (status: "skipped", dedup by tweet_id)

### Step 5: Delete saved bookmarks from X

For each tweet in `saved[]`, remove from X bookmarks:

```bash
python3 "$SKILL_DIR/scripts/bookmark.py" remove --cookies "$COOKIES" --tweet-id "<id>"
```

Only delete bookmarks that were successfully saved. Skipped (dedup) tweets are also safe to delete since they already exist in the vault.

### Step 6: Report

```
书签同步完成
- N 条已保存到 10-Inbox/Clippings/ 并从 X 删除
- N 条已存在（跳过去重）
- N 条 article 爬取失败，仍保留在 X：
  - <url1>
  - <url2>

后续处理：
- /obsidian-deep-research decompose [[CLIP-xxx]] — 拆解感兴趣的 clipping 为原子笔记
```

## Error Handling

- **Chrome not running / auto-connect fails**: AskUserQuestion — ask user to open Chrome with x.com
- **Cookies expired (401/403)**: Re-extract from Chrome via agent-browser
- **Rate limited (429)**: Read `x-rate-limit-reset` header, wait, retry
- **Article crawl fails**: Mark as Gap, keep bookmark on X, report in summary
