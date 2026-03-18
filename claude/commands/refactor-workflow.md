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
DOCS_ROOT = docs/superpowers/
```

If `docs/superpowers/` does not exist, create it (`mkdir -p docs/superpowers/{specs,plans}`).

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

Record the decision to `docs/superpowers/YYYY-MM-DD-refactor-justification.md`:

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

## Phase 2: Branch Setup

Use AskUserQuestion to ask:
- Question: "How to isolate this refactoring work?"
- Options: "Create worktree (Recommended)", "Create refactor branch"

### If worktree:

Invoke Skill `superpowers:using-git-worktrees`. Follow the skill exactly.

Record `BRANCH_MODE=worktree` and the base branch name for Phase 7.

### If refactor branch:

Create and switch to a new branch from the current HEAD:

```bash
# Derive branch name from refactoring goal (kebab-case, max 50 chars)
# e.g., "Extract auth logic" → refactor/extract-auth-logic
git checkout -b refactor/<refactor-slug>
```

Record `BRANCH_MODE=branch` and the base branch name (the branch you were on before switching) for Phase 7.

Announce: **"Phase 2 complete. Moving to Phase 3."**

---

## Phase 3: Plan (conditional)

**If user chose "Simple refactor" in Phase 1:** Skip this phase entirely. Announce: **"Phase 3 skipped — simple refactor. Moving to Phase 4."**

**If user chose "Complex refactor" in Phase 1:**

### Step 0: Reuse Discovery

Before writing the plan, invoke Skill `everything-claude-code:search-first` with the refactoring goal as context. Feed findings into the plan — reference existing code rather than proposing new implementations of already-available functionality.

### Step 1: Write the Plan

Invoke Skill `superpowers:writing-plans`.

Follow the skill exactly. It will:
- Create a detailed refactoring plan with incremental steps
- Each step must preserve behavior — all existing tests pass after every step
- Save the plan to `docs/superpowers/plans/YYYY-MM-DD-<refactor-summary>.md`
- Present the execution mode choice at the end:
  1. **Subagent-Driven** (recommended) — fresh subagent per task with two-stage review
  2. **Inline Execution** — execute tasks in this session with checkpoints

Use AskUserQuestion to confirm:
- Question: "Plan is ready. Proceed to implementation?"
- Options: "Start implementation", "Revise plan", "Stop workflow"

If "Revise plan": go back to writing-plans skill to iterate.
If "Stop workflow": end here.

Remember the user's execution mode choice for Phase 4.

### Context Protection & Compact

Before suggesting compact, ensure:
1. Plan file is saved to `docs/superpowers/`
2. TodoWrite records: test baseline, affected files, BRANCH_MODE (branch/worktree), base branch name, execution mode choice, current phase

Then suggest: **"The scope analysis and planning phases used significant context. Consider running `/compact` now — all decisions are persisted in TodoWrite and docs/superpowers/. After compact, I'll recover context by reading those files."**

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

### Step 1: Scope Analysis — Determine Review Matrix

Before dispatching any reviewers, analyze the change scope to build the full review list.

```bash
# Collect scope signals (run in main session, fast)
BASE=$(git merge-base HEAD <BASE_BRANCH>)
CHANGED_DIRS=$(git diff --name-only $BASE..HEAD | cut -d/ -f1-2 | sort -u | wc -l)
HAS_GO=$(test -f go.mod && echo yes || echo no)
HAS_PYTHON=$(test -f pyproject.toml -o -f setup.py -o -f requirements.txt && echo yes || echo no)
HAS_TS=$(test -f tsconfig.json && echo yes || echo no)
HAS_RUST=$(test -f Cargo.toml && echo yes || echo no)
HAS_CPP=$(test -f CMakeLists.txt -o -f Makefile.am && echo yes || echo no)
HAS_KOTLIN=$(find . -maxdepth 3 -name "*.kt" -quit 2>/dev/null && echo yes || echo no)
TESTS_CHANGED=$(git diff --name-only $BASE..HEAD | grep -c '_test\.\|\.test\.\|test_\|_spec\.' || true)
```

**Replace `<BASE_BRANCH>`** with the actual base branch name recorded in Phase 2.

Build the agent list:

| Agent | Condition | Always/Conditional |
|-------|-----------|-------------------|
| Verification loop | Always | Always |
| Security review | Always | Always |
| Code review | Always | Always |
| Simplify review | Always | Always |
| Architecture review | CHANGED_DIRS >= 3 | Conditional |
| Go review | HAS_GO = yes | Conditional |
| Python review | HAS_PYTHON = yes | Conditional |
| TypeScript review | HAS_TS = yes | Conditional |
| Rust review | HAS_RUST = yes | Conditional |
| C++ review | HAS_CPP = yes | Conditional |
| Kotlin review | HAS_KOTLIN = yes | Conditional |
| Test coverage analysis | TESTS_CHANGED > 0 or no tests exist for changed code | Conditional |

Announce which agents will be dispatched.

### Step 2: Dispatch All Reviews in Parallel

Dispatch every agent from the matrix in a **single parallel batch**:

**Always:**
```
Agent(description="Run verification loop",
      subagent_type="general-purpose",
      prompt="Run the verification loop for this project.
        Invoke Skill `verification-loop`. Follow it exactly — run all 6 phases
        (build, types, lint, tests, security, diff). Return the full VERIFICATION REPORT
        with PASS/FAIL for each phase.
        CRITICAL FOR REFACTORING: Compare test results against this baseline
        from Phase 1: [paste test baseline from TodoWrite]. All previously passing
        tests must still pass. Coverage must not decrease.")

Agent(description="Run security review",
      subagent_type="everything-claude-code:security-reviewer",
      prompt="Security review on this branch's changes.
        Use `git diff $(git merge-base HEAD <BASE_BRANCH>)..HEAD` to scope changes.
        Focus on: hardcoded secrets, input validation, injection, auth/authz, OWASP Top 10.
        Return structured findings with severity levels.")

Agent(description="Run code review",
      subagent_type="superpowers:code-reviewer",
      prompt="Review the refactoring on this branch. Confirm:
        1. Behavior is preserved (no functional changes)
        2. Code quality has improved (refactoring achieved its goal)
        3. No regressions introduced
        Use `git diff $(git merge-base HEAD <BASE_BRANCH>)..HEAD` for all changes.
        Read the plan from docs/superpowers/ directory for context.
        Return findings as Critical / Important / Minor.")

Agent(description="Run simplify review",
      subagent_type="general-purpose",
      prompt="Review-only simplify analysis on this branch's changes.
        Use `git diff $(git merge-base HEAD <BASE_BRANCH>)..HEAD` to scope changes.
        Analyze three dimensions:
        1. CODE REUSE: Search for existing utilities/helpers in the codebase that could
           replace newly written code. Flag duplicated functionality and inline logic
           that has existing helpers.
        2. CODE QUALITY: Check for redundant state, parameter sprawl, copy-paste with
           slight variation, leaky abstractions, stringly-typed code, unnecessary nesting.
        3. EFFICIENCY: Check for unnecessary work (redundant computations, duplicate API
           calls, N+1 patterns), missed concurrency, hot-path bloat, recurring no-op
           updates, unbounded data structures, overly broad operations.
        IMPORTANT: Report findings ONLY — do NOT modify any code.
        Return findings as Critical / Important / Minor for each dimension.")
```

**Conditional (include only if condition met):**
```
Agent(description="Run architecture review",
      subagent_type="everything-claude-code:architect",
      prompt="Architecture review of this refactoring.
        Use `git diff $(git merge-base HEAD <BASE_BRANCH>)..HEAD` for all changes.
        Evaluate: module boundaries, coupling direction, dependency hygiene,
        interface design, separation of concerns.
        Confirm the refactoring improved structural quality.
        Return findings as Critical / Important / Minor.")

Agent(description="Run Go review",
      subagent_type="everything-claude-code:go-reviewer",
      prompt="Go-specific review of this branch's changes.
        Run go vet, staticcheck. Check for: idiomatic Go, concurrency safety,
        error wrapping, race conditions, goroutine leaks.
        Return findings as Critical / Important / Minor.")

Agent(description="Run Python review",
      subagent_type="everything-claude-code:python-reviewer",
      prompt="Python-specific review of this branch's changes.
        Run ruff, mypy, bandit. Check for: PEP 8, type hints, Pythonic idioms,
        security, mutable defaults, bare excepts.
        Return findings as Critical / Important / Minor.")

Agent(description="Run TypeScript review",
      subagent_type="everything-claude-code:code-reviewer",
      prompt="TypeScript-specific review of this branch's changes.
        Run tsc --noEmit, eslint. Check for: strict types, proper error handling,
        React patterns (if applicable), async/await correctness, import hygiene.
        Return findings as Critical / Important / Minor.")

Agent(description="Run Rust review",
      subagent_type="everything-claude-code:rust-reviewer",
      prompt="Rust-specific review of this branch's changes.
        Run cargo clippy. Check for: ownership/lifetime correctness, unsafe usage,
        error handling (Result/Option), idiomatic patterns, performance.
        Return findings as Critical / Important / Minor.")

Agent(description="Run C++ review",
      subagent_type="everything-claude-code:cpp-reviewer",
      prompt="C++ review of this branch's changes.
        Check for: memory safety, modern C++ idioms (RAII, smart pointers),
        concurrency correctness, const correctness, include hygiene.
        Return findings as Critical / Important / Minor.")

Agent(description="Run Kotlin review",
      subagent_type="everything-claude-code:kotlin-reviewer",
      prompt="Kotlin-specific review of this branch's changes.
        Check for: null safety, coroutine safety, idiomatic patterns,
        Compose best practices (if applicable), clean architecture.
        Return findings as Critical / Important / Minor.")

Agent(description="Run test coverage analysis",
      subagent_type="pr-review-toolkit:pr-test-analyzer",
      prompt="Analyze test coverage quality for this branch's changes.
        Use `git diff $(git merge-base HEAD <BASE_BRANCH>)..HEAD` for all changes.
        Focus on: behavioral coverage (not line coverage), critical gaps,
        test-vs-implementation coupling. Rate criticality 1-10.
        Return findings with gap descriptions.")
```

### Step 3: Collect and Act on Findings

When all agents return, consolidate results into a summary table:

```
| Agent              | Status | Critical | Important | Minor |
|--------------------|--------|----------|-----------|-------|
| Verification       | PASS   | 0        | -         | -     |
| Security           | PASS   | 0        | 1         | 2     |
| Code Review        | PASS   | 0        | 2         | 3     |
| ...                |        |          |           |       |
```

**Fix priority:** Critical (all agents) > Important (all agents) > Minor (skip unless trivial).

If fixes were needed, re-run only the affected agent(s) to confirm.

### Step 4: Update Project Docs

Check if the following files need updates based on the changes made:
- **CLAUDE.md**: Module boundaries, file organization, or architectural patterns
- **README.md**: New features, usage examples, configuration options, API endpoints
- **Makefile**: New commands, updated targets, new dependencies
- **Install scripts**: New dependencies, setup steps, environment variables
- **Other project docs**: CHANGELOG, API docs, deployment guides, docker-compose, etc.

For each file: read current content, compare against actual changes, update only what is factually outdated or missing. Do not rewrite unchanged sections.

### Gate

Use AskUserQuestion to confirm:
- Question: "All reviews complete. Ship this refactor?"
- Options: "Continue to ship", "Fix issues first", "Stop workflow"

If "Fix issues first": address remaining issues, then re-run the failing verification steps.
If "Stop workflow": end here.

### CHECKPOINT — Do NOT announce phase complete until ALL items are confirmed:
- [ ] Step 1: Scope analysis done, review matrix determined
- [ ] Step 2: All agents dispatched and returned
- [ ] Step 3: All Critical/Important findings resolved
- [ ] Step 4: Project docs checked and updated if needed
- [ ] Gate: User confirmed to ship

If any item is unchecked, go back and complete it now.

Announce: **"Phase 6 complete — verified and reviewed. Moving to Phase 7."**

---

## Phase 7: Ship

Invoke Skill `superpowers:finishing-a-development-branch`.

Follow the skill exactly. It will:
1. Verify tests pass
2. Present 4 options: merge locally / push + PR / keep as-is / discard
3. Execute the chosen option
4. Clean up worktree if applicable

**Default recommendation:** When presenting the 4 options, recommend "Push and create a Pull Request" as the default choice — this is the safest integration path since it allows code review before merging.

Announce: **"Refactor workflow complete."**
