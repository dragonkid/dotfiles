---
name: llm-agent-tool-calling-optimization
description: Use when LLM agents use server-side search tools (web_search, x_search) with excessive execution time, sequential iterative searching behavior, or need to constrain tool call budgets with parallel execution.
---

# LLM Agent Tool Calling Performance Optimization

## Overview
LLM agents tend to perform iterative sequential searches when calling server-side tools, causing linear time growth. Force parallel execution through prompt constraints and explicit tool call budgeting.

## When to Use
- Agent uses server-side search tools (web_search, x_search, etc.)
- Execution time is noticeably long (30-40s per round)
- Response analysis shows multi-round sequential tool calls
- Need to limit total tool calls across multiple search tools

## Core Pattern

Force parallel execution through prompt constraints with explicit numeric limits:

```python
# Add to system prompt
## Search Constraints (CRITICAL)
- Maximum N total searches: up to X tool_a + up to Y tool_b
- Plan ALL search queries upfront, then execute them in ONE parallel batch
- Do NOT add follow-up searches based on initial results
- Use OR operators to combine multiple intents into single queries
```

### Query Consolidation

**Before** (4 separate searches):
- "TOKEN launch"
- "TOKEN migration"
- "TOKEN listing"
- "TOKEN partnership"

**After** (1 consolidated search):
- "TOKEN (launch OR migration OR listing OR partnership)"

### Time Constraints

**Priority: Check SDK/API parameters first.**

1. **SDK supports time range** (e.g., `from_date`, `to_date`): Use SDK parameters directly (hard constraint).

2. **SDK does not support time range**: Add soft constraints in prompt:
```
## Time Constraints
- Focus on events from {search_from_date} onwards
- Skip/ignore any search results dated before {search_from_date}
```

## Diagnosis

Analyze API response for these indicators:
- `server_side_tools_used`: Number of tool calls
- Multiple `outputs` blocks: Indicates multi-round calls
- `reasoning_tokens`: Usually not the main bottleneck

## Common Mistakes
- Allowing iterative follow-up searches based on initial results
- Not setting explicit numeric limits on total tool calls
- Forgetting to use OR operators to consolidate related intents
