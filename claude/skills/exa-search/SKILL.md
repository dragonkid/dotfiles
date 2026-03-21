---
name: exa-search
description: Web search via Exa MCP. Covers general web search, code context, academic papers, tweets, personal blogs, financial reports, and people profiles. Use when the user needs web search, code examples, news, academic papers, tweets, blog posts, people lookup, or any real-time web information. Triggers on "search", "look up", "find", "what's the latest", "news about", "search tweets", "find papers", "search blogs".
context: fork
---

# Exa Search

Unified web search skill using Exa MCP tools. Selects the right tool and category based on intent.

## Tool Selection

| Intent | Tool | Category |
|--------|------|----------|
| General web search | `web_search_exa` | - |
| Filtered search (domain/date) | `web_search_advanced_exa` | - |
| Code examples, API docs | `get_code_context_exa` | - |
| News, current events | `web_search_advanced_exa` | `news` |
| Academic papers, arXiv | `web_search_advanced_exa` | `research paper` |
| Tweets, X discussions | `web_search_advanced_exa` | `tweet` |
| Personal blogs, portfolios | `web_search_advanced_exa` | `personal site` |
| People, LinkedIn profiles | `web_search_advanced_exa` | `people` |
| Financial reports, SEC filings | `web_search_advanced_exa` | `financial report` |
| Extract URL content | `crawling_exa` | - |
| Deep async research | `deep_researcher_start` | - |

## Token Isolation

Never run Exa in main context. Always spawn Task agents:
- Agent runs search internally
- Agent deduplicates and distills results
- Agent returns concise output (compact JSON or brief markdown)
- Main context stays clean

## Token Efficiency

- Agent workflows: use `highlights` mode (10x fewer tokens than full text)
- Deep research: use `text` + `maxCharacters` limit
- Can combine highlights + text in one call

## Category Filter Restrictions

Each category disables certain filters. Violating these causes 400 errors.

### Full filter support
`research paper`, `personal site`, `news` — all filters work.

### Partial restrictions
- **`tweet`**: NO includeText, excludeText, includeDomains, excludeDomains, moderation. Use date filters + query keywords instead.
- **`financial report`**: NO excludeText. Everything else works.

### Severe restrictions
- **`company`**: NO date filters, NO text filters, NO excludeDomains. Only query + numResults + type.
- **`people`**: NO date filters, NO text filters, NO excludeDomains. includeDomains only accepts LinkedIn domains.

### Universal restriction
`includeText` and `excludeText` only support single-item arrays. Multi-item causes 400. Put multiple terms in the query string instead.

## Query Writing

- Always include programming language for code search ("Go generics" not "generics")
- Include framework + version when applicable ("Next.js 14", "React 19")
- Use 2-3 query variations for coverage, run in parallel, merge and deduplicate
- For tweets: put keywords in query, not includeText (which is unsupported)

## Content Freshness (maxAgeHours)

- Omit (recommended): livecrawl only when no cache exists
- `0`: always livecrawl (high latency)
- `-1`: cache only (fastest)
- `24` / `1`: livecrawl if cache exceeds age

## Search Types

- `auto` (default): highest quality, use for most queries
- `fast`: low latency when speed matters
- `instant`: <200ms, real-time apps
- `deep` / `deep-reasoning`: complex multi-step research, supports `outputSchema` for structured JSON output

## Deep Search Notes

- `outputSchema` only works with `deep` / `deep-reasoning`
- Do not include citation/confidence fields in schema — returned automatically in `output.grounding`
- Simpler schemas perform better
- Use `systemPrompt` for behavior guidance, `outputSchema` for structure

## Code Search (`get_code_context_exa`)

Parameters: `query` (required), `tokensNum` (optional, default 5000, range 1000-50000)

Token strategy:
- Focused snippet: 1000-3000
- Most tasks: 5000
- Complex integration: 10000-20000

Output: copyable snippets + version/constraints notes + source URLs.

## Examples

### General web search
```
web_search_exa(query: "latest AI developments 2026", numResults: 5)
```

### Code search
```
get_code_context_exa(query: "Python asyncio gather error handling", tokensNum: 3000)
```

### Academic papers
```
web_search_advanced_exa(
  query: "transformer attention efficiency",
  category: "research paper",
  startPublishedDate: "2025-01-01",
  numResults: 15
)
```

### Tweet search
```
web_search_advanced_exa(
  query: "Claude Code MCP experience",
  category: "tweet",
  startPublishedDate: "2025-01-01",
  numResults: 20
)
```

### Personal blogs (exclude aggregators)
```
web_search_advanced_exa(
  query: "building production LLM applications lessons",
  category: "personal site",
  excludeDomains: ["medium.com", "substack.com"],
  numResults: 15
)
```

### Domain-filtered news
```
web_search_advanced_exa(
  query: "AI regulation policy",
  category: "news",
  includeDomains: ["reuters.com", "nytimes.com"],
  startPublishedDate: "2025-01-01",
  numResults: 10
)
```
