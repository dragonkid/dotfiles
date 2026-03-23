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

## Workflow

```
Fetch announcements ─→ LLM classify ─→ Exa verify unknowns ─→ Extract details ─→ Filter ─→ Verify APY ─→ Output
```

### Step 1: Fetch Announcements

Use agent-browser to execute JS on the Binance page, calling the internal API to batch-fetch titles. This avoids SPA pagination issues.

```
agent-browser --auto-connect open "https://www.binance.com/zh-CN/support/announcement/list/93"
```

Then via `agent-browser eval --stdin` inside the page context (inherits cookies, bypasses CORS):

```javascript
(async () => {
  const results = [];
  for (let page = 1; page <= 8; page++) {
    const resp = await fetch(
      'https://www.binance.com/bapi/composite/v1/public/cms/article/list/query'
      + '?type=1&catalogId=93&pageNo=' + page + '&pageSize=20'
    );
    const data = await resp.json();
    const articles = data?.data?.catalogs?.[0]?.articles || [];
    articles.forEach(a => {
      const date = a.releaseDate
        ? new Date(a.releaseDate).toISOString().split('T')[0]
        : '';
      results.push({ title: a.title, code: a.code, date });
    });
    if (articles.length === 0) break;
  }
  return JSON.stringify(results);
})()
```

After fetching, filter to the past 30 days (or the user's requested range) by comparing each item's `date` field against today's date. Discard older items before classification.

Key notes:
- `catalogId=93` = "币安最新活动" category. Only use this category.
- The API returns **English** titles regardless of page language. Classification must handle English.
- 8 pages (~160 items) is a safe over-fetch. Always date-filter after fetching rather than guessing page count.
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

### Step 4: Extract Activity Details

For each confirmed stablecoin_earn activity, open the detail page and extract text:

```bash
agent-browser --auto-connect open "https://www.binance.com/zh-CN/support/announcement/detail/{code}"
agent-browser wait --load networkidle
agent-browser eval --stdin <<'EOF'
document.body.innerText.substring(0, 3000)
EOF
```

Extract into this structure:

| Field | Description |
|-------|-------------|
| coin | Asset name (e.g., USDC, RLUSD, USD1, U) |
| type | 活期 (Flexible) / 定期 (Locked) / 持仓空投 (Hold Airdrop) |
| advertised_apy | The APY stated in the announcement |
| apy_structure | How APY breaks down (tiered rate + base rate) |
| tier_limit | Maximum amount eligible for the tiered rate |
| personal_limit | Per-user max subscription |
| start_time | Activity start (UTC+8) |
| end_time | Activity end (UTC+8) |
| participation | How to participate |
| reward_currency | What currency rewards are paid in (same coin, or different token) |
| special_conditions | KYC, region restrictions, new-user-only, etc. |
| url | Full announcement URL |

Important distinctions:
- **U is NOT USDT** — "U" is a separate asset on Binance Simple Earn. The announcement explicitly states it is not an abbreviation of USD fiat currency.
- If reward_currency differs from deposit coin (e.g., hold USD1 → earn WLFI), flag this prominently — it introduces token price risk on the reward side.

### Step 5: Filter

After extracting details, filter out:
- **Ended activities**: end_time < current time
- **Region-limited activities**: special_conditions contains geographic restrictions (e.g., "Balkans only", specific country lists)

This filtering happens here (not in Step 2) because region/time info is only available in the detail page.

### Step 6: Verify Real APY

Two categories:

**Fixed-rate earn products** (e.g., USDC 5.5%, RLUSD 8%): Tiered APY is guaranteed within the tier limit. No verification needed — just note the tier cap.

**Variable APY activities** (e.g., hold-to-earn airdrops with fixed token pool): The advertised APY is illustrative only. Announcements use hypothetical numbers in examples (e.g., "假设年化收益率20%") — these are NOT promises. Always calculate an estimated range for these:

**6a. Get reward token price** from Binance public API:
```bash
curl -s "https://api.binance.com/api/v3/ticker/price?symbol={TOKEN}USDT"
```
If no USDT pair, try USDC: `?symbol={TOKEN}USDC`

**6b. Get on-chain holdings** from Arkham Intelligence:
```bash
agent-browser --auto-connect open "https://intel.arkm.com/explorer/entity/binance"
agent-browser wait --load networkidle
```
Extract the coin's total holdings via JS eval. Note: Arkham shows total Binance holdings (including cold wallet reserves), not just activity participants.

**6c. Calculate estimated APY range:**
```
# Generalize from the announcement's reward schedule:
annual_reward_value = (pool_per_period × token_price) × (periods_per_year)
#   e.g., weekly pool: × 52; daily pool: × 365; one-time pool: annualize over activity duration

APY = annual_reward_value / total_participating_amount

# Show a range since actual participation is unknown:
Conservative: 100% of Arkham holdings participate (floor estimate)
Moderate:      25% participate
Optimistic:     5% participate
```

### Step 7: Risk Assessment

**7a. Get market data** from Binance public API for each coin involved (deposit coin + reward coin if different):
```bash
# 24h trading volume and price
curl -s "https://api.binance.com/api/v3/ticker/24hr?symbol={COIN}USDT"
```
Extract `quoteVolume` (24h USD volume) and `lastPrice`. For market cap, use `quoteVolume` as a proxy or check CoinGecko/CoinMarketCap via Exa if needed.

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

Low volume and small market cap coins carry higher slippage risk on entry/exit and are more susceptible to de-peg events.

### Step 8: Output

Output each activity:

```markdown
## [Coin] [Type] — [Advertised APY]

| Field | Detail |
|-------|--------|
| Coin | ... |
| Risk | Low / Medium / High — [one-line reason] |
| Participation | ... |
| APY | ... (with tier breakdown) |
| Time | start → end |
| Link | announcement URL |

[If variable APY: include estimated range from Step 6]
```

End with a horizontal comparison table sorted by risk-adjusted return.

### Cleanup

Close agent-browser when done:
```bash
agent-browser close
```

## Gotchas from Experience

- **Binance SPA pagination doesn't work** — URL params and click events on page numbers are unreliable. Always use the internal API via JS eval.
- **Search box on announcement page is non-functional** — it doesn't filter results. Don't waste time with it.
- **API returns English titles** even on the Chinese page. Classification should handle English titles.
- **Cloudflare on Arkham** — use `--auto-connect` and may need to click through a verification challenge. Click the iframe element, then wait and re-screenshot.
- **"U" ≠ USDT** — always treat as separate assets.
- **Advertised APY in examples ≠ guaranteed APY** — some announcements use hypothetical numbers in calculation examples (e.g., "假设年化收益率20%"). This is an illustration, not a promise. Always flag when APY is variable vs fixed.
- **Detail page text extraction** — use `document.body.innerText.substring(0, 3000)` via eval. Snapshot is too noisy for structured data; full innerText is too long.
