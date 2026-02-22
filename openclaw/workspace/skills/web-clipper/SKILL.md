---
name: web-clipper
description: Clip web articles to Obsidian vault with full content and images. Use when user sends a URL and wants to save it to Obsidian, or says "clip this", "save to Obsidian", "保存到 Obsidian", "clip 到 vault" etc. Also auto-triggers in "AI 工作台" topic 3 when user sends a message containing only a URL. Handles WeChat articles, X/Twitter articles, and general web pages. Saves to Clippings/ folder by default.
user-invocable: true
---

# Web Clipper

Clip web articles to Obsidian vault with full text and images.

## Vault Location

```
~/Documents/second-brain
```

Default save folder: `Clippings/`
Image folder: `Attachments/<article-title>/`

## Workflow

### 1. Fetch article content

Use browser tool (profile=openclaw) for best results — handles lazy-loaded images and JS-rendered content:

```
browser open → wait for load → scroll to bottom (trigger lazy load) → wait 3s → snapshot
```

Fall back to `web_fetch` if browser is unavailable.

For long articles, snapshot may truncate. Use JS evaluate to get remaining text:

```js
// Get text in chunks
document.querySelector('main').innerText.substring(0, 15000)
document.querySelector('main').innerText.substring(15000, 30000)
// Continue until all content captured
```

### 2. Extract metadata

Use JS evaluate to get title, author, date:

```js
// Generic
JSON.stringify({
  title: document.querySelector('h1')?.textContent?.trim(),
  author: document.querySelector('[rel=author]')?.textContent?.trim()
})
```

See platform-specific sections below for better selectors.

### 3. Get image URLs

After scrolling, evaluate JS to get all content images:

```js
Array.from(document.querySelectorAll('article img, #js_content img')).map((img, i) => ({
  index: i,
  src: img.src,
  dataSrc: img.getAttribute('data-src')
}))
```

Use `dataSrc` when `src` is a placeholder (data:image/svg or 1x1 pixel).

Skip non-content images: tracking pixels, avatars, follow buttons, QR codes, GIFs at end of WeChat articles.

### 4. Download images

```bash
ATTACH_DIR="~/Documents/second-brain/Attachments/<title>"
mkdir -p "$ATTACH_DIR"
curl -s -L "<url>" -o "$ATTACH_DIR/img-1.png"
```

### 5. Write Markdown

Frontmatter template:

```yaml
---
title: "<title>"
source: "<url>"
author:
  - "<author>"
date: YYYY-MM-DD
tags:
  - clippings
---
```

- Convert article to clean Markdown with proper headings, lists, code blocks, tables
- Embed images using Obsidian wikilink syntax at their original position: `![[<title>/img-1.png]]`
- Preserve code blocks with language hints
- Clean up promotional content, ads, "follow me" sections
- Save to: `~/Documents/second-brain/Clippings/<title>.md`

### 6. Confirm

Brief message: file path, image count, one-line topic summary.

## Platform-Specific Handling

### WeChat (mp.weixin.qq.com)

- Content is in `#js_content` selector
- Title: `#activity-name`
- Author: `#js_name`
- Date: `#publish_time` or `.rich_media_meta_list` emphasis elements
- Last image is usually a "follow" GIF — skip it
- Images are lazy-loaded; always scroll before extracting URLs

### X/Twitter Articles

- `web_fetch` will fail (requires login). Must use browser.
- For article posts, navigate to the article URL: `x.com/<user>/article/<id>`
- Content is in `main` element
- Long articles need chunked extraction via `innerText.substring()`
- Author/date from the article header elements
- Images: extract from article body, skip UI elements

### General Web Pages

- Try `web_fetch` first for simple pages
- Fall back to browser for JS-rendered content
- Look for `article`, `main`, `.post-content`, `.entry-content` selectors

### 5. 清理

任务完成后关闭 tab：
```
browser(action=close, profile=openclaw, targetId=<targetId>)
```

## Ask user if unclear

- Target folder (default: `Clippings/`)
- Whether to include images (default: yes)
