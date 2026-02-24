---
description: "End-to-end refactoring: justify → scope → baseline → plan (optional) → execute → cleanup → review → ship"
argument-hint: "Refactoring goal (e.g., 'Extract auth logic into separate module' or 'Reduce coupling between order and payment services')"
---

# Refactor Workflow

You are orchestrating a complete refactoring pipeline. The core constraint: **behavior must not change — only structure improves.** Execute the phases below in order. Each phase uses a specific skill — invoke it via the Skill tool and follow it exactly.

**Refactoring goal:** $ARGUMENTS

## Document Output

Plans (if written) are saved in the project repo:

```
DOCS_ROOT = .plan/
```

If `.plan/` does not exist, create it (`mkdir -p .plan`).

### Vault Sync

After creating or updating any document in `DOCS_ROOT`, ask:
- Question: "同步此文档到 Obsidian vault？"
- Options: "Yes — sync to vault", "No — skip"

If yes: copy the file to `~/Documents/second-brain/Jobs/{project_name}/` where `{project_name}` is derived from `basename $(git rev-parse --show-toplevel)`. Create the directory if it doesn't exist.

---

## Phase 0: Refactoring Justification

Before committing resources, evaluate whether this refactoring is justified. This phase produces a GO / NO-GO / DEFER verdict with documented rationale.

### Step 1: Triage — Fast Track vs Full Assessment

**Step 1a:** Determine assessment depth.

Use AskUserQuestion to ask:
- Question: "How should we evaluate this refactoring?"
- Options: "Fast track — trigger is clear, skip justification analysis", "Full assessment — evaluate severity, cost, and benefit", "Skip Phase 0 — justification is already clear, go to Phase 1"

**If "Skip Phase 0":** Direct to Phase 1.

**Step 1b:** Identify the trigger.

**If "Fast track"**, use AskUserQuestion to ask:
- Question: "What is triggering this refactoring?"
- Options: "Rule of Three — third instance of duplication found", "Comprehension — cannot understand the code well enough to work on it", "Preparatory — must refactor before adding a feature or fixing a bug"

Record trigger category, automatic GO verdict, skip to Step 3.

**If "Full assessment"**, use AskUserQuestion to ask:
- Question: "What is triggering this refactoring?"
- Options: "Code review finding — reviewer identified structural issues", "Proactive improvement — code works but could be better", "Technical debt — accumulated shortcuts causing friction"

Record trigger category, proceed to Step 2.

### Step 2: Evidence Gathering + Cost-Benefit Analysis (Full Assessment Only)

#### 2a: Parallel Evidence Collection

Dispatch two Task agents in parallel:

```
Task(subagent_type="code-reviewer", prompt="Analyze the code area related to this refactoring goal: [refactoring goal]. Focus on STRUCTURAL quality issues only (not functional bugs). Categorize findings by severity: 1) CHANGE PREVENTERS (Divergent Change, Shotgun Surgery) — highest, multiplies cost of all future changes; 2) COUPLERS (Feature Envy, Inappropriate Intimacy) — high, makes isolated changes impossible; 3) BLOATERS (Long Method, Large Class, Long Parameter List) — medium, reduces comprehension; 4) DISPENSABLES (Dead Code, Duplicate Code, Lazy Class) — lower, cleanup improves clarity. For each finding report: category, severity, file:line, brief description, and change frequency (git log --oneline --since='6 months ago' <file> | wc -l).")

Task(subagent_type="architect", prompt="Evaluate architectural implications of this refactoring: [refactoring goal]. Analyze: 1) Current coupling — how many modules depend on the target code? (grep imports/references); 2) Change frequency — how often has this code changed in 6 months? (git log --since='6 months ago'); 3) Blast radius — how many files would this refactoring touch?; 4) Test coverage — do tests exist for the affected code?; 5) Anti-patterns — check for God Object, Tight Coupling, Big Ball of Mud. Return a structured assessment.")
```

#### 2b: 4W Framework Interactive Evaluation

Present the combined evidence summary from both agents, then walk through the 4W questions:

Use AskUserQuestion to ask:
- Question: "Who benefits from this refactoring?"
- Options: "Customers — enables a user-facing improvement", "Development team — faster feature velocity", "Both — customer feature requires structural change", "Unclear — primarily aesthetic improvement"

Use AskUserQuestion to ask:
- Question: "What measurable improvement do you expect?"
- Options: "Reduced change cost — currently touching N files for simple changes", "Reduced defect rate — structural issues cause recurring bugs", "Unblocked feature — cannot add feature without this refactoring", "No measurable benefit — subjective improvement only"

Use AskUserQuestion to ask:
- Question: "When do you expect to see the payoff?"
- Options: "Immediate — current sprint or task", "Near-term — within 2-4 weeks", "Long-term — months from now", "Unknown — speculative"

The fourth W (cost) is derived from the agent evidence: affected files count, risk level, test coverage status.

#### 2c: Verdict

**Kill signals (any one triggers NO-GO recommendation):**
- Code should be rewritten, not refactored (fundamentally broken)
- No test coverage and cannot add characterization tests
- Throwaway / prototype code with defined expiration
- Stable code that rarely changes + only Dispensable-level smells
- No measurable benefit + Unknown payoff timeline

**Verdict logic:**
- **GO** — Measurable benefit + reasonable payoff timeline + manageable cost; OR Change Preventer / Coupler smells in high-change-frequency code
- **NO-GO** — No measurable benefit + low change frequency; OR kill signal triggered
- **DEFER** — Real benefit exists but timing is wrong (missing test coverage, impending deadline, etc.) — record trigger conditions for revisiting

Use AskUserQuestion to ask:
- Question: "Recommendation: [GO/NO-GO/DEFER] — [one-sentence rationale]. Accept this verdict?"
- Options: "Accept verdict", "Override to GO — I have additional context", "Override to NO-GO — agree, let's stop", "Discuss further — brainstorm alternatives"

**If "Discuss further":** Invoke Skill `superpowers:brainstorming` with the full evidence context. When brainstorming completes, return to the verdict question (excluding the brainstorm option).

### Step 3: Record Decision

Record the decision to `.plan/YYYY-MM-DD-refactor-justification.md`:

```markdown
# Refactoring Justification: [goal]

## Verdict: [GO / NO-GO / DEFER]

## Trigger
[Selected trigger category from Step 1]

## Evidence (full assessment only)
### Code Smells
[Summary from code-reviewer agent]

### Architectural Impact
[Summary from architect agent]

## 4W Evaluation (full assessment only)
- **Who benefits:** [answer]
- **What improvement:** [answer]
- **When payoff:** [answer]
- **What cost:** [estimated files, risk level]

## Rationale
[1-3 sentences explaining the verdict]

## If DEFER
- **Revisit when:** [trigger conditions]
- **Prerequisites needed:** [e.g., add test coverage first]
```

**If GO:** Announce: **"Phase 0 complete — refactoring justified. Moving to Phase 1."**
**If NO-GO:** Announce: **"Phase 0 complete — refactoring not justified. Workflow ended."** Stop here.
**If DEFER:** Announce: **"Phase 0 complete — refactoring deferred. Decision recorded with trigger conditions."** Stop here.

---

## Phase 1: Scope & Baseline

### Step 1: Discover Affected Code

**Context hint:** Project architecture and conventions are already loaded from the project's CLAUDE.md. Use that as your starting point — only explore areas where CLAUDE.md lacks sufficient detail for the refactoring.

Invoke Skill `everything-claude-code:iterative-retrieval` with the refactoring goal above as context.

Follow the skill exactly — progressively refine searches (max 3 cycles) to find all files and dependencies affected by this refactoring: target files, consumers, related tests, downstream imports.

### Step 2: Establish Test Baseline

Run the project's existing test suite and record the baseline:
- Total tests and pass count
- Coverage percentage (if available)
- Build status

If test coverage for the affected code is insufficient (key paths untested), invoke Skill `superpowers:test-driven-development` to write characterization tests that capture the current behavior before any structural changes.

**Critical:** All existing tests must pass before proceeding. If any fail, fix them first — do not refactor broken code.

### Step 3: Record Baseline

Record the following in TodoWrite:
- Test baseline (pass count, coverage %)
- Affected files and their dependents
- Current code smells or structural issues identified

Then use AskUserQuestion to ask:
- Question: "Scope analysis complete. How should we proceed?"
- Options: "Simple refactor — proceed directly" (first/default), "Complex refactor — write a plan first", "Brainstorm refactoring approaches", "Stop workflow"

**If "Simple refactor":** Skip Phase 3. Proceed to Phase 2, then Phase 4.
**If "Complex refactor":** Proceed to Phase 2, then Phase 3 (plan), then Phase 4.
**If "Brainstorm refactoring approaches":** Invoke Skill `superpowers:brainstorming` with the scope analysis context. When brainstorming completes, return to this gate and ask again (excluding the brainstorm option).
**If "Stop workflow":** End here.

Remember the user's choice for Phase 4.

Announce: **"Phase 1 complete — scope analyzed and baseline established. Moving to Phase 2."**

---

## Phase 2: Worktree Setup

Use AskUserQuestion to ask:
- Question: "Create a git worktree for isolated development?"
- Options: "Skip — work on current branch" (first/default), "Create worktree"

- **If skip:** Continue on the current branch.
- **If create worktree:** Invoke Skill `superpowers:using-git-worktrees`. Follow the skill exactly.

Announce: **"Phase 2 complete. Moving to Phase 3."**

---

## Phase 3: Plan (conditional)

**If user chose "Simple refactor" in Phase 1:** Skip this phase entirely. Announce: **"Phase 3 skipped — simple refactor. Moving to Phase 4."**

**If user chose "Complex refactor" in Phase 1:**

Invoke Skill `superpowers:writing-plans`.

Follow the skill exactly. It will:
- Create a detailed refactoring plan with incremental steps
- Each step must preserve behavior — all existing tests pass after every step
- Save the plan to `.plan/YYYY-MM-DD-<refactor-summary>.md`
- Present the execution mode choice at the end:
  1. **Subagent-Driven** (this session) — fresh subagent per task with two-stage review
  2. **Parallel Session** (separate session) — batch execution with checkpoints

Use AskUserQuestion to confirm:
- Question: "Plan is ready. Proceed to implementation?"
- Options: "Start implementation", "Revise plan", "Stop workflow"

If "Revise plan": go back to writing-plans skill to iterate.
If "Stop workflow": end here.

Remember the user's execution mode choice for Phase 4.

### Context Protection & Compact

Before suggesting compact, ensure:
1. Plan file is saved to `.plan/`
2. TodoWrite records: test baseline, affected files, execution mode choice, current phase

Then suggest: **"The scope analysis and planning phases used significant context. Consider running `/compact` now — all decisions are persisted in TodoWrite and .plan/. After compact, I'll recover context by reading those files."**

Announce: **"Phase 3 complete — plan saved. Moving to Phase 4."**

---

## Phase 4: Execute

### Simple Refactor Path (user chose "Simple refactor" in Phase 1)

Execute the refactoring incrementally:
1. Make one structural change at a time
2. After each change, run the full test suite — all existing tests must pass
3. If any test fails, revert the last change and rethink the approach
4. Commit after each successful step

If the refactoring is more involved than expected (touches 5+ files or requires interface changes), pause and ask:
- Question: "This refactor is more complex than expected. Switch to planned approach?"
- Options: "Continue incrementally" (first/default), "Switch to plan-first approach"

If "Switch to plan-first approach": Go to Phase 3 (write a plan), then return to Phase 4 with subagent-driven execution.

### Complex Refactor Path (user chose "Complex refactor" in Phase 1)

Based on the execution mode chosen in Phase 3:

- **If Subagent-Driven:** Invoke Skill `superpowers:subagent-driven-development`. Follow the skill exactly.
- **If Parallel Session:** Invoke Skill `superpowers:executing-plans`. Follow the skill exactly.

**Important:** Both skills will attempt to invoke `superpowers:finishing-a-development-branch` at the end. Do NOT follow that final step — instead proceed to Phase 5.

### Context Protection & Compact

Before suggesting compact, ensure:
1. TodoWrite has all task statuses updated
2. Note the base branch name for later use

Then suggest: **"Refactoring complete. Consider running `/compact` before cleanup and verification — progress is tracked in TodoWrite and git history. After compact, I'll recover context from TodoWrite + git log."**

Announce: **"Phase 4 complete — refactoring done. Moving to Phase 5."**

---

## Phase 5: Cleanup

Use the Task tool to dispatch the `refactor-cleaner` agent:

```
Task(subagent_type="refactor-cleaner", prompt="Analyze the codebase for dead code, unused exports, and unused dependencies created by the recent refactoring. Follow your safety checklist: grep for references, check dynamic imports, review git history, and test after each removal batch.")
```

Review the agent's findings. If it identifies safe removals, let it proceed. For risky removals, verify manually before approving.

Announce: **"Phase 5 complete — cleanup done. Moving to Phase 6."**

---

## Phase 6: Verify & Review

### Step 1: Verification Loop

Invoke Skill `verification-loop`.

Follow the skill exactly — run all 6 verification phases (build, types, lint, tests, security, diff) and produce the VERIFICATION REPORT.

**Critical for refactoring:** Compare test results against the Phase 1 baseline recorded in TodoWrite. All previously passing tests must still pass. Coverage must not decrease.

If any phase fails, fix issues before proceeding.

### Step 2: Security Review

Invoke Skill `everything-claude-code:security-review`.

Follow the skill exactly — run through the security checklist relevant to the changes made.

Fix any critical security issues found.

### Step 3: Code Review

Invoke Skill `superpowers:requesting-code-review`.

Follow the skill exactly — dispatch the code-reviewer subagent to review the refactoring. The review should confirm:
- Behavior is preserved (no functional changes)
- Code quality has improved (the refactoring achieved its goal)
- No regressions introduced

Fix any Critical or Important issues found.

### Gate

Use AskUserQuestion to confirm:
- Question: "Verification, security review, and code review complete. Ship this refactor?"
- Options: "Continue to ship", "Fix issues first", "Stop workflow"

If "Fix issues first": address remaining issues, then re-run the failing verification steps.
If "Stop workflow": end here.

### Step 4: Update Project Docs

Check if the following files need updates based on the changes made:
- **CLAUDE.md**: Module boundaries, file organization, or architectural patterns
- **README.md**: New features, usage examples, configuration options, API endpoints
- **Makefile**: New commands, updated targets, new dependencies
- **Install scripts**: New dependencies, setup steps, environment variables
- **Other project docs**: CHANGELOG, API docs, deployment guides, docker-compose, etc.

For each file: read current content, compare against actual changes, update only what is factually outdated or missing. Do not rewrite unchanged sections.

Announce: **"Phase 6 complete — verified and reviewed. Moving to Phase 7."**

---

## Phase 7: Ship

Invoke Skill `superpowers:finishing-a-development-branch`.

Follow the skill exactly. It will:
1. Verify tests pass
2. Present 4 options: merge locally / push + PR / keep as-is / discard
3. Execute the chosen option
4. Clean up worktree if applicable

Announce: **"Refactor workflow complete."**
