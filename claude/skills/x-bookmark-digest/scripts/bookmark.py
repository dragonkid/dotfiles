#!/usr/bin/env python3
"""X Bookmark operations: fetch, write, remove. Called by Claude via Bash."""

import argparse
import asyncio
import glob
import json
import os
import re
import sys
from datetime import datetime

import httpx

BEARER = "Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA"

FEATURES = json.dumps({
    "graphql_timeline_v2_bookmark_timeline": True,
    "rweb_tipjar_consumption_enabled": True,
    "responsive_web_graphql_exclude_directive_enabled": True,
    "verified_phone_label_enabled": False,
    "creator_subscriptions_tweet_preview_api_enabled": True,
    "responsive_web_graphql_timeline_navigation_enabled": True,
    "responsive_web_graphql_skip_user_profile_image_extensions_enabled": False,
    "communities_web_enable_tweet_community_results_fetch": True,
    "c9s_tweet_anatomy_moderator_badge_enabled": True,
    "articles_preview_enabled": True,
    "responsive_web_edit_tweet_api_enabled": True,
    "graphql_is_translatable_rweb_tweet_is_translatable_enabled": True,
    "view_counts_everywhere_api_enabled": True,
    "longform_notetweets_consumption_enabled": True,
    "responsive_web_twitter_article_tweet_consumption_enabled": True,
    "tweet_awards_web_tipping_enabled": False,
    "creator_subscriptions_quote_tweet_preview_enabled": False,
    "freedom_of_speech_not_reach_fetch_enabled": True,
    "standardized_nudges_misinfo": True,
    "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": True,
    "rweb_video_timestamps_enabled": True,
    "longform_notetweets_rich_text_read_enabled": True,
    "longform_notetweets_inline_media_enabled": True,
    "responsive_web_enhance_cards_enabled": False,
})


def _make_headers(cookies: dict) -> dict:
    return {
        "authorization": BEARER,
        "x-csrf-token": cookies["ct0"],
        "x-twitter-auth-type": "OAuth2Session",
        "x-twitter-active-user": "yes",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36",
    }


def _parse_tweet(entry: dict) -> dict | None:
    content = entry.get("content", {}).get("itemContent", {}).get("tweet_results", {}).get("result", {})
    tweet_data = content.get("tweet", content)
    legacy = tweet_data.get("legacy", {})
    user_legacy = (
        tweet_data.get("core", {})
        .get("user_results", {})
        .get("result", {})
        .get("legacy", {})
    )
    if not legacy or not user_legacy:
        return None

    media_items = []
    for m in legacy.get("extended_entities", {}).get("media", []):
        mtype = m.get("type", "photo")
        if mtype == "photo":
            media_items.append({"type": "photo", "url": m.get("media_url_https", "")})
        elif mtype in ("video", "animated_gif"):
            mp4s = [v for v in m.get("video_info", {}).get("variants", [])
                    if v.get("content_type") == "video/mp4"]
            if mp4s:
                best = max(mp4s, key=lambda v: v.get("bitrate", 0))
                media_items.append({"type": "video", "url": best["url"]})

    created_at = legacy.get("created_at", "")
    try:
        dt = datetime.strptime(created_at, "%a %b %d %H:%M:%S %z %Y")
        date_compact = dt.strftime("%Y%m%d")
        time_str = dt.strftime("%Y-%m-%d %H:%M")
    except ValueError:
        date_compact = datetime.now().strftime("%Y%m%d")
        time_str = datetime.now().strftime("%Y-%m-%d %H:%M")

    tweet_id = legacy.get("id_str", tweet_data.get("rest_id", ""))
    username = user_legacy.get("screen_name", "unknown")
    full_text = legacy.get("full_text", "")

    for u in legacy.get("entities", {}).get("urls", []):
        full_text = full_text.replace(u.get("url", ""), u.get("expanded_url", u.get("url", "")))
    for mu in legacy.get("entities", {}).get("media", []):
        full_text = full_text.replace(mu.get("url", ""), "").strip()

    return {
        "id": tweet_id,
        "text": full_text,
        "username": username,
        "name": user_legacy.get("name", ""),
        "date_compact": date_compact,
        "time": time_str,
        "url": f"https://x.com/{username}/status/{tweet_id}",
        "media": media_items,
        "likes": legacy.get("favorite_count", 0),
        "retweets": legacy.get("retweet_count", 0),
        "replies": legacy.get("reply_count", 0),
    }


def _extract_entries(data: dict) -> list:
    instructions = (
        data.get("data", {})
        .get("bookmark_timeline_v2", {})
        .get("timeline", {})
        .get("instructions", [])
    )
    entries = []
    for inst in instructions:
        entries.extend(inst.get("entries", []))
    return entries


def _extract_cursor(entries: list) -> str | None:
    for e in entries:
        if e.get("entryId", "").startswith("cursor-bottom-"):
            return e.get("content", {}).get("value")
    return None


# --- fetch (paginated) ---

async def cmd_fetch(cookies: dict) -> None:
    headers = _make_headers(cookies)
    all_tweets = []
    cursor = None

    async with httpx.AsyncClient(cookies=cookies, headers=headers, timeout=30) as client:
        while True:
            variables = {"count": 20, "includePromotedContent": False}
            if cursor:
                variables["cursor"] = cursor

            resp = await client.get(
                "https://x.com/i/api/graphql/bN6kl72VsPDRIGxDIhVu7A/Bookmarks",
                params={"variables": json.dumps(variables), "features": FEATURES},
            )
            if resp.status_code != 200:
                print(json.dumps({"error": f"HTTP {resp.status_code}", "body": resp.text[:300]}),
                      file=sys.stderr)
                break

            entries = _extract_entries(resp.json())

            page_tweets = []
            for e in entries:
                if e.get("entryId", "").startswith("tweet-"):
                    t = _parse_tweet(e)
                    if t:
                        page_tweets.append(t)

            if not page_tweets:
                break

            all_tweets.extend(page_tweets)
            cursor = _extract_cursor(entries)
            if not cursor:
                break

    print(json.dumps(all_tweets, ensure_ascii=False))


# --- write (CLIP format) ---

def _clean_article_text(raw: str) -> str:
    """Clean article text from agent-browser eval output.

    Handles two issues:
    1. Literal \\n sequences (from JS eval JSON output) → real newlines
    2. X UI noise at head (author, date, engagement counts) and tail (Premium promo, bio)
    """
    # Decode literal \n to real newlines
    text = raw.replace("\\n", "\n").replace("\\t", "\t")
    # Strip surrounding quotes from JSON string output
    if text.startswith('"') and text.endswith('"'):
        text = text[1:-1]

    lines = text.split("\n")

    # Remove tail: everything after "想发布自己的文章？" or "升级为 Premium"
    cut_markers = ["想发布自己的文章", "升级为 Premium", "升级到Premium"]
    cleaned = []
    for line in lines:
        if any(m in line for m in cut_markers):
            break
        cleaned.append(line)

    # Remove head UI noise. X article innerText has a fixed structure:
    # Title (line 0) → Author name → @handle → "·" → Date → "关注" → engagement numbers → Body
    # Strategy: keep title (first long line), then skip until we find the next long content line.
    noise_re = re.compile(
        r"^(\d+[万亿]?|·|关注|@\w+|认证账号|\d+月\d+日|"
        r"\d+\s*回复.*|\d+\s*次转帖.*|\d+\s*喜欢.*|\d+\s*书签.*|\d+\s*次观看.*)$"
    )
    title = ""
    body_start = 0
    found_title = False
    for i, line in enumerate(cleaned):
        stripped = line.strip()
        if not stripped:
            continue
        if not found_title and len(stripped) > 10:
            title = stripped
            found_title = True
            continue
        if found_title:
            # Skip noise lines after the title
            if noise_re.match(stripped) or len(stripped) <= 4:
                continue
            # Skip short author-like lines (display name, usually < 20 chars before @handle)
            if len(stripped) < 20 and not any(c in stripped for c in "。，！？.!?:："):
                continue
            # Found real body content
            body_start = i
            break

    body_lines = [title, ""] + cleaned[body_start:] if title else cleaned[body_start:]
    result = "\n".join(body_lines).strip()
    # Collapse 3+ consecutive blank lines to 2
    result = re.sub(r"\n{3,}", "\n\n", result)
    return result


def _auto_slug(text: str, username: str, tweet_id: str) -> str:
    """Generate a kebab-case slug from content text.

    Extracts English words first. Falls back to username if no English words found.
    """
    # Extract English words (2+ chars) from first 300 chars
    words = re.findall(r"[a-zA-Z][a-zA-Z0-9]+", text[:300])
    # Filter out common noise words
    noise = {"the", "and", "for", "with", "that", "this", "from", "are", "was",
             "you", "your", "can", "all", "but", "not", "has", "have", "its",
             "http", "https", "www", "com", "status"}
    words = [w.lower() for w in words if w.lower() not in noise and len(w) > 1]

    # Deduplicate while preserving order
    seen = set()
    unique = []
    for w in words:
        if w not in seen:
            seen.add(w)
            unique.append(w)
    if len(unique) >= 2:
        return "-".join(unique[:5])

    # Fallback: username + last 6 digits of tweet_id
    return f"{username.lower()}-{tweet_id[-6:]}"


def cmd_write(tweet_json: str, slug: str | None, vault: str,
              article_content: str | None = None) -> None:
    tweet = json.loads(tweet_json)
    vault = os.path.expanduser(vault)
    clip_dir = os.path.join(vault, "10-Inbox", "Clippings")
    os.makedirs(clip_dir, exist_ok=True)

    tweet_id = tweet["id"]

    # Dedup: check if any existing CLIP file contains this tweet_id
    for existing in glob.glob(os.path.join(clip_dir, "CLIP-*.md")):
        with open(existing, "r", encoding="utf-8") as f:
            if tweet_id in f.read(2000):
                print(json.dumps({"status": "skipped", "tweet_id": tweet_id, "path": existing}))
                return

    # Clean article content
    body_text = tweet["text"]
    if article_content:
        body_text = _clean_article_text(article_content)

    # Generate slug
    if not slug:
        slug = _auto_slug(body_text, tweet["username"], tweet_id)
    safe_slug = re.sub(r"[^a-zA-Z0-9-]", "", slug.replace(" ", "-").lower())[:60]
    if not safe_slug:
        safe_slug = f"{tweet['username'].lower()}-{tweet_id[-6:]}"

    # Filename
    date_compact = tweet["date_compact"]
    filename = f"CLIP-{date_compact}-{safe_slug}.md"
    vault_path = os.path.join(clip_dir, filename)

    # Resolve collision
    counter = 2
    while os.path.exists(vault_path):
        filename = f"CLIP-{date_compact}-{safe_slug}-{counter}.md"
        vault_path = os.path.join(clip_dir, filename)
        counter += 1

    # Build CLIP markdown
    created = tweet["time"]  # "YYYY-MM-DD HH:MM"

    lines = [
        "---",
        "tags:",
        "  - type/clipping",
        "  - source/x-bookmark",
        f"created: {created}",
        "source_tool: x-bookmark-digest",
        'source_query: ""',
        "processed: false",
        "up: []",
        "---",
        "",
        f"> [@{tweet['username']}]({tweet['url']}), {created}",
        "",
        body_text,
    ]

    if tweet.get("media"):
        lines.append("")
        lines.append("## Media")
        for m in tweet["media"]:
            if m["type"] == "photo":
                lines.append(f"![img]({m['url']})")
            else:
                lines.append(f"[video]({m['url']})")

    lines.append("")
    md = "\n".join(lines)

    with open(vault_path, "w", encoding="utf-8") as f:
        f.write(md)

    print(json.dumps({"status": "written", "tweet_id": tweet_id, "path": vault_path}))


# --- remove ---

async def cmd_remove(cookies: dict, tweet_id: str) -> None:
    headers = _make_headers(cookies)
    async with httpx.AsyncClient(cookies=cookies, headers=headers, timeout=30) as client:
        resp = await client.post(
            "https://x.com/i/api/graphql/Wlmlj2-xzyS1GN3a6cj-mQ/DeleteBookmark",
            json={
                "variables": {"tweet_id": tweet_id},
                "queryId": "Wlmlj2-xzyS1GN3a6cj-mQ",
            },
        )
        if resp.status_code == 200:
            print(json.dumps({"status": "removed", "tweet_id": tweet_id}))
        else:
            print(json.dumps({"status": "error", "tweet_id": tweet_id, "code": resp.status_code}))
            sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="X Bookmark operations")
    sub = parser.add_subparsers(dest="command", required=True)

    p_fetch = sub.add_parser("fetch", help="Fetch all bookmarks (paginated)")
    p_fetch.add_argument("--cookies", required=True, help="JSON: {auth_token, ct0}")

    p_write = sub.add_parser("write", help="Write a tweet as CLIP note to vault")
    p_write.add_argument("--tweet", required=True, help="Tweet JSON string")
    p_write.add_argument("--slug", default=None, help="Content slug for filename (kebab-case). Auto-generated if omitted.")
    p_write.add_argument("--vault", default="~/Documents/second-brain")
    p_write.add_argument("--article-content", default=None,
                         help="Article body text (replaces tweet text for article tweets)")

    p_remove = sub.add_parser("remove", help="Remove a bookmark from X")
    p_remove.add_argument("--cookies", required=True, help="JSON: {auth_token, ct0}")
    p_remove.add_argument("--tweet-id", required=True)

    args = parser.parse_args()

    if args.command == "fetch":
        asyncio.run(cmd_fetch(json.loads(args.cookies)))
    elif args.command == "write":
        cmd_write(args.tweet, args.slug, args.vault, args.article_content)
    elif args.command == "remove":
        asyncio.run(cmd_remove(json.loads(args.cookies), args.tweet_id))


if __name__ == "__main__":
    main()
