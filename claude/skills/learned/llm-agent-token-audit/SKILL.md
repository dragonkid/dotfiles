---
name: llm-agent-token-audit
description: Use when LLM agent token consumption is high, system prompt feels
  bloated, or setting up a new agent framework. Symptoms: slow responses, high
  cost, injected workspace files with template/placeholder content, unused
  skills loading every call.
---

# LLM Agent System Token Audit

Systematic audit for reducing fixed per-call token overhead in LLM agent
frameworks that inject workspace files into system prompts.

## When to Use

- Per-call token usage feels high or costs are growing
- Agent framework injects workspace files (OpenClaw, custom setups)
- Setting up new agent and want lean defaults
- After adding skills/tools, want to check overhead

## Audit Steps

### 1. Quantify

Find the framework's prompt report (`/context detail`, `sessions.json`,
equivalent). Record exact char counts per injected component.

### 2. Classify Waste

| Type | Signal | Fix |
|------|--------|-----|
| Dead files | One-time files still present | Delete |
| Template bloat | Unfilled placeholders/examples | Clear or fill with real content |
| Redundancy | Same info in multiple files | Deduplicate |
| Unused features | Skills/tools loaded but never used | Disable via config |
| Model mismatch | Expensive model on simple tasks | Reassign per-task |

### 3. Prioritize

- **P0:** Delete/clear (zero risk, immediate savings)
- **P1:** Config changes (disable skills, adjust settings)
- **P2:** Content rewrite, model tiering (more effort)

For file-level content optimization, use `optimize-llm-config-docs` skill.

### 4. Execute Safely

- Version-control before modifying
- Critical instruction files: edit incrementally with review
- Non-critical (templates, dead files): batch delete/clear
- Restart agent after config changes
- Verify with framework's context reporting tool

## Common Mistakes

- Rewriting critical instruction files in one shot without review
- Optimizing by gut feel instead of measuring first
- Disabling skills that are rare but critical
- Forgetting to restart after config changes
