---
name: deep-research
description: Multi-source deep research using Exa MCP. Breaks topics into sub-questions, searches with category-aware queries, deep-reads key sources, and synthesizes cited reports. Use when the user wants thorough research, deep dives, competitive analysis, technology evaluation, tool/library comparison, company research, market landscape analysis, or any question requiring synthesis from multiple sources. Triggers on "research", "deep dive", "investigate", "what's the current state of", "compare", "对比", "比较", "哪个好", "推荐几个", "evaluate", "帮我调研", "深入研究", "研究下", "research this company", "competitor analysis", "company overview", "market landscape", "who are the players in", "alternatives to".
context: fork
---

# Deep Research (Exa)

Produce thorough, cited research reports by breaking topics into sub-questions and searching with Exa's category-aware tools.

## Token Isolation

Always spawn Task agents for search and deep-read steps. Agent returns distilled findings only — main context stays clean.

When dispatching agents, include tool routing and category restrictions in the prompt. Agents don't see this skill — they only know what you tell them. Example:

```
Research [topic]. For GitHub projects, use `gh api repos/{owner}/{repo}` for
metadata/README — not web search. For community reception, use Exa
web_search_advanced_exa with category "tweet" or includeDomains ["reddit.com"].
Category restrictions: "company" allows NO date/text/domain filters;
"tweet" allows NO includeText/excludeText/includeDomains/excludeDomains.
Return distilled findings with source URLs.
```

## Tool Routing

Not everything should go through Exa. Pick the right tool for each data source:

| Data source | Tool | Why |
|-------------|------|-----|
| GitHub repo metadata (stars, language, topics) | `gh api repos/{owner}/{repo}` | Structured data, zero noise, instant |
| GitHub README | `gh api repos/{owner}/{repo}/readme --jq '.content' \| base64 -d` | Full content, no web scraping |
| Community discussions (Reddit, HN, Twitter) | Exa `web_search_advanced_exa` | Category-aware, highlights mode |
| News, papers, blogs | Exa `web_search_advanced_exa` | Category filters, date filters |
| Full page content | Exa `crawling_exa` | Deep reads, maxCharacters control |

When dispatching research agents, include tool routing in the prompt so agents use the right tool for each source.

## Workflow

### Step 1: Understand the Goal

Ask 1-2 quick clarifying questions:
- "What's your goal — learning, making a decision, or writing something?"
- "Any specific angle or depth you want?"

If the user says "just research it" — skip ahead with reasonable defaults.

### Step 1.5: Vault Cross-Reference

Before web research, check the Obsidian vault for existing notes on the topic. This avoids duplicating prior research and surfaces useful context:

```
Grep pattern="<topic keywords>" path="~/Documents/second-brain" glob="*.md"
```

If related notes found:
- Read the most relevant 2-3 notes for context
- Note what's already covered vs what's missing — focus web research on gaps
- Include existing note titles in the report's `## Related` section later

If nothing found, proceed directly to web research.

### Step 2: Plan Sub-Questions

Break the topic into 3-5 research sub-questions. For each, decide the best Exa category:

| Sub-question type | Tool | Category | Why |
|-------------------|------|----------|-----|
| Current events, press | `web_search_advanced_exa` | `news` | Journalism, announcements |
| Academic findings | `web_search_advanced_exa` | `research paper` | arXiv, peer-reviewed |
| Company/market data | `web_search_advanced_exa` | `company` | Homepages, metadata |
| Community sentiment | `web_search_advanced_exa` | `tweet` | Developer opinions, discussions |
| Expert perspectives | `web_search_advanced_exa` | `personal site` | Independent analysis, blogs |
| General / mixed | `web_search_exa` | (none) | Broad coverage |

### Step 3: Search with Query Variations

For each sub-question, generate 2-3 keyword variations — Exa returns different results for different phrasings. Run variations in parallel, merge and deduplicate.

Example for sub-question "What are the main AI applications in healthcare?":
- Variation 1: "AI applications healthcare clinical deployment 2025"
- Variation 2: "machine learning medical diagnosis treatment real-world"
- Variation 3: "artificial intelligence hospital workflow automation"

**Search parameters:**
- Use `highlights` mode for search results (10x fewer tokens than full text)
- Set `numResults: 10-15` per variation
- For news: add `startPublishedDate` for recency (last 12 months)
- For research papers: add `includeDomains: ["arxiv.org"]` if needed
- Aim for 15-30 unique sources total across all sub-questions

### Step 4: Category Filter Restrictions

These restrictions cause 400 errors if violated:

- **`company`**: NO date filters, NO text filters, NO includeDomains/excludeDomains
- **`people`**: NO date filters, NO text filters, NO excludeDomains. includeDomains only accepts LinkedIn
- **`tweet`**: NO includeText, excludeText, includeDomains, excludeDomains, moderation
- **`financial report`**: NO excludeText
- **`research paper`**, **`personal site`**, **`news`**: all filters work
- **Universal**: `includeText`/`excludeText` only support single-item arrays

When a category restricts filters you need, drop the category and use `web_search_exa` with keywords in the query instead.

### Step 5: Deep-Read Key Sources

For the 3-5 most promising URLs from search results, fetch full content:

```
crawling_exa(url: "<url>", maxCharacters: 10000)
```

Use `text` mode (not highlights) for deep reads — you need the full context to synthesize accurately.

### Step 6: Synthesize Report

Structure the report with inline citations:

```markdown
# [Topic]: Research Report
*Generated: [date] | Sources: [N] | Confidence: [High/Medium/Low]*

## Executive Summary
[3-5 sentence overview of key findings]

## 1. [First Major Theme]
[Findings with inline citations]
- Key point ([Source Name](url))
- Supporting data ([Source Name](url))

## 2. [Second Major Theme]
...

## Key Takeaways
- [Actionable insight 1]
- [Actionable insight 2]

## Sources
1. [Title](url) — [one-line summary]
2. ...

## Methodology
Searched [N] queries across [categories used]. Analyzed [M] sources.
Sub-questions investigated: [list]
```

### Step 7: Deliver

- Short topics: post full report in chat
- Long reports: post executive summary + key takeaways, save full report to a file

## Parallel Execution

For broad topics, parallelize sub-questions across Task agents:

```
Launch 3 research agents:
1. Agent 1: Sub-questions 1-2 (news + research paper categories)
2. Agent 2: Sub-questions 3-4 (company + general categories)
3. Agent 3: Sub-question 5 + cross-cutting themes (tweet + personal site)
```

Each agent searches, reads sources, and returns findings. Main session synthesizes into the final report.

## Quality Rules

1. Every claim needs a source. No unsourced assertions.
2. Cross-reference: if only one source says it, flag as unverified.
3. Recency matters: prefer sources from the last 12 months.
4. Acknowledge gaps: if you couldn't find good info, say so.
5. No hallucination: if you don't know, say "insufficient data found."
6. Separate fact from inference: label estimates and opinions clearly.

## Company Research Shortcut

When the research target is a company or market landscape, use this pre-planned sub-question template instead of designing from scratch:

1. **Discovery** — `category: "company"`, find companies in the space
2. **Deep dive** — no category, `includeDomains` for TechCrunch/Crunchbase/Bloomberg
3. **News** — `category: "news"`, `startPublishedDate` for recent coverage
4. **Social** — `category: "tweet"`, developer/user sentiment
5. **People** — `category: "people"`, key executives and team

**Dynamic tuning for company lists:**
- User says "a few" → `numResults: 10-20`
- User says "comprehensive" → `numResults: 50-100`
- User specifies a number → match it

**Output format for company lists:** use structured table (name, description, funding, headcount) instead of prose. For single-company deep dives, use the standard report template.

## Deep Search (Optional)

For complex topics that benefit from structured output, use Exa's deep search:

```
web_search_advanced_exa(
  query: "compare frontier AI model releases 2025-2026",
  type: "deep",
  numResults: 10
)
```

Deep search runs multiple query variations internally and returns synthesized results. Use `type: "deep"` when a single sub-question is complex enough to warrant multi-step reasoning. Don't use for simple factual lookups — `auto` is faster and cheaper.
