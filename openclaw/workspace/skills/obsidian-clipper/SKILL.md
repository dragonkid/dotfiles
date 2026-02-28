---
name: obsidian-clipper
description: Clip web articles to Obsidian vault with full content and images. Use when user sends a URL and wants to save it to Obsidian, or says "clip this", "save to Obsidian", "保存到 Obsidian", "clip 到 vault" etc. Also auto-triggers in Discord channel #obsidian-vault (id:1477264581674926214) when user sends a message containing only a URL or a PDF file attachment. Handles WeChat articles, X/Twitter articles, general web pages, and PDF files. Saves to Clippings/ folder by default.
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

### ⚠️ Vault 文件写入规则
所有 vault 文件的创建和编辑必须通过 staging 目录中转（`~/.openclaw/workspace/.vault-staging/`）：
1. 编辑已有文件：先 `cp` 到 staging，编辑完再 `cp` 回 vault
2. 创建新文件：先在 staging 写好完整内容，再一次性 `cp` 到 vault
3. 禁止直接在 vault 目录内多次写入同一文件
4. 图片文件同理：先下载到 staging，再 `cp -r` 到 `Attachments/`

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

### 6. 更新语义索引

文件保存后，触发增量索引（只索引新文件，不影响其他笔记）：

```bash
python3 ~/.openclaw/workspace/scripts/vault_index.py --file "Clippings/<title>.md"
```

### 7. Confirm

**只在索引完成后发一条消息**，过程中保持静默。格式（多行）：

```
✅ Clippings/<title>.md
N 张图 · 索引完成（N chunks）
<一句话主题摘要>
```

索引失败时第二行改为 `N 张图 · 索引失败：<错误原因>`。

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

---

## PDF 处理流程

当用户在 Discord #obsidian-vault channel 发送 PDF 附件时（消息中包含本地文件路径），触发此流程。

### 1. 获取文件

OpenClaw 会将附件保存到本地临时路径，从消息 metadata 中获取该路径。

### 2. 复制到 Clippings/

```bash
cp "<tmp_path>/<filename>.pdf" ~/Documents/second-brain/Clippings/<filename>.pdf
```

保持原始文件名，不做重命名。

### 3. 更新语义索引

```bash
python3 ~/.openclaw/workspace/scripts/vault_index.py --file "Clippings/<filename>.pdf"
```

### 4. Confirm

**只在索引完成后发一条消息**，格式：

```
✅ Clippings/<filename>.pdf
索引完成（N chunks）
```

索引失败时第二行改为 `索引失败：<错误原因>`。
