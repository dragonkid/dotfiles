---
name: cex-earn-analyzer
description: >
  Scan Binance "币安最新活动" announcements for stablecoin earning/holding activities, extract structured
  details, and estimate real APY using on-chain data and price APIs. Use when the user wants to check
  stablecoin yields, compare earn products, find new stablecoin activities, or analyze whether advertised
  APY is realistic. Triggers on: "稳定币活动", "stablecoin yields", "理财活动", "earn products",
  "看看有什么活动", "稳定币收益", "活期产品", "定期产品", "币安理财", "yield arena", "赚币",
  "有什么稳定币可以投", "收益对比", "哪个稳定币收益高". Also trigger when the user mentions Binance
  earn, stablecoin comparison, or asks about safe yield opportunities on Binance.
user-invocable: true
---

# CEX Earn Analyzer

Scan Binance announcements for stablecoin earning activities, verify advertised APY against on-chain reality, and produce a risk-adjusted comparison.

All data fetching uses public APIs — no browser or login required. The bundled `scripts/fetch_data.py` handles all network calls and returns structured JSON.

## Bundled Script

`scripts/fetch_data.py` provides these subcommands:

```bash
SCRIPT="$(dirname "$0")/../scripts/fetch_data.py"   # when called from skill dir
# Or use the absolute path shown by the skill loader

python3 scripts/fetch_data.py announcements [--days N]   # Binance CMS API → JSON list
python3 scripts/fetch_data.py stablecoins                # DefiLlama → JSON list
python3 scripts/fetch_data.py ticker USDCUSDT RLUSDUSDT  # Binance 24h ticker → JSON
python3 scripts/fetch_data.py price WLFIUSDT             # Binance spot price → JSON
python3 scripts/fetch_data.py detail CODE1 CODE2         # defuddle → clean markdown per page
python3 scripts/fetch_data.py parse  CODE1 CODE2         # detail + structured extraction → JSON
```

All output is JSON to stdout, errors to stderr.

## Workflow

```
fetch_data.py announcements → LLM classify → Exa verify unknowns → fetch_data.py detail → Filter → Verify APY → Output
```

### Step 1: Fetch Announcements

```bash
python3 <skill-dir>/scripts/fetch_data.py announcements --days 30
```

Returns JSON array: `[{title, code, date}, ...]`

Key notes:
- `catalogId=93` = "币安最新活动" category. Only use this category.
- The API returns **English** titles regardless of page language. Classification must handle English.
- Default range is 30 days. Adjust if the user specifies a different period.

### Step 2: LLM Classification (No Keyword Filtering)

Do NOT use keyword-based filtering — it misses new stablecoins and produces false positives (e.g., "Share 300 USDT in rewards" is not a stablecoin earn activity).

Send all titles to the LLM in a single prompt and classify each as:

- **stablecoin_earn**: The PRIMARY asset the user deposits/holds is a USD-pegged stablecoin, and the activity is earn/savings/holding reward
- **non_usd_stablecoin**: The asset is a stablecoin pegged to a non-USD fiat currency (e.g., KGST pegged to Kyrgyzstani Som). Include in output separately with a warning — holding these exposes users to FX risk on top of crypto risk, which defeats the purpose of "stable" yield.
- **not_relevant**: Trading competitions, referral programs, or activities that merely use stablecoins as reward denomination
- **uncertain**: Cannot determine — coin might be a stablecoin but not sure

What counts as "stablecoin_earn":
- Flexible/locked earn products for a USD-pegged stablecoin (e.g., "USDC Flexible Products", "U活期产品")
- Hold-to-earn airdrops where you hold a USD-pegged stablecoin (e.g., "Hold USD1 to share WLFI")
- Does NOT include: trading competitions with stablecoin prizes, referral bonuses paid in USDT
- Does NOT include by default: non-USD-pegged stablecoins (e.g., KGST/KGS, EURS/EUR). Mention them separately if found.

Note: region restrictions and activity end dates cannot be determined from titles alone — these are filtered in Step 5 after extracting details.

### Step 3: Exa Search for Uncertain Coins

For coins classified as "uncertain", search to determine if they are stablecoins:

```
web_search_exa: "[COIN_NAME] stablecoin OR pegged OR 稳定币"
```

Reclassify based on results. If still unclear, include in output with a note.

### Step 4: Extract Activity Details (Structured)

Use the `parse` subcommand instead of `detail` — it fetches the page via defuddle AND automatically extracts structured fields:

```bash
python3 <skill-dir>/scripts/fetch_data.py parse CODE1 CODE2 CODE3
```

Returns JSON array with pre-extracted fields:
```json
[{
  "code": "...", "url": "...",
  "coin": "USDC",           // auto-detected from table
  "type": "Flexible",       // Flexible / Locked / Hold Airdrop
  "advertised_apr": "5.8%", // headline APR
  "tier_limit": 200.0,      // max amount at tier APR (e.g., ≤200 USDC gets 5.8%)
  "tier_apr": "5.8%",       // APR within tier limit
  "base_apr": "0.8%",       // APR above tier limit (Real-Time APR only)
  "personal_limit": 300000000.0,  // per-user max subscription
  "start_time": "2026-04-01 00:00:00 UTC",
  "end_time": "2026-04-30 23:59:59 UTC",
  "is_ended": false,         // auto-compared with current time
  "reward_currency": "USDC", // same coin or different token
  "region_restriction": null, // "Bahrain", "CIS", "GCC", etc. or null
  "new_user_only": false,
  "raw_table_text": "..."   // fallback if auto-extraction missed something
}]
```

The script handles HTML table parsing, promotion period extraction, and tier limit detection automatically. This avoids the 100KB+ raw markdown problem from `detail`.

**When to fall back to `detail`:** If `parse` returns `null` for critical fields (coin, tier_limit) on a specific activity, use `detail` for that code and parse manually. The `raw_table_text` field provides a compact summary of the first table for quick LLM review.

Important distinctions:
- **U is NOT USDT** — "U" is a separate asset on Binance Simple Earn. The announcement explicitly states it is not an abbreviation of USD fiat currency.
- If reward_currency differs from deposit coin (e.g., hold USD1 → earn WLFI), flag this prominently — it introduces token price risk on the reward side.

### Step 5: Filter

The `parse` output already includes `is_ended` and `region_restriction` fields. Simply:
- **Remove** entries where `is_ended = true`
- **Separate** entries with `region_restriction` (report them at the bottom as region-limited)
- **Remove** entries where `new_user_only = true` if the user is not a new user (ask if unclear)

### Step 6: Verify Real APY

Two categories:

**Fixed-rate earn products** (e.g., USDC 5.5%, RLUSD 8%): Tiered APY is guaranteed within the tier limit. No verification needed — just note the tier cap.

**Variable APY activities** (e.g., hold-to-earn airdrops with fixed token pool): The advertised APY is illustrative only. Announcements use hypothetical numbers in examples (e.g., "假设年化收益率20%") — these are NOT promises. Always calculate an estimated range:

**6a. Get reward token price:**
```bash
python3 <skill-dir>/scripts/fetch_data.py price WLFIUSDT
```

**6b. Get stablecoin circulating supply:**
```bash
python3 <skill-dir>/scripts/fetch_data.py stablecoins
```
Find the coin by symbol, use `market_cap_usd`. Assume Binance holds 20-40% of total supply.

**6c. Calculate estimated APY range:**
```
annual_reward_value = (pool_per_period * token_price) * periods_per_year
APY = annual_reward_value / total_participating_amount

Conservative: 40% of circulating supply on Binance, 100% participate
Moderate:     40% on Binance, 25% participate
Optimistic:   40% on Binance, 5% participate
```

### Step 7: Risk Assessment

**7a. Get market data:**
```bash
python3 <skill-dir>/scripts/fetch_data.py ticker USDCUSDT RLUSDUSDT UUSDT USD1USDT WLFIUSDT
```
Returns `[{symbol, price, volume_24h_usd}, ...]`

For market cap, use the DefiLlama data already fetched in Step 6b.

**7b. Assess each coin's risk level:**

| Factor | Low | Medium | High |
|--------|-----|--------|------|
| Issuer track record | Years of operation, major issuer | Backed by known company, < 2 years | New project, unproven |
| Regulatory status | Licensed (e.g., NYDFS) | Partial compliance | No clear regulation |
| Reserve transparency | Regular third-party audits | Self-reported reserves | Opaque |
| **24h trading volume** | **> $100M** | **$10M - $100M** | **< $10M** |
| **Market cap** | **> $1B** | **$100M - $1B** | **< $100M** |
| Peg stability | Consistent $1.00 | Minor deviations (±0.5%) | Significant deviations |
| Reward currency risk | Same coin (USDC→USDC) | N/A | Different volatile token |

### Step 8: Output

Tag activities with status icons:
- `[NEW]` — announced within the last 3 days
- `[EXPIRING]` — ends within the next 3 days

Output each activity:

```markdown
## [NEW] [Coin] [Type] — [Advertised APY]

| Field | Detail |
|-------|--------|
| Coin | ... |
| Risk | Low / Medium / High — [one-line reason] |
| Participation | ... |
| APY | ... (with tier breakdown) |
| Time | start → end [EXPIRING: highlight days remaining] |
| Link | announcement URL |

[If variable APY: include estimated range from Step 6]
```

End with a horizontal comparison table sorted by risk-adjusted return:

```markdown
| 币种 | APR | 类型 | Tier 限额 | 截止时间 (UTC / 本地) | 风险 | 奖励币种 | 24h Vol | Market Cap | 状态 |
```

Show both UTC and the user's local timezone. Detect the user's timezone from system environment or conversation context. Example: `Apr 30 23:59 UTC / May 1 07:59 UTC+8`.

## Gotchas from Experience

- **All APIs are public** — no browser or login needed. The bundled script handles all network calls.
- **defuddle for detail pages** — returns clean markdown with tables preserved, more reliable than WebFetch's summarization.
- **API returns English titles** even on the Chinese page. Classification should handle English titles.
- **"U" ≠ USDT** — always treat as separate assets.
- **Advertised APY in examples ≠ guaranteed APY** — some announcements use hypothetical numbers in calculation examples. Always flag when APY is variable vs fixed.
- **DefiLlama for stablecoin data** — `stablecoins` subcommand returns market cap and circulating supply for all stablecoins.
- **Binance ticker API** — `ticker` and `price` subcommands are public, no API key needed.
