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
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)

    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


if __name__ == "__main__":
    main()
