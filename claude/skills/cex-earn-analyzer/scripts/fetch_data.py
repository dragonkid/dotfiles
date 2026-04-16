#!/usr/bin/env python3
"""
CEX Earn Analyzer — data fetching layer.

Subcommands:
  announcements [--days N]   Fetch Binance announcement titles (catalogId=93)
  stablecoins                Fetch stablecoin market caps from DefiLlama
  ticker SYMBOL [SYMBOL...]  Fetch Binance 24h ticker data (e.g. USDCUSDT)
  price  SYMBOL [SYMBOL...]  Fetch Binance spot price (e.g. WLFIUSDT)
  detail CODE [CODE...]      Fetch announcement detail pages via defuddle

All output is JSON to stdout. Errors go to stderr.
"""

import json
import subprocess
import sys
import urllib.request
from datetime import datetime, timedelta, timezone

BINANCE_CMS_URL = (
    "https://www.binance.com/bapi/composite/v1/public/cms/article/list/query"
    "?type=1&catalogId=93&pageNo={page}&pageSize=20"
)
BINANCE_DETAIL_URL = (
    "https://www.binance.com/en/support/announcement/detail/{code}"
)
DEFILLAMA_STABLECOINS_URL = (
    "https://stablecoins.llama.fi/stablecoins?includePrices=true"
)
BINANCE_TICKER_URL = "https://api.binance.com/api/v3/ticker/24hr?symbol={symbol}"
BINANCE_PRICE_URL = "https://api.binance.com/api/v3/ticker/price?symbol={symbol}"

MAX_PAGES = 8


def _fetch_json(url: str) -> dict:
    with urllib.request.urlopen(url, timeout=15) as resp:
        return json.loads(resp.read())


# ── announcements ──────────────────────────────────────────────

def fetch_announcements(days: int = 30) -> list[dict]:
    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    results = []
    for page in range(1, MAX_PAGES + 1):
        data = _fetch_json(BINANCE_CMS_URL.format(page=page))
        articles = (
            data.get("data", {}).get("catalogs", [{}])[0].get("articles", [])
        )
        if not articles:
            break
        for a in articles:
            ts = a.get("releaseDate", 0)
            dt = datetime.fromtimestamp(ts / 1000, tz=timezone.utc)
            if dt < cutoff:
                continue
            results.append({
                "title": a["title"],
                "code": a["code"],
                "date": dt.strftime("%Y-%m-%d"),
            })
    return results


# ── stablecoins ────────────────────────────────────────────────

def fetch_stablecoins() -> list[dict]:
    data = _fetch_json(DEFILLAMA_STABLECOINS_URL)
    out = []
    for asset in data.get("peggedAssets", []):
        mcap = asset.get("circulating", {}).get("peggedUSD", 0)
        if mcap < 1e6:
            continue
        out.append({
            "symbol": asset.get("symbol", ""),
            "name": asset.get("name", ""),
            "market_cap_usd": round(mcap, 2),
        })
    return out


# ── ticker / price ─────────────────────────────────────────────

def fetch_tickers(symbols: list[str]) -> list[dict]:
    out = []
    for sym in symbols:
        try:
            d = _fetch_json(BINANCE_TICKER_URL.format(symbol=sym))
            out.append({
                "symbol": sym,
                "price": float(d.get("lastPrice", 0)),
                "volume_24h_usd": round(float(d.get("quoteVolume", 0)), 2),
            })
        except Exception as e:
            out.append({"symbol": sym, "error": str(e)})
    return out


def fetch_prices(symbols: list[str]) -> list[dict]:
    out = []
    for sym in symbols:
        try:
            d = _fetch_json(BINANCE_PRICE_URL.format(symbol=sym))
            out.append({
                "symbol": sym,
                "price": float(d.get("price", 0)),
            })
        except Exception as e:
            out.append({"symbol": sym, "error": str(e)})
    return out


# ── detail (defuddle) ──────────────────────────────────────────

def fetch_details(codes: list[str]) -> list[dict]:
    out = []
    for code in codes:
        url = BINANCE_DETAIL_URL.format(code=code)
        try:
            result = subprocess.run(
                ["defuddle", "parse", url, "--md"],
                capture_output=True,
                text=True,
                timeout=30,
            )
            if result.returncode == 0:
                out.append({"code": code, "url": url, "markdown": result.stdout})
            else:
                out.append({
                    "code": code,
                    "url": url,
                    "error": result.stderr.strip() or f"exit {result.returncode}",
                })
        except subprocess.TimeoutExpired:
            out.append({"code": code, "url": url, "error": "timeout"})
    return out


# ── parse (structured extraction) ─────────────────────────────

import re as _re

_REGION_KEYWORDS = [
    "Bahrain", "CIS", "GCC", "MENA", "South Asia", "Pakistan",
    "Balkans", "Turkey", "Nigeria", "India Exclusive", "Indonesia",
    "Japan Exclusive", "Korea Exclusive", "EEA",
]

_PROMOTION_PERIOD_RE = _re.compile(
    r"Promotion Period[:\s*]*(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}(?::\d{2})?\s*\(UTC\))"
    r"\s*to\s*(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}(?::\d{2})?\s*\(UTC\))",
    _re.IGNORECASE,
)

_TIER_RE = _re.compile(
    r"Subscription Amount\s*[≤<=]+\s*([\d,]+(?:\.\d+)?)\s+(\w+)",
    _re.IGNORECASE,
)

_PERSONAL_LIMIT_RE = _re.compile(
    r"Max\.?\s*Subscription\s*Limit\s*per\s*User.*?</(?:td|p)>\s*</(?:td|p)>.*?"
    r"([\d,]+(?:\.\d+)?)\s+(\w+)",
    _re.IGNORECASE | _re.DOTALL,
)


def _strip_html(text: str) -> str:
    return _re.sub(r"<[^>]+>", "", text).strip()


def _extract_table_cells(html_table: str) -> list[str]:
    raw = _re.findall(r"<(?:td|p)[^>]*>(.*?)</(?:td|p)>", html_table, _re.DOTALL)
    return [_strip_html(c) for c in raw if _strip_html(c)]


def _parse_number(s: str) -> float | None:
    cleaned = s.replace(",", "").strip()
    try:
        return float(cleaned)
    except ValueError:
        return None


def _parse_dt(s: str) -> str | None:
    s = s.strip().replace("(UTC)", "UTC").strip()
    return s if s else None


def _detect_region(title: str, markdown: str) -> str | None:
    # Check title first (strongest signal)
    title_low = title.lower()
    for kw in _REGION_KEYWORDS:
        if kw.lower() in title_low:
            return kw
    # Check for explicit "exclusive" patterns in first 500 chars of body
    head = markdown[:500].lower()
    for kw in _REGION_KEYWORDS:
        kw_low = kw.lower()
        if f"{kw_low} exclusive" in head or f"exclusive for {kw_low}" in head or f"eligible users in {kw_low}" in head or f"for {kw_low} residents" in head:
            return kw
    return None


def _detect_coin_from_table(cells: list[str]) -> str | None:
    stablecoins = ["USDC", "USDT", "RLUSD", "USD1", "RWUSD", "U", "KGST", "FDUSD"]
    for c in cells:
        token = c.strip()
        if token in stablecoins:
            return token
    return None


def _detect_type(cells: list[str], markdown: str) -> str:
    for c in cells:
        low = c.lower()
        if "flexible" in low:
            return "Flexible"
        if "locked" in low or "14 days" in low or "7 days" in low:
            return "Locked"
    if "hold" in markdown.lower() and "airdrop" in markdown.lower():
        return "Hold Airdrop"
    return "Unknown"


def parse_activity(code: str, url: str, markdown: str) -> dict:
    result = {
        "code": code,
        "url": url,
        "coin": None,
        "type": "Unknown",
        "advertised_apr": None,
        "tier_limit": None,
        "tier_apr": None,
        "base_apr": None,
        "personal_limit": None,
        "total_pool_limit": None,
        "start_time": None,
        "end_time": None,
        "is_ended": False,
        "reward_currency": None,
        "region_restriction": None,
        "new_user_only": False,
        "raw_table_text": None,
    }

    # Region detection — extract title from first line
    title_line = markdown.split("\n")[0] if markdown else ""
    result["region_restriction"] = _detect_region(title_line, markdown)

    # New user detection
    if "never" in markdown.lower() and ("subscribed" in markdown.lower() or "locked" in markdown.lower()):
        result["new_user_only"] = True

    # Promotion period
    period_matches = _PROMOTION_PERIOD_RE.findall(markdown)
    if period_matches:
        # Take the first match (main promotion, not sub-promotions)
        result["start_time"] = _parse_dt(period_matches[0][0])
        result["end_time"] = _parse_dt(period_matches[0][1])

        # Check if ended
        end_str = period_matches[0][1]
        try:
            clean = _re.sub(r"\s*\(UTC\)\s*", "", end_str).strip()
            end_dt = datetime.strptime(clean, "%Y-%m-%d %H:%M:%S") if ":" in clean.split(" ")[-1] and clean.count(":") >= 2 else datetime.strptime(clean, "%Y-%m-%d %H:%M")
            end_dt = end_dt.replace(tzinfo=timezone.utc)
            result["is_ended"] = datetime.now(timezone.utc) > end_dt
        except (ValueError, IndexError):
            pass

    # Extract HTML tables
    tables = _re.findall(r"<table>(.*?)</table>", markdown, _re.DOTALL)
    all_cells = []
    for t in tables:
        cells = _extract_table_cells(t)
        all_cells.extend(cells)
        if not result["raw_table_text"]:
            result["raw_table_text"] = " | ".join(cells[:30])

    # Coin detection
    result["coin"] = _detect_coin_from_table(all_cells)

    # Type detection
    result["type"] = _detect_type(all_cells, markdown)

    # Tier limit from "Subscription Amount ≤ N COIN"
    tier_matches = _TIER_RE.findall(markdown)
    if tier_matches:
        val = _parse_number(tier_matches[0][0])
        if val is not None:
            result["tier_limit"] = val

    # APR extraction from table cells
    for i, c in enumerate(all_cells):
        if "%" in c and "APR" not in c:
            pct = _re.search(r"([\d.]+)%", c)
            if pct:
                val = pct.group(0)
                if result["tier_apr"] is None:
                    result["tier_apr"] = val
                    result["advertised_apr"] = val
                elif result["base_apr"] is None:
                    base_pct = float(pct.group(1))
                    if base_pct < 10:  # base rate is usually lower
                        result["base_apr"] = val

    # Fallback: APR from markdown text
    if not result["advertised_apr"]:
        apr_match = _re.search(r"(?:up to|enjoy)\s+([\d.]+)%\s*APR", markdown, _re.IGNORECASE)
        if apr_match:
            result["advertised_apr"] = apr_match.group(1) + "%"
            result["tier_apr"] = result["advertised_apr"]

    # Personal limit from table: look for cells after "Max. Subscription Limit per User"
    for i, c in enumerate(all_cells):
        if "max" in c.lower() and "subscription" in c.lower() and "per user" in c.lower():
            # Look at subsequent cells for the number
            for j in range(i + 1, min(i + 5, len(all_cells))):
                num = _parse_number(all_cells[j].split()[0] if all_cells[j].split() else "")
                if num is not None and num > 0:
                    result["personal_limit"] = num
                    break
            break
    # Fallback: regex on full text
    if result["personal_limit"] is None:
        pl_match = _re.search(r"maximum\s+([\d,]+)\s+(\w+)\s+per\s+user", markdown, _re.IGNORECASE)
        if pl_match:
            result["personal_limit"] = _parse_number(pl_match.group(1))
        # Another pattern: "Max. Subscription Limit per User" in table followed by value
        pl_match2 = _re.findall(r"([\d,]+)\s+(?:USDC|RLUSD|U|USDT|USD1|KGST|RWUSD)\b", markdown)
        if pl_match2 and result["personal_limit"] is None:
            # Take the largest number as personal limit
            nums = [_parse_number(x) for x in pl_match2 if _parse_number(x)]
            if nums:
                result["personal_limit"] = max(nums)

    # Reward currency: check if reward differs from deposit
    reward_match = _re.search(r"share\s+[\d,.]+\s+(?:million\s+)?(\w+)\s+token", markdown, _re.IGNORECASE)
    if reward_match:
        result["reward_currency"] = reward_match.group(1)
    else:
        result["reward_currency"] = result["coin"]

    return result


def fetch_and_parse(codes: list[str]) -> list[dict]:
    details = fetch_details(codes)
    results = []
    for item in details:
        if "error" in item:
            results.append({"code": item["code"], "url": item.get("url", ""), "error": item["error"]})
            continue
        parsed = parse_activity(item["code"], item["url"], item["markdown"])
        results.append(parsed)
    return results


# ── CLI ────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "announcements":
        days = 30
        if "--days" in sys.argv:
            idx = sys.argv.index("--days")
            days = int(sys.argv[idx + 1])
        result = fetch_announcements(days)
    elif cmd == "stablecoins":
        result = fetch_stablecoins()
    elif cmd == "ticker":
        result = fetch_tickers(sys.argv[2:])
    elif cmd == "price":
        result = fetch_prices(sys.argv[2:])
    elif cmd == "detail":
        result = fetch_details(sys.argv[2:])
    elif cmd == "parse":
        result = fetch_and_parse(sys.argv[2:])
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)

    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


if __name__ == "__main__":
    main()

