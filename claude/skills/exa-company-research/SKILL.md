---
name: exa-company-research
description: Multi-step company research using Exa. Combines company discovery, news coverage, social presence, and people lookup into a structured research workflow. Use when researching companies, doing competitor analysis, market research, building company lists, or due diligence. Triggers on "research this company", "competitor analysis", "company overview", "market landscape", "who are the players in".
context: fork
---

# Company Research (Exa)

Multi-step research workflow combining multiple Exa categories for comprehensive company intelligence.

## Tool

ONLY use `web_search_advanced_exa`. Select different `category` values per research phase.

## Token Isolation

Always spawn Task agents — never run Exa in main context. Agent returns distilled output only.

## Research Workflow

### Phase 1: Discovery
Find companies in a space using `category: "company"`.

```
web_search_advanced_exa(
  query: "AI infrastructure startups San Francisco",
  category: "company",
  numResults: 20,
  type: "auto"
)
```

**company category restrictions**: NO date filters, NO text filters, NO includeDomains/excludeDomains. Only query + numResults + type.

### Phase 2: Deep Dive
Research specific companies without category (enables all filters).

```
web_search_advanced_exa(
  query: "Anthropic funding rounds valuation 2024",
  type: "deep",
  numResults: 10,
  includeDomains: ["techcrunch.com", "crunchbase.com", "bloomberg.com"]
)
```

### Phase 3: News Coverage
Track press and announcements with `category: "news"`.

```
web_search_advanced_exa(
  query: "Anthropic AI safety",
  category: "news",
  numResults: 15,
  startPublishedDate: "2024-01-01"
)
```

### Phase 4: Social Presence (optional)
Check Twitter/X discussion with `category: "tweet"`.

**tweet restrictions**: NO includeText, excludeText, includeDomains, excludeDomains. Use date filters + query keywords.

```
web_search_advanced_exa(
  query: "Anthropic Claude developer experience",
  category: "tweet",
  startPublishedDate: "2025-01-01",
  numResults: 20
)
```

### Phase 5: People (optional)
Find key people with `category: "people"`.

**people restrictions**: NO date filters, NO text filters, NO excludeDomains. includeDomains only accepts LinkedIn.

```
web_search_advanced_exa(
  query: "VP Engineering Anthropic",
  category: "people",
  numResults: 10
)
```

## Dynamic Tuning

- "a few" -> 10-20 results
- "comprehensive" -> 50-100 results
- User specifies number -> match it
- Ambiguous -> ask

## Query Variation

Generate 2-3 query variations per phase, run in parallel, merge and deduplicate. Exa returns different results for different phrasings.

## Output Format

1. Structured results (one company per row for discovery; sections for deep dive)
2. Sources (URLs with 1-line relevance)
3. Notes (uncertainty, conflicting data, gaps)
