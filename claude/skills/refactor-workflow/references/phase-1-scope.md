# Phase 1: Scope & Baseline

Read TodoWrite to recover: verdict from Phase 0.

## Step 1: Discover Affected Code

**Context hint:** Project architecture and conventions are already loaded from the project's CLAUDE.md. Use that as your starting point — only explore areas where CLAUDE.md lacks sufficient detail for the refactoring.

Invoke Skill `everything-claude-code:iterative-retrieval` with the refactoring goal above as context.

Follow the skill exactly — progressively refine searches (max 3 cycles) to find all files and dependencies affected by this refactoring: target files, consumers, related tests, downstream imports.

## Step 2: Establish Test Baseline

Run the project's existing test suite and record the baseline:
- Total tests and pass count
- Coverage percentage (if available)
- Build status

If test coverage for the affected code is insufficient (key paths untested), invoke Skill `superpowers:test-driven-development` to write characterization tests that capture the current behavior before any structural changes.

**Critical:** All existing tests must pass before proceeding. If any fail, fix them first — do not refactor broken code.

## Step 3: Record Baseline

Record the following in TodoWrite:
- Test baseline (pass count, coverage %)
- Affected files and their dependents
- Current code smells or structural issues identified

Announce: **"Phase 1 complete — scope analyzed and baseline established. Returning to state machine for Gate 1."**

Return to the state machine SKILL.md for Gate 1.
