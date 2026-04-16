---
name: bugfix-workflow
description: "End-to-end bugfix pipeline: diagnose -> plan (optional) -> fix -> review -> ship. Use when the user invokes /bugfix-workflow or asks to run the full bugfix development pipeline."
argument-hint: "Bug description (e.g., 'Empty email accepted in registration form' or 'API returns 500 on concurrent requests')"
---

# Bugfix Workflow — State Machine

You are orchestrating a complete bugfix pipeline. This file is the **control flow** — each phase's detailed instructions live in `references/`. You MUST execute phases in order and MUST NOT silently skip any phase.

**Bug report:** $ARGUMENTS

## Execution Rules

1. Execute phases in strict order: 1 -> 2 -> 3 -> 4 -> 5 -> 6
2. At every **GATE**, analyze whether the phase is necessary. If you believe a phase can be skipped, present your reasoning and recommendation via AskUserQuestion — let the user decide. NEVER skip silently.
3. Read the phase reference file, execute it fully, then return here for the gate.
4. Track state in TodoWrite after every gate: current phase, user choices, fix path, branch mode, base branch.

---

## Phase 1: Diagnose

Read `references/phase-1-diagnose.md` and follow it completely.

**GATE 1** — When Phase 1 completes, use AskUserQuestion:
- Question: "Root cause identified. How should we proceed?"
- Options: "Simple fix — proceed to TDD (Recommended)", "Complex fix — write a plan first", "Brainstorm fix approaches", "Stop workflow"

| Choice | Action |
|--------|--------|
| Simple fix | Record `fix_path=simple` in TodoWrite. Skip Phase 3. Proceed to Phase 2. |
| Complex fix | Record `fix_path=complex` in TodoWrite. Proceed to Phase 2, then Phase 3. |
| Brainstorm | Invoke Skill `superpowers:brainstorming` with root cause context. When done, return to this gate (exclude brainstorm option). |
| Stop workflow | End. |

Update TodoWrite: `phase=1-complete, fix_path=<simple|complex>`.

---

## Phase 2: Branch Setup

**Smart skip analysis:** Check if the user is already on a fix branch or worktree. If so, recommend skipping.
- Already on `fix/` or `feat/` branch, or in a worktree? -> Recommend: "You're already on branch `X`. Skip branch setup?"
- On main/master/develop? -> Proceed to Phase 2 normally.

If proceeding: Read `references/phase-2-branch.md` and follow it completely.

Update TodoWrite: `phase=2-complete, branch_mode=<worktree|branch|skipped>, base_branch=<name>`.

---

## Phase 3: Plan (conditional)

**If `fix_path=simple`:** Skip this phase entirely. Announce: **"Phase 3 skipped — simple fix. Moving to Phase 4."**

**If `fix_path=complex`:** Read `references/phase-3-plan.md` and follow it completely.

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

## Phase 4: Implement

Read `references/phase-4-implement.md` and follow it completely.

**GATE 4** — Use AskUserQuestion:
- Question: "Implementation complete. Ready for verification & review?"
- Options: "Proceed to review (Recommended)", "Continue implementing", "Stop workflow"

| Choice | Action |
|--------|--------|
| Proceed to review | Proceed to Phase 5. |
| Continue implementing | Stay in Phase 4, continue work, then return to this gate. |
| Stop workflow | End. |

Update TodoWrite: `phase=4-complete`.

---

## Phase 5: Verify & Review

**ENTRY GATE** — Before doing anything, use AskUserQuestion to let the user choose the review level. Provide change scope context (files changed, lines added) to help them decide:
- Question: "Phase 5: 变更范围是 X 个文件 / Y 行。选择 review 方式？"
- Options: "Full review (Recommended) — 7+ agent 并行审查", "Lightweight — 仅 verification loop (build/lint/test)", "Skip review"

| Choice | Action |
|--------|--------|
| Full review | Read `references/phase-5-review.md` and follow it **completely** — do NOT improvise a partial review. The reference file defines the exact agent matrix and all 4 steps (scope analysis → dispatch → fix → docs). |
| Lightweight | Run only the verification loop (build, types, lint, tests) and skip the multi-agent dispatch. |
| Skip review | Proceed directly to Gate 5. |

**GATE 5 CHECKPOINT** — Before presenting the Gate 5 question, verify:
- [ ] If Full review was chosen: all agents from the review matrix returned results
- [ ] If Full review was chosen: all Critical findings are resolved
- [ ] Verification loop (build + lint + tests) passed

If any item is unchecked, go back and complete it before proceeding.

**GATE 5** — Use AskUserQuestion:
- Question: "All reviews complete. Ship this fix?"
- Options: "Continue to ship (Recommended)", "Fix issues first", "Stop workflow"

| Choice | Action |
|--------|--------|
| Continue to ship | Proceed to Phase 6. |
| Fix issues first | Address issues, re-run affected agents, then return to **GATE 5 CHECKPOINT** (not Gate 5 directly — the checkpoint re-verifies all steps including docs updates). |
| Stop workflow | End. |

Update TodoWrite: `phase=5-complete`.

---

## Phase 6: Ship

Read `references/phase-6-ship.md` and follow it completely.

Announce: **"Bugfix workflow complete."**
