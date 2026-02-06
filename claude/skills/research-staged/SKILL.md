---
name: research-staged
description: Multi-stage research workflow with approval checkpoints to prevent over-exploration
---

# Staged Research Workflow

## Overview
Conduct research in structured stages with explicit approval checkpoints.

## The Problem This Solves
User's insights report shows research sessions sometimes explore too broadly without checkpoints, wasting time on irrelevant areas.

## The Four Stages

### Stage 1: Scope Definition (WAIT for approval)
**Goal**: Define research boundaries

**Actions**:
- List all potential areas to investigate
- Identify key questions to answer
- Estimate breadth (3-5 topics vs single deep-dive)
- Recommend initial focus

**Output format**:
```
## Research Scope: {topic}

Areas to investigate:
1. Area A (high priority)
2. Area B (medium priority)
3. Area C (low priority)

Key questions:
- Question 1
- Question 2

Recommendation: Start with areas 1-2, depth over breadth
```

**STOP**: Present to user, WAIT for approval before Stage 2

### Stage 2: Initial Survey (WAIT for approval)
**Goal**: Quick scan of all approved areas

**Actions**:
- Use mgrep --web for each approved area
- Gather high-level information only
- Rank areas by relevance/complexity/risk
- Recommend which areas deserve deep analysis

**Output format**:
```
## Initial Survey Results

Area A: {summary} - Relevance: HIGH
Area B: {summary} - Relevance: MEDIUM

Recommendation: Deep dive into Area A (most critical), skip Area B (low value)
```

**STOP**: Present rankings, WAIT for approval before Stage 3

### Stage 3: Deep Analysis (on approved areas only)
**Goal**: Detailed investigation of approved areas

**Actions**:
- Detailed technical investigation
- Security/risk analysis
- Comparative evaluation
- Code examples/patterns
- Best practices

**Output format**:
```
## Deep Analysis: {approved area}

Technical details: ...
Security considerations: ...
Trade-offs: ...
Recommended approach: ...
```

**STOP**: Present analysis, WAIT for approval before Stage 4

### Stage 4: Documentation
**Goal**: Create structured, reusable documentation

**Actions**:
- Format as Obsidian note
- Include metadata (tags, dates, sources)
- Add actionable insights
- Reference sources with links

**Output format**: Markdown file in docs/ or Obsidian vault

## Usage

```bash
# Start staged research
/research-staged "AgentFi project analysis"
/research-staged "database MCP best practices"
```

## Key Principles

- **Never skip stages**: Each stage builds on previous
- **WAIT at every stage**: User must approve before continuing
- **Trim scope aggressively**: Recommend dropping low-value areas
- **Document sources**: Always cite where information came from
- **One stage per message**: Don't combine Stage 1+2
