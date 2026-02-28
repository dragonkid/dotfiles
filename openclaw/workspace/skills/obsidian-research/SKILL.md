---
name: obsidian-research
description: Research a topic with brainstorming dialogue, staged web exploration, and Obsidian vault integration. Triggers on /research command, deep research requests, or when user wants to explore a topic and save findings to their knowledge base.
user-invocable: true
---

# Obsidian Research

Staged research with brainstorming dialogue, saving results to `~/Documents/second-brain`.

Read `~/Documents/second-brain/CLAUDE.md` for vault conventions.

## Phase 1: Scope Definition

1. Search existing vault notes on the topic via grep
2. Ask questions ONE AT A TIME to refine scope:
   - What specific aspect interests you most?
   - What's the goal? (decision-making, learning, writing, etc.)
   - How deep? (quick overview vs deep-dive)
3. Prefer multiple choice questions
4. List potential areas to investigate
5. Recommend initial focus (depth over breadth)

**STOP**: Present scope summary, wait for approval.

## Phase 2: Survey + Exploration

1. Use **`mgrep --web "<query>"`** 搜索每个研究方向，找到相关 URL；用 **`web_fetch`** 获取页面内容
2. Cross-reference with existing vault notes
3. Rank areas by relevance
4. Propose 2-3 approaches/perspectives with trade-offs
5. Lead with recommended approach

**STOP**: Present survey results, wait for approval.

## Phase 3: Deep Analysis

1. Detailed investigation of approved areas
2. Present findings in 200-300 word sections
3. Ask after each section whether direction is right
4. Adjust based on feedback

**STOP**: Present analysis, wait for approval.

## Phase 4: Consolidate + Save

### ⚠️ Vault 文件写入规则
所有 vault 文件的创建和编辑必须通过 staging 目录中转（`~/.openclaw/workspace/.vault-staging/`）：
1. 编辑已有文件：先 `cp` 到 staging，编辑完再 `cp` 回 vault
2. 创建新文件：先在 staging 写好完整内容，再一次性 `cp` 到 vault
3. 禁止直接在 vault 目录内多次写入同一文件

### Step 4a: Handle existing related notes

For each related vault note found in Phase 1, present options:
- **Merge**: Absorb unique content into new note, delete old
- **Update**: Keep existing, add new findings + bidirectional `[[wikilinks]]`
- **Link only**: Just add `[[wikilinks]]` in both directions
- **Skip**: No relationship worth maintaining

### Step 4b: Save research note

Save to `~/Documents/second-brain/Research/<topic-slug>.md`:

```yaml
---
date: YYYY-MM-DD
tags: [status/seed, source/research]
aliases: []
---
```

Sections: `## Summary`, `## Key Findings`, `## Sources`, `## Related`

### Step 4c: Execute decisions

- Merge → append unique content, delete original
- Update → add findings + wikilinks
- Link only → add wikilinks both directions

Report: file path, notes merged/updated/linked.

## Command

```
/research <topic>
```

If no topic provided, ask what to research.
