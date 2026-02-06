---
name: optimize-llm-config-docs
description: Use when creating or reviewing LLM configuration files (skills, CLAUDE.md, prompts) that contain verbose explanations, troubleshooting sections, or historical context consuming tokens without providing actionable guidance
---

# Optimize LLM Configuration Documents

## Overview

**LLM configuration documents should contain only actionable patterns, not human-oriented explanations.** Remove verbose descriptions, troubleshooting guides, and statistical predictions that waste tokens without enabling execution.

## When to Use

Apply when:
- Creating new skills or configuration files
- Reviewing existing LLM documentation
- Noticing sections with "Symptoms", "Troubleshooting", "Expected Improvements", "Based on N sessions"
- Converting human documentation to LLM-consumable format
- File exceeds recommended length (skills >500 words, CLAUDE.md >300 lines)
- Consolidating multiple reference topics into accessible structure (skills with Read tool only)

## Applicability by File Type

| File Type | Inline Optimization (Steps 1-4) | Progressive Disclosure (Step 5) |
|-----------|--------------------------------|--------------------------------|
| **CLAUDE.md** | ✅ Always apply | ❌ Auto-loaded, no lazy loading |
| **Hook configs** | ✅ Always apply | ❌ Auto-executed, no subdocs |
| **Skills with Read tool** | ✅ First optimize inline | ✅ Then split if >200 lines |
| **Skills without Read** | ✅ Only option | ❌ Can't lazy-load subdocs |

**Key insight**: Progressive disclosure requires execution control (skills can choose when to Read). Auto-loaded configs must remain compact via inline optimization.

## Quick Reference

| Remove ❌ | Keep ✅ |
|-----------|---------|
| "Expected Improvements" / statistics | Rules and directives ("Use X for Y") |
| "Symptoms" / problem descriptions | Workflow steps (1→2→3) |
| "Troubleshooting" sections | Decision trees ("If X, then Y") |
| "Key Limitations" / background | Anti-patterns ("❌ Don't X, ✅ Do Y") |
| Historical context ("Based on 169 sessions") | Configuration examples |
| Problem numbering (Problem 1/2/3) | Commands and syntax |
| Explanatory phrases ("This is because...") | Code snippets |
| Structure overload (single 500+ line file) | Modular index + subdocuments (skills only) |

## Core Pattern

**Before** (verbose, human-oriented - 13 lines):
```markdown
### Problem 1: Claude often implements without providing plan (37 rejections)

**Symptoms**:
- You say "how to implement X", Claude immediately starts coding
- You're forced to interrupt and request plan first
- Wastes time and tokens

**Solutions**:
1. ✅ CLAUDE.md contains "BLOCKING REQUIREMENT" rule
2. ✅ Use explicit trigger words...

## Expected Improvements
Based on 169 sessions, rejected operations drop from 37 to <10.
```

**After** (actionable, LLM-optimized - 8 lines):
```markdown
### Plan Before Implementation

**Rules**:
- Use explicit trigger words: "give me a plan"
- Use `/brainstorming` skill
- Use `/writing-plans` skill

**Examples**:
❌ Wrong: "Help me add authentication"
✅ Correct: "Give me a plan for authentication"
```

## Implementation

### Step 1: Scan for Human-Oriented Sections

Search for these keywords:
- "Symptoms", "Problem", "Issue", "Troubleshooting"
- "Limitations", "Improvements", "Expected"
- "Based on", "sessions", "analysis"

### Step 2: Identify Actionable vs Explanatory

Ask: "Can an LLM execute this directly?"
- No → remove or rewrite as rule/pattern
- Yes → keep

### Step 3: Restructure to Patterns

| Convert from → | Convert to → |
|----------------|--------------|
| Problems | Rules |
| Symptoms | Anti-patterns |
| Solutions | Workflows |
| Troubleshooting | Commands/Syntax |

### Step 4: Verify Language

- ✅ Use imperative voice ("Use X", "Apply Y")
- ❌ Remove qualifiers ("usually", "often", "typically")
- ✅ Keep examples concrete

### Step 5: Progressive Disclosure (Skills Only)

**Applicable to**: Skills with Read tool access
**Not applicable to**: CLAUDE.md, hook configs (auto-loaded, no lazy loading)

**When to split documents:**
- Skill file exceeds 200 lines after inline optimization
- Contains multiple independent reference topics (plugins + workflow + database)
- Has sections rarely needed together (mutually exclusive use cases)
- Skill has Read tool capability for lazy loading

**Pattern: Index SKILL.md + Subdocuments**

**Index file (SKILL.md)**:
- Keep <50 lines
- Topic table with descriptions
- Usage examples (`/skill-name topic-name`)
- Links to subdocuments for Read tool

**Subdocuments** (topic-name.md):
- Self-contained reference content
- Read by skill on demand via Read tool
- Can be verbose without token penalty
- Lives in same directory as SKILL.md

**Example** (from `/guide` skill):
```markdown
## Available Topics

| Topic | Content |
|-------|---------|
| `plugins` | 17 plugins overview, decision tree |
| `workflow` | Optimization patterns |

## Usage
/guide plugins    # Skill reads plugins.md
/guide workflow   # Skill reads workflow.md
```

**Why CLAUDE.md can't use this**:
- CLAUDE.md auto-loaded in every conversation (no lazy loading)
- No skill wrapper to selectively read subdocuments
- Must optimize via Steps 1-4 (inline reduction)

**Benefits** (skills only):
- Reduces default context load (41 lines vs 768 lines total)
- Preserves detailed documentation
- User-controlled exploration depth

**Decision workflow for mixed problems**:
1. Apply inline optimization first (Steps 1-4)
2. Evaluate resulting size
3. If still >200 lines with multiple topics → progressive disclosure
4. Keep as single file if <200 lines or single cohesive topic

## Common Mistakes

**Mistake**: Removing all explanatory text, making rules unclear
**Fix**: Keep brief context for WHY a rule exists if it affects understanding

**Mistake**: Converting troubleshooting to commands that LLM can't execute (user environment issues)
**Fix**: Only keep troubleshooting if LLM can apply the fix (code changes, config updates)

**Mistake**: Keeping "Expected Improvements" thinking it motivates compliance
**Fix**: LLMs don't need motivation - they need clear instructions

**Mistake**: Splitting large skill into multiple independent skills (e.g., `/react-patterns`, `/vue-patterns`, `/svelte-patterns`)
**Fix**: Use progressive disclosure pattern - one skill with subdocuments (e.g., `/frontend-patterns` reads `react.md`, `vue.md`, `svelte.md` on demand)

## Real-World Impact

Typical reduction: 25-40% content size while preserving all actionable information.

This session results:
- workflow.md: -31% (193 → 133 lines)
- plugins.md: -46% (271 → 145 lines)
- database-mcp.md: -27% (333 → 242 lines)
