---
description: "Analyze observations → extract instincts → cluster → generate skills"
argument-hint: "Optional: --instincts-only (stop after extraction) or --evolve-only (cluster existing instincts, skip extraction)"
---

# Analyze Observations

Analyze `~/.claude/homunculus/observations.jsonl`, extract behavioral instincts, cluster them, and generate learned skills.

**Arguments:** $ARGUMENTS

## Paths

```
OBSERVATIONS = ~/.claude/homunculus/observations.jsonl
INSTINCTS    = ~/.claude/homunculus/instincts/personal/
EVOLVED      = ~/.claude/homunculus/evolved/
SKILLS       = ~/.claude/skills/learned/
ARCHIVE      = ~/.claude/homunculus/observations.archive/
```

---

## Phase 1: Analyze Observations

**Skip if** `$ARGUMENTS` contains `--evolve-only`.

Run: `python3 ~/.claude/scripts/analyze-observations.py OBSERVATIONS`

Present the output. Wait for user acknowledgment before proceeding.

---

## Phase 2: Extract Instincts

**Skip if** `$ARGUMENTS` contains `--evolve-only`.

Analyze the observations for these 4 pattern types:

### Pattern 1: User Corrections
When a user's follow-up corrects Claude's previous action:
- "No, use X instead of Y"
- "Actually, I meant..."
- Immediate undo/redo patterns

→ Instinct: "When doing X, prefer Y" (domain: `workflow` or `code-style`)

### Pattern 2: Error Resolutions
When an error is followed by a fix:
- Tool output contains error
- Next few tool calls fix it
- Same error type resolved similarly multiple times

→ Instinct: "When encountering error X, try Y" (domain: `debugging`)

### Pattern 3: Repeated Workflows
Same sequence of tools used multiple times:
- Same tool sequence with similar inputs
- File patterns that change together
- Use bigram data from Phase 1

→ Instinct: "When doing X, follow steps Y, Z, W" (domain: `workflow`)

### Pattern 4: Tool Preferences
Certain tools consistently preferred:
- Always uses Grep before Edit
- Prefers Read over Bash cat
- Uses specific Bash commands for certain tasks

→ Instinct: "When needing X, use tool Y" (domain: `workflow`)

### Confidence Calculation

| Observations | Confidence |
|-------------|------------|
| 1-2 | 0.3 (tentative) |
| 3-5 | 0.5 (moderate) |
| 6-10 | 0.7 (strong) |
| 11+ | 0.85 (very strong) |

### Instinct File Format

Write each instinct as `INSTINCTS/<id>.md`:

```markdown
---
id: <kebab-case-id>
trigger: "when <condition>"
confidence: <0.3-0.9>
domain: "<workflow|code-style|debugging|infrastructure|testing>"
source: "session-observation"
---

# <Title>

## Action
<What to do when triggered>
```

### Rules

- One file per pattern, minimum 3 observations to create
- Narrow triggers over broad ones
- Skip trivial or obvious patterns
- Present proposed instincts to user for confirmation before writing
- If an instinct with the same id already exists, update confidence (increase by +0.05 per confirming observation) rather than creating a duplicate

**Stop here if** `$ARGUMENTS` contains `--instincts-only`.

---

## Phase 3: Cluster (Evolve)

Read all `.md` files from `INSTINCTS`. **Skip instincts that have `evolved_to` in their frontmatter** (already consumed by a previous run). Group remaining by:
- Domain similarity
- Trigger pattern overlap
- Action sequence relationship

For each cluster of 3+ related instincts, determine type:

| Type | Criteria |
|------|----------|
| **Skill** | Auto-triggered behaviors, patterns, style enforcement |
| **Command** | User-invoked repeatable workflows |
| **Agent** | Complex multi-step processes needing isolation |

### Actionability Gate

Before proposing a cluster for evolution, verify ALL three criteria:

| Criterion | Pass | Fail |
|-----------|------|------|
| **Prescriptive** | "Do X when Y" | "Sessions tend to be Bash-heavy" |
| **Non-obvious** | Not already in CLAUDE.md or rules/ | "Edit before Read" (already a rule) |
| **Decision-changing** | Changes a specific tool/approach choice | "User prefers short sessions" |

Skip clusters that fail any criterion — note as "observed, not actionable".

### Check for Overlap

Before proposing new skills, read existing `SKILLS` directory. If a cluster covers the same domain as an existing skill, suggest **merging** into the existing skill rather than creating a new one.

Present clusters and overlap analysis to user. Only proceed to Phase 4 with explicit approval.

---

## Phase 4: Generate Skills

For each approved cluster, invoke `superpowers:writing-skills` and follow its guidelines.

Create `SKILLS/<skill-name>/SKILL.md` with:
- YAML frontmatter: `name` (hyphens only) and `description` (starts with "Use when...", triggers/symptoms only, no workflow summary)
- Concise overview (1-2 sentences)
- Quick Reference table
- Core Pattern (before/after or decision logic)
- When NOT to use
- No statistics, no evidence, no provenance sections

Record in `EVOLVED/skills/<skill-name>.md`:
```markdown
---
name: <skill-name>
type: skill
evolved_from:
  - <instinct-id-1>
  - <instinct-id-2>
---
Evolved to: `skills/learned/<skill-name>/SKILL.md`
```

Mark consumed instincts by adding `evolved_to: <skill-name>` to their YAML frontmatter. This prevents re-clustering in future runs.

---

## Phase 5: Archive

Move processed observations to archive:

```bash
mkdir -p ARCHIVE
mv OBSERVATIONS ARCHIVE/processed-$(date +%Y%m%d-%H%M%S).jsonl
touch OBSERVATIONS
```
