# Phase 1: Diagnose

## Step 1: Gather Context

**Context hint:** Project architecture and conventions are already loaded from the project's CLAUDE.md. Use that as your starting point — only explore areas where CLAUDE.md lacks sufficient detail for the bug.

Invoke Skill `everything-claude-code:iterative-retrieval` with the bug report above as context.

Follow the skill exactly — progressively refine searches (max 3 cycles) to find the relevant code paths, files, and dependencies related to the bug.

## Step 2: Root Cause Analysis

Invoke Skill `superpowers:systematic-debugging` with the bug report and gathered context.

Follow the skill exactly. It will:
- Investigate root cause before proposing any fix
- Analyze patterns by comparing working vs broken code
- Form and test hypotheses with minimal changes
- Identify the root cause and affected code paths

The skill has built-in gates: no fixes before root cause investigation is complete. If 3+ fix attempts fail, the skill will stop and discuss architecture.

When diagnosis completes, record the following in TodoWrite:
- Root cause description (1-2 sentences)
- Affected files and code paths
- Confirmed hypothesis

Announce: **"Phase 1 complete — root cause identified. Returning to state machine for Gate 1."**

Return to the state machine SKILL.md for Gate 1.
