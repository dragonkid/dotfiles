---
name: refactor-workflow
description: "End-to-end refactoring: justify -> scope -> branch -> plan (optional) -> execute -> cleanup -> review -> ship. Use when the user invokes /refactor-workflow or asks to run the full refactoring pipeline."
argument-hint: "Refactoring goal (e.g., 'Extract auth logic into separate module' or 'Reduce coupling between order and payment services')"
---

# Refactor Workflow — State Machine

You are orchestrating a complete refactoring pipeline. The core constraint: **behavior must not change — only structure improves.** This file is the **control flow** — each phase's detailed instructions live in `references/`. You MUST execute phases in order and MUST NOT silently skip any phase.

**Refactoring goal:** $ARGUMENTS

## Execution Rules

1. Execute phases in strict order: 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7
2. At every **GATE**, analyze whether the phase is necessary. If you believe a phase can be skipped, present your reasoning and recommendation via AskUserQuestion — let the user decide. NEVER skip silently.
3. Read the phase reference file, execute it fully, then return here for the gate.
4. Track state in TodoWrite after every gate: current phase, user choices, branch mode, base branch, test baseline.

---

## Phase 0: Refactoring Justification

Read `references/phase-0-justify.md` and follow it completely.

**GATE 0** — Phase 0 produces a GO / NO-GO / DEFER verdict:

| Verdict | Action |
|---------|--------|
| GO | Proceed to Phase 1. |
| NO-GO | End workflow. |
| DEFER | End workflow (decision recorded with trigger conditions). |

Update TodoWrite: `phase=0-complete, verdict=<GO/NO-GO/DEFER>`.

---

## Phase 1: Scope & Baseline

Read `references/phase-1-scope.md` and follow it completely.

**GATE 1** — When Phase 1 completes, use AskUserQuestion:
- Question: "Scope analysis complete. How should we proceed?"
- Options: "Simple refactor — proceed directly (Recommended)", "Complex refactor — write a plan first", "Brainstorm refactoring approaches", "Stop workflow"

| Choice | Action |
|--------|--------|
| Simple refactor | Record `refactor_mode=simple`. Skip Phase 3. Proceed to Phase 2, then Phase 4. |
| Complex refactor | Record `refactor_mode=complex`. Proceed to Phase 2, then Phase 3, then Phase 4. |
| Brainstorm | Invoke Skill `superpowers:brainstorming` with scope context. Return to this gate (excluding brainstorm option). |
| Stop workflow | End. |

Update TodoWrite: `phase=1-complete, refactor_mode=<simple/complex>, test_baseline=<pass count, coverage %>`.

---

## Phase 2: Branch Setup

**Smart skip analysis:** Check if the user is already on a refactor branch or worktree. If so, recommend skipping.
- Already on `refactor/` branch, or in a worktree? -> Recommend: "You're already on branch `X`. Skip branch setup?"
- On main/master/develop? -> Proceed to Phase 2 normally.

If proceeding: Read `references/phase-2-branch.md` and follow it completely.

Update TodoWrite: `phase=2-complete, branch_mode=<worktree|branch|skipped>, base_branch=<name>`.

---

## Phase 3: Plan (conditional)

**If `refactor_mode=simple`:** Skip this phase entirely. Announce: **"Phase 3 skipped — simple refactor. Moving to Phase 4."**

**If `refactor_mode=complex`:** Read `references/phase-3-plan.md` and follow it completely.

**GATE 3** — Use AskUserQuestion:
- Question: "Plan is ready. Proceed to implementation?"
- Options: "Start implementation (Recommended)", "Revise plan", "Stop workflow"

| Choice | Action |
|--------|--------|
| Start implementation | Record execution mode in TodoWrite. Proceed to Phase 4. |
| Revise plan | Re-invoke writing-plans skill, then return to this gate. |
| Stop workflow | End. |

Update TodoWrite: `phase=3-complete, execution_mode=<choice from plan phase>`.

---

## Phase 4: Execute

Read `references/phase-4-execute.md` and follow it completely.

**GATE 4** — Use AskUserQuestion:
- Question: "Refactoring complete. Ready for cleanup?"
- Options: "Proceed to cleanup (Recommended)", "Continue refactoring", "Stop workflow"

| Choice | Action |
|--------|--------|
| Proceed to cleanup | Proceed to Phase 5. |
| Continue refactoring | Stay in Phase 4, continue work, then return to this gate. |
| Stop workflow | End. |

Update TodoWrite: `phase=4-complete`.

---

## Phase 5: Cleanup

**Smart skip analysis:** Assess whether cleanup is needed.
- Trivial refactor (1-2 files, no removed exports/dependencies)? -> Recommend: "This was a small refactor. Skip dead code cleanup?"
- Non-trivial change? -> Proceed with cleanup.

If proceeding: Read `references/phase-5-cleanup.md` and follow it completely.

Update TodoWrite: `phase=5-complete`.

---

## Phase 6: Verify & Review

**Smart skip analysis:** Assess the change scope before committing to full review.
- Trivial change (1-2 files, <50 lines, rename-only)? -> Recommend: "This is a small change. Run verification only and skip multi-agent review?"
- Non-trivial change? -> Proceed with full review matrix.

If full review: Read `references/phase-6-review.md` and follow it completely.
If lightweight: Run only the verification loop (build, types, lint, tests) and skip the multi-agent dispatch.

**GATE 6** — Use AskUserQuestion:
- Question: "All reviews complete. Ship this refactor?"
- Options: "Continue to ship (Recommended)", "Fix issues first", "Stop workflow"

| Choice | Action |
|--------|--------|
| Continue to ship | Proceed to Phase 7. |
| Fix issues first | Address issues, re-run affected agents, then return to this gate. |
| Stop workflow | End. |

Update TodoWrite: `phase=6-complete`.

---

## Phase 7: Ship

Read `references/phase-7-ship.md` and follow it completely.

Announce: **"Refactor workflow complete."**
