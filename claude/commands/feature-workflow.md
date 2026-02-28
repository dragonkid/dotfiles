---
description: "End-to-end feature development: brainstorm → plan → implement → review → ship"
argument-hint: "Feature description (e.g., 'Add OAuth2 login with JWT refresh tokens')"
---

# Feature Workflow

You are orchestrating a complete feature development pipeline. Execute the phases below in order. Each phase uses a specific skill — invoke it via the Skill tool and follow it exactly.

**Feature request:** $ARGUMENTS

## Document Output

All design documents and implementation plans are saved in the project repo:

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

## Phase 1: Brainstorm (skippable)

Use AskUserQuestion to ask:
- Question: "How would you like to start?"
- Options: "Brainstorm from scratch", "I have a design — skip to planning"

### If brainstorming:

Invoke Skill `superpowers:brainstorming` with the feature request above as context.

**Context hint:** Project architecture and conventions are already loaded from the project's CLAUDE.md. Use that as your starting point — only explore areas where CLAUDE.md lacks sufficient detail for the feature.

Follow the skill exactly. It will:
- Explore the codebase and ask questions one at a time
- Propose 2-3 approaches with trade-offs
- Present the design in sections for incremental validation
- Write the validated design to `.plan/YYYY-MM-DD-<topic>-design.md`

When brainstorming completes and the design document is saved, announce:
**"Phase 1 complete — design document saved. Moving to Phase 2."**

### If skipping:

Ask the user for the design document path or description, then proceed directly to Phase 2.

---

## Phase 2: Worktree Setup

Use AskUserQuestion to ask:
- Question: "Create a git worktree for isolated development?"
- Options: "Skip — work on current branch" (first/default), "Create worktree"

- **If skip:** Continue on the current branch.
- **If create worktree:** Invoke Skill `superpowers:using-git-worktrees`. Follow the skill exactly.

Announce: **"Phase 2 complete. Moving to Phase 3."**

---

## Phase 3: Plan

Invoke Skill `superpowers:writing-plans`.

Follow the skill exactly. It will:
- Create a detailed implementation plan based on the Phase 1 design
- Structure tasks with TDD steps (write test → verify fail → implement → verify pass → commit)
- Save the plan to `.plan/YYYY-MM-DD-<feature-name>.md`
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
1. Design document and plan file are saved to `.plan/`
3. TodoWrite records: worktree choice, execution mode choice, current phase

Then suggest: **"The brainstorm and planning phases used significant context. Consider running `/compact` now — all decisions are persisted in .plan/ and TodoWrite. After compact, I'll recover context by reading those files."**

Announce: **"Phase 3 complete — plan saved. Moving to Phase 4."**

---

## Phase 4: Implement

Based on the execution mode chosen in Phase 3:

- **If Subagent-Driven:** Invoke Skill `superpowers:subagent-driven-development`. Follow the skill exactly.
- **If Parallel Session:** Invoke Skill `superpowers:executing-plans`. Follow the skill exactly.

**Important:** Both skills will attempt to invoke `superpowers:finishing-a-development-branch` at the end. Do NOT follow that final step — instead proceed to Phase 5.

### Context Protection & Compact

Before suggesting compact, ensure:
1. TodoWrite has all task statuses updated
2. Note the base branch name for later use

Then suggest: **"Implementation complete. Consider running `/compact` before verification — progress is tracked in TodoWrite and git history. After compact, I'll recover context from TodoWrite + git log + .plan/."**

Announce: **"Phase 4 complete — implementation done. Moving to Phase 5."**

---

## Phase 5: Verify & Review

### Step 1: Verification Loop

Invoke Skill `verification-loop`.

Follow the skill exactly — run all 6 verification phases (build, types, lint, tests, security, diff) and produce the VERIFICATION REPORT.

If any phase fails, fix issues before proceeding.

### Step 2: Security Review

Invoke Skill `everything-claude-code:security-review`.

Follow the skill exactly — run through the security checklist relevant to the changes made.

Fix any critical security issues found.

### Step 3: Code Review

Invoke Skill `superpowers:requesting-code-review`.

Follow the skill exactly — dispatch the code-reviewer subagent to review the entire implementation against the plan.

Fix any Critical or Important issues found.

### Step 4: Update Project Docs

Check if the following files need updates based on the changes made:
- **CLAUDE.md**: New modules, patterns, commands, or architectural changes
- **README.md**: New features, usage examples, configuration options, API endpoints
- **Makefile**: New commands, updated targets, new dependencies
- **Install scripts**: New dependencies, setup steps, environment variables
- **Other project docs**: CHANGELOG, API docs, deployment guides, docker-compose, etc.

For each file: read current content, compare against actual changes, update only what is factually outdated or missing. Do not rewrite unchanged sections.

### Gate

Use AskUserQuestion to confirm:
- Question: "Verification, security review, code review, and doc updates complete. Ship this feature?"
- Options: "Continue to ship", "Fix issues first", "Stop workflow"

If "Fix issues first": address remaining issues, then re-run the failing verification steps.
If "Stop workflow": end here.

### CHECKPOINT — Do NOT announce phase complete until ALL items are confirmed:
- [ ] Step 1: Verification Loop — ran and produced report
- [ ] Step 2: Security Review — ran or confirmed N/A for this change
- [ ] Step 3: Code Review — ran or confirmed N/A for this change
- [ ] Step 4: Update Project Docs — checked CLAUDE.md, README, Makefile, .env.example, etc.
- [ ] Gate: User confirmed to ship

If any item is unchecked, go back and complete it now.

Announce: **"Phase 5 complete — verified and reviewed. Moving to Phase 6."**

---

## Phase 6: Ship

Invoke Skill `superpowers:finishing-a-development-branch`.

Follow the skill exactly. It will:
1. Verify tests pass
2. Present 4 options: merge locally / push + PR / keep as-is / discard
3. Execute the chosen option
4. Clean up worktree if applicable

Announce: **"Feature workflow complete."**
