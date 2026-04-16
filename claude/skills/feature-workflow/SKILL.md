---
name: feature-workflow
description: "End-to-end feature development: brainstorm -> plan -> implement -> review -> ship. Use when the user invokes /feature-workflow or asks to run the full feature development pipeline."
argument-hint: "Feature description (e.g., 'Add OAuth2 login with JWT refresh tokens')"
---

# Feature Workflow — State Machine

You are orchestrating a complete feature development pipeline. This file is the **control flow** — each phase's detailed instructions live in `references/`. You MUST execute phases in order and MUST NOT silently skip any phase.

**Feature request:** $ARGUMENTS

## Execution Rules

1. Execute phases in strict order: 1 -> 2 -> 3 -> 4 -> 5
2. At every **GATE**, analyze whether the phase is necessary. If you believe a phase can be skipped, present your reasoning and recommendation via AskUserQuestion — let the user decide. NEVER skip silently.
3. Read the phase reference file, execute it fully, then return here for the gate.
4. Track state in TodoWrite after every gate: current phase, user choices, branch mode, base branch.

---

## Phase 1: Branch Setup

Branch setup comes first so that all artifacts (design docs, plans, code) live on the same branch. The branch name is derived from $ARGUMENTS.

**Smart skip analysis:** Check if the user is already on a feature branch or worktree. If so, recommend skipping.
- Already on `feat/` or `fix/` branch, or in a worktree? -> Recommend: "You're already on branch `X`. Skip branch setup?"
- On main/master/develop? -> Proceed to Phase 1 normally.

If proceeding: Read `references/phase-1-branch.md` and follow it completely.

Update TodoWrite: `phase=1-complete, branch_mode=<worktree|branch|skipped>, base_branch=<name>`.

---

## Phase 2: Design & Plan

Read `references/phase-2-design.md` and follow it completely.

**GATE 2** — When Phase 2 completes, use AskUserQuestion:
- Question: "Plan is ready. Proceed to implementation?"
- Options: "Start implementation (Recommended)", "Revise plan", "Stop workflow"

| Choice | Action |
|--------|--------|
| Start implementation | Record execution mode in TodoWrite. Proceed to Phase 3. |
| Revise plan | Re-invoke writing-plans skill, then return to this gate. |
| Stop workflow | End. |

Update TodoWrite: `phase=2-complete, execution_mode=<choice from design phase>`.

---

## Phase 3: Implement

Read `references/phase-3-implement.md` and follow it completely.

**GATE 3** — Use AskUserQuestion:
- Question: "Implementation complete. Ready for verification & review?"
- Options: "Proceed to review (Recommended)", "Continue implementing", "Stop workflow"

| Choice | Action |
|--------|--------|
| Proceed to review | Proceed to Phase 4. |
| Continue implementing | Stay in Phase 3, continue work, then return to this gate. |
| Stop workflow | End. |

Update TodoWrite: `phase=3-complete`.

---

## Phase 4: Verify & Review

**ENTRY GATE** — Before doing anything, use AskUserQuestion to let the user choose the review level. Provide change scope context (files changed, lines added) to help them decide:
- Question: "Phase 4: 变更范围是 X 个文件 / Y 行。选择 review 方式？"
- Options: "Full review (Recommended) — 7+ agent 并行审查", "Lightweight — 仅 verification loop (build/lint/test)", "Skip review"

| Choice | Action |
|--------|--------|
| Full review | Read `references/phase-4-review.md` and follow it **completely** — do NOT improvise a partial review. The reference file defines the exact agent matrix and all 4 steps (scope analysis → dispatch → fix → docs). |
| Lightweight | Run only the verification loop (build, types, lint, tests) and skip the multi-agent dispatch. |
| Skip review | Proceed directly to Gate 4. |

**Why full review matters:** A single reviewer catches surface issues, but cross-model multi-agent review catches deeper problems — the FOMC multi-day parsing bug (HIGH) was found by a Python reviewer, the cache deadlock was found by a code reviewer, and the fan-out concurrency risk was flagged independently by 3 different agents. Single-agent review would have missed most of these.

**GATE 4 CHECKPOINT** — Before presenting the Gate 4 question, verify:
- [ ] If Full review was chosen: all agents from the review matrix returned results
- [ ] If Full review was chosen: all Critical findings are resolved
- [ ] Verification loop (build + lint + tests) passed

If any item is unchecked, go back and complete it before proceeding.

**GATE 4** — Use AskUserQuestion:
- Question: "All reviews complete. Ship this feature?"
- Options: "Continue to ship (Recommended)", "Fix issues first", "Stop workflow"

| Choice | Action |
|--------|--------|
| Continue to ship | Proceed to Phase 5. |
| Fix issues first | Address issues, re-run affected agents, then return to **GATE 4 CHECKPOINT** (not Gate 4 directly — the checkpoint re-verifies all 4 steps including docs updates). |
| Stop workflow | End. |

Update TodoWrite: `phase=4-complete`.

---

## Phase 5: Ship

Read `references/phase-5-ship.md` and follow it completely.

Announce: **"Feature workflow complete."**
