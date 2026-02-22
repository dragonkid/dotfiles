---
name: web-clipper
description: Clip web articles to Obsidian vault with full content and images. Use when user sends a URL and wants to save it to Obsidian, or says "clip this", "save to Obsidian", "保存到 Obsidian", "clip 到 vault" etc. Handles WeChat articles (mp.weixin.qq.com) and general web pages. Saves to Clippings/ folder by default.
---

# Web Clipper

Clip web articles to Obsidian vault with full text and images.

## Vault Location

```
/Users/dk/Library/CloudStorage/GoogleDrive-idragonkid@gmail.com/My Drive/Second Brain
```

Default save folder: `Clippings/`
Image folder: `Attachments/<article-title>/`

## Workflow

### 1. Fetch article content

Use browser tool (profile=openclaw) for best results — handles lazy-loaded images and JS-rendered content:

```
browser open → browser snapshot (snapshotFormat=ai) → extract text
```

Fall back to `web_fetch` if browser is unavailable.

### 2. Get image URLs

After opening in browser, evaluate JS to get all image URLs including lazy-loaded ones:

```js
// Scroll to trigger lazy load first
window.scrollTo(0, document.body.scrollHeight)

// Then get all images with data-src fallback
Array.from(document.querySelectorAll('article img, #js_content img')).map((img, i) => ({
  index: i,
  src: img.src,
  dataSrc: img.getAttribute('data-src')
}))
```

Use `dataSrc` when `src` is a placeholder (data:image/svg or 1x1 pixel).

### 3. Download images

```bash
ATTACH_DIR="<vault>/Attachments/<title>"
mkdir -p "$ATTACH_DIR"
curl -s -L "<url>" -o "$ATTACH_DIR/img-1.jpg"
# repeat for each image
```

Skip non-content images (tracking pixels, avatars, follow buttons, GIFs at end of WeChat articles).

### 4. Write Markdown

Frontmatter template:
```yaml
---
title: <title>
source: <url>
author: <author>
date: <YYYY-MM-DD>
tags: [<relevant tags>]
---
```

Embed images using Obsidian wikilink syntax at their original position in the article:
```
![[<title>/img-1.jpg]]
```

Save to: `<vault>/Clippings/<title>.md`

## WeChat Articles

- Content is in `#js_content` selector
- Last image is usually a "follow" GIF — skip it
- Some images are lazy-loaded; always scroll before extracting URLs
- Author info is in `.rich_media_meta_list`

## Ask user if unclear

- Target folder (default: `Clippings/`)
- Whether to include images (default: yes)
