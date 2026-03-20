#!/usr/bin/env python3
"""X Bookmark operations: fetch, write, remove. Called by Claude via Bash."""

import argparse
import asyncio
import json
import os
import re
import shutil
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
        date_str = dt.strftime("%Y-%m-%d")
        time_str = dt.strftime("%Y-%m-%d %H:%M")
    except ValueError:
        date_str = datetime.now().strftime("%Y-%m-%d")
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
        "date": date_str,
        "time": time_str,
        "url": f"https://x.com/{username}/status/{tweet_id}",
        "media": media_items,
        "likes": legacy.get("favorite_count", 0),
        "retweets": legacy.get("retweet_count", 0),
        "replies": legacy.get("reply_count", 0),
    }


# --- fetch ---

async def cmd_fetch(cookies: dict) -> None:
    headers = _make_headers(cookies)
    async with httpx.AsyncClient(cookies=cookies, headers=headers, timeout=30) as client:
        params = {
            "variables": json.dumps({"count": 20, "includePromotedContent": False}),
            "features": FEATURES,
        }
        resp = await client.get(
            "https://x.com/i/api/graphql/bN6kl72VsPDRIGxDIhVu7A/Bookmarks",
            params=params,
        )
        if resp.status_code != 200:
            print(json.dumps({"error": f"HTTP {resp.status_code}", "body": resp.text[:300]}))
            sys.exit(1)

        data = resp.json()
        instructions = (
            data.get("data", {})
            .get("bookmark_timeline_v2", {})
            .get("timeline", {})
            .get("instructions", [])
        )
        entries = []
        for inst in instructions:
            entries.extend(inst.get("entries", []))

        tweets = []
        for e in entries:
            if e.get("entryId", "").startswith("tweet-"):
                t = _parse_tweet(e)
                if t:
                    tweets.append(t)

        print(json.dumps(tweets, ensure_ascii=False))


# --- write ---

def cmd_write(tweet_json: str, vault: str, clippings_dir: str) -> None:
    tweet = json.loads(tweet_json)
    staging = os.path.expanduser("~/.x-bookmark-sync/staging")
    vault = os.path.expanduser(vault)
    clip_dir = os.path.join(vault, clippings_dir)
    os.makedirs(staging, exist_ok=True)
    os.makedirs(clip_dir, exist_ok=True)

    title_text = tweet["text"][:60].replace("\n", " ").strip()
    if not title_text:
        title_text = f"Tweet by @{tweet['username']}"
    title_yaml = title_text.replace('"', '\\"')

    lines = [
        "---",
        f'title: "{title_yaml}"',
        f'source: "{tweet["url"]}"',
        "author:",
        f'  - "@{tweet["username"]}"',
        f"date: {tweet['date']}",
        "tags:",
        "  - clippings",
        "  - source/clipping",
        "  - x-bookmark",
        "---",
        "",
        f"> {tweet['text']}",
        "",
        f"--- [@{tweet['username']}]({tweet['url']}), {tweet['time']}",
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

    filename = f"@{tweet['username']} - {tweet['id']}.md"
    filename = re.sub(r'[<>:"/\\|?*]', '_', filename)
    vault_path = os.path.join(clip_dir, filename)

    if os.path.exists(vault_path):
        print(json.dumps({"status": "skipped", "path": vault_path}))
        return

    staging_path = os.path.join(staging, filename)
    with open(staging_path, "w", encoding="utf-8") as f:
        f.write(md)
    shutil.copy2(staging_path, vault_path)
    os.remove(staging_path)

    print(json.dumps({"status": "written", "path": vault_path}))


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

    p_fetch = sub.add_parser("fetch", help="Fetch page 1 of bookmarks")
    p_fetch.add_argument("--cookies", required=True, help="JSON: {auth_token, ct0}")

    p_write = sub.add_parser("write", help="Write a tweet as Markdown to vault")
    p_write.add_argument("--tweet", required=True, help="Tweet JSON string")
    p_write.add_argument("--vault", default="~/Documents/second-brain")
    p_write.add_argument("--clippings-dir", default="Clippings")

    p_remove = sub.add_parser("remove", help="Remove a bookmark from X")
    p_remove.add_argument("--cookies", required=True, help="JSON: {auth_token, ct0}")
    p_remove.add_argument("--tweet-id", required=True)

    args = parser.parse_args()

    if args.command == "fetch":
        asyncio.run(cmd_fetch(json.loads(args.cookies)))
    elif args.command == "write":
        cmd_write(args.tweet, args.vault, args.clippings_dir)
    elif args.command == "remove":
        asyncio.run(cmd_remove(json.loads(args.cookies), args.tweet_id))


if __name__ == "__main__":
    main()
