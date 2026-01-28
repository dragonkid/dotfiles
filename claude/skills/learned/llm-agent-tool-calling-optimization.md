# LLM Agent Tool Calling Performance Optimization

**Extracted:** 2026-01-28
**Context:** When LLM agents use server-side tools (web_search, x_search), execution time is excessive

## Problem

LLM agents tend to perform "iterative searching" when calling search tools:
1. First round of searches → wait for results
2. Analyze results, find gaps → second round of searches
3. Continue supplementing → third round of searches

Each round includes network latency + search engine processing time (30-40s). Sequential execution causes linear growth in total time.

## Solution

Force parallel execution through prompt constraints:

```
## Search Constraints (CRITICAL)
- Plan ALL search queries upfront, then execute them in ONE parallel batch
- Do NOT add follow-up searches based on initial results
```

### Time Constraints

**Priority: Check SDK/API parameters first.**

1. **SDK supports time range** (e.g., `from_date`, `to_date`): Use SDK parameters directly. This is a hard constraint - the API will filter results server-side.

2. **SDK does not support time range**: Add soft constraints in prompt as fallback:

```
## Time Constraints
- Focus on events from {search_from_date} onwards
- Skip/ignore any search results dated before {search_from_date}
```

Note: Prompt-based time constraints are soft constraints. The model will try to follow them, but search engines may still return older content.

## Diagnosis Method

Analyze from API response:
- `server_side_tools_used`: Number of tool calls
- Multiple `outputs` blocks: Indicates multi-round calls
- `reasoning_tokens`: Reasoning consumption (usually not the main bottleneck)

## Alternative Approaches (Context-Dependent)

| Approach | Trade-offs |
|----------|------------|
| Predefined search queries | Reduces flexibility but ensures coverage of specific topics. Good for well-defined domains. |
| Add year to search terms | May miss historical events, but helps focus on recent information when recency matters. |
| Limit search count | Most SDKs don't support this, but if available, useful for cost control. |

Choose based on your specific requirements:
- **Predefined queries**: When you know exactly what information you need
- **Year in search terms**: When only recent events matter
- **Search count limits**: When cost/latency is critical and some information loss is acceptable

## When to Use

- Agent uses server-side search tools (web_search, x_search, etc.)
- Execution time is noticeably long
- Response analysis shows multi-round sequential tool calls
