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
| Limit search count | See "Explicit Tool Call Budgeting" section below. |

Choose based on your specific requirements:
- **Predefined queries**: When you know exactly what information you need
- **Year in search terms**: When only recent events matter
- **Search count limits**: When cost/latency is critical and some information loss is acceptable

### Explicit Tool Call Budgeting

When LLMs have access to multiple search tools, they tend to over-search. Add explicit numeric limits in prompts:

```
## Search Constraints (CRITICAL)
- Maximum N total searches: up to X tool_a + up to Y tool_b
- Plan ALL search queries upfront, then execute them in ONE parallel batch
- Do NOT add follow-up searches based on initial results
- Use OR operators to combine multiple intents into single queries
```

**Budget allocation strategy:**
- Allocate more queries to higher-value tools (e.g., x_search for crypto projects)
- Example: `4 x_search + 3 web_search = 7 total` (reduced from ~10 uncontrolled)

**Query consolidation:**
- Group related intents using OR operators
- Before: 4 separate searches for "launch", "migration", "listing", "partnership"
- After: 1 search for "TOKEN (launch OR migration OR listing OR partnership)"

**Structured query allocation template:**
```
1. **tool_a** (up to X queries):
   - Query 1: [Primary intent]
   - Query 2: [Secondary intent]
   ...

2. **tool_b** (up to Y queries):
   - Query 1: [Primary intent]
   ...
```

## When to Use

- Agent uses server-side search tools (web_search, x_search, etc.)
- Execution time is noticeably long
- Response analysis shows multi-round sequential tool calls
