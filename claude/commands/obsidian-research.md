---
description: Research a topic with brainstorming dialogue, staged exploration, and vault integration
---

Research and explore: $ARGUMENTS

This command combines brainstorming dialogue with staged research, saving results to the Obsidian vault.

## Phase 1: Scope Definition (brainstorming mode)

Understand what the user wants to research through dialogue:
- Check existing vault notes on the topic: use mgrep to search ~/Documents/second-brain
- Ask questions ONE AT A TIME to refine scope:
  - What specific aspect interests you most?
  - What's the goal? (decision-making, learning, writing an article, etc.)
  - How deep? (quick overview vs deep-dive)
- Prefer multiple choice questions when possible
- List all potential areas to investigate
- Recommend initial focus (depth over breadth)

**STOP**: Present scope summary, WAIT for approval before Phase 2.

## Phase 2: Survey + Exploration

- Use mgrep --web --answer for each approved area
- Cross-reference with existing vault notes
- Rank areas by relevance
- Propose 2-3 approaches/perspectives with trade-offs if applicable
- Lead with recommended approach and explain why

**STOP**: Present survey results, WAIT for approval before Phase 3.

## Phase 3: Deep Analysis (approved areas only)

- Detailed investigation of approved areas
- Present findings in sections of 200-300 words
- Ask after each section whether it looks right
- Be ready to adjust direction based on feedback

**STOP**: Present analysis, WAIT for approval before Phase 4.

## Phase 4: Consolidate + Save to Vault

### Step 4a: Handle existing related notes

Review the related vault notes found in Phase 1. For each related note, present the user with options:
- **Merge**: Absorb the existing note's unique content into the new research note, then delete the old note
- **Update**: Keep the existing note but update it with new findings and add bidirectional [[wikilinks]]
- **Link only**: Leave the existing note unchanged, just add [[wikilinks]] in both directions
- **Skip**: No relationship worth maintaining

Ask the user to decide for each related note (or batch-decide if there are many).

### Step 4b: Save research note

Save to ~/Documents/second-brain/Research/<topic-slug>.md with:
- Obsidian frontmatter: date, tags, aliases
- ## Summary
- ## Key Findings
- ## Sources (URLs with descriptions)
- ## Related (wikilinks to related vault notes)

### Step 4c: Execute decisions

- For "Merge" notes: append unique content to research note, delete the original file
- For "Update" notes: update them with new findings, add [[wikilinks]] to the research note
- For "Link only" notes: add [[wikilinks]] in both the research note and the existing note

After saving, report: file path, notes merged/updated/linked, notes deleted.

If $ARGUMENTS is empty, ask what the user wants to research.
