---
name: agent-browser-automation
description: >
  Web information gathering and browser automation using agent-browser CLI. Handles connection
  strategy selection, anti-bot bypass, content extraction patterns, and site-specific gotchas
  for collecting information from any website. Use when the user asks to "open a website",
  "search on [site]", "scrape/extract info from", "check [website]", "帮我搜一下",
  "去[网站]上看看", "帮我查一下", "从[网站]提取", "打开[网站]", or any task involving
  browsing real websites to gather information. Also use when the user mentions specific sites
  like 小红书, 知乎, 微博, Twitter/X, YouTube, Reddit, or any site requiring browser interaction.
  This skill complements the official agent-browser skill (command reference) by providing
  higher-level strategy for information gathering workflows.
allowed-tools: Bash(agent-browser:*), Bash(npx agent-browser:*)
---

# Web Information Gathering with agent-browser

This skill provides strategy and patterns for using agent-browser to collect information from websites. For command syntax details, see the official `agent-browser` skill.

## Connection Strategy Decision

Choose connection mode based on the target site:

```
Does the site require login or have anti-bot protection?
├── YES → Use --auto-connect (piggyback on user's Chrome session)
│         This inherits cookies, login state, and browser fingerprint.
│         The user must have Chrome running with remote debugging enabled,
│         or a Chrome instance already open.
│
├── MAYBE (social platforms, e-commerce) → Try --auto-connect first
│         Most social/content platforms (小红书, 知乎, 微博, X) aggressively
│         detect headless browsers. Using the user's real Chrome avoids this.
│
└── NO (public docs, news, GitHub) → Direct open is fine
          agent-browser open <url>
```

**Default to `--auto-connect` for any site you haven't confirmed works without it.** The cost of using auto-connect unnecessarily is zero; the cost of getting blocked is a wasted attempt and confused error messages.

## Core Workflow

```bash
# 1. Connect and navigate
agent-browser --auto-connect open <url>

# 2. Wait for dynamic content
agent-browser wait --load networkidle

# 3. Snapshot to understand page structure
agent-browser snapshot -i -c    # -i: interactive only, -c: compact

# 4. Interact (search, click, scroll)
agent-browser fill @e6 "search query"
agent-browser press Enter
agent-browser wait --load networkidle

# 5. Extract results
agent-browser snapshot -i -c    # Re-snapshot after page change

# 6. For image-heavy content, screenshot
agent-browser screenshot /tmp/page.png
```

## Search Patterns

Many sites have unreliable search boxes (Enter doesn't trigger, autocomplete intercepts input, search redirects). When the search box doesn't work as expected, use **direct URL navigation**:

### Direct URL Search (Preferred)

Most sites support URL-based search. Try this pattern first — it's faster and more reliable:

```bash
# Generic pattern
agent-browser --auto-connect open "https://site.com/search?q=your+query"

# Site-specific examples
agent-browser --auto-connect open "https://www.xiaohongshu.com/search_result?keyword=your+query&source=web_search_result_notes"
agent-browser --auto-connect open "https://www.zhihu.com/search?type=content&q=your+query"
agent-browser --auto-connect open "https://s.weibo.com/weibo?q=your+query"
agent-browser --auto-connect open "https://www.google.com/search?q=your+query"
```

### Search Box Interaction (Fallback)

If the URL pattern is unknown, use the search box:

```bash
agent-browser snapshot -i           # Find the search input
agent-browser click @eN             # Click to focus
agent-browser fill @eN "query"      # Type query
agent-browser press Enter           # Submit
agent-browser wait --load networkidle
agent-browser snapshot -i -c        # Check if results loaded
```

If Enter doesn't work, look for a search/submit button in the snapshot and click it instead.

## Content Extraction Strategies

### Text-heavy pages (articles, forums, docs)

```bash
agent-browser snapshot -c           # Full snapshot gives text content
agent-browser get text @eN          # Extract specific element text
```

### Image-heavy pages (小红书, Instagram, Pinterest)

These platforms show content primarily as images. Text snapshots only give titles.

```bash
# Screenshot the note/post to read image content
agent-browser screenshot /tmp/note.png

# For multi-image posts, check for navigation indicators
# e.g., "1/10" means 10 images — swipe/click through
agent-browser click @next_button
agent-browser screenshot /tmp/note-2.png
```

### List/feed pages (search results, timelines)

```bash
# Snapshot to get all visible links/titles
agent-browser snapshot -i -c | grep 'link "'

# Scroll to load more
agent-browser scroll down 1000
agent-browser wait 1500
agent-browser snapshot -i -c
```

### Data tables

```bash
# Use JavaScript to extract structured data
agent-browser eval --stdin <<'EOF'
JSON.stringify(
  Array.from(document.querySelectorAll('table tr')).map(row =>
    Array.from(row.cells).map(cell => cell.textContent.trim())
  )
)
EOF
```

## Site-Specific Notes

Accumulate site-specific knowledge here as you encounter gotchas.

### 小红书 (Xiaohongshu)

- **Connection**: MUST use `--auto-connect`. Direct access returns 461 "IP at risk" error.
- **Search**: Search box Enter unreliable. Use direct URL: `/search_result?keyword=<encoded>&source=web_search_result_notes`
- **Content**: Notes are mostly images. Use `screenshot` to read content. Check for "1/N" indicator for multi-image posts.
- **Feed**: Explore page shows card grid. Links contain note titles and author names.

### General Tips

- **Refs invalidate on navigation**: Always re-snapshot after clicking links or submitting forms.
- **Dynamic content**: Use `agent-browser wait --load networkidle` after navigation. For SPAs, wait for specific elements: `agent-browser wait "#content"`.
- **Rate limiting**: Add `agent-browser wait 1000` between rapid actions on the same site to avoid triggering rate limits.
- **Popups/modals**: Check snapshot for overlay elements (cookie banners, login prompts). Dismiss them before interacting with the main content.
- **Closing**: Run `agent-browser close` when done, especially with `--auto-connect` — leaving the connection open can interfere with the user's browsing.
