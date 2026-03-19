# Phase 2: Design & Plan

## Document Output

All design documents and implementation plans are saved in the project repo:

```
DOCS_ROOT = docs/superpowers/
```

If `docs/superpowers/` does not exist, create it (`mkdir -p docs/superpowers/{specs,plans}`).

### Vault Sync

After creating or updating any document in `DOCS_ROOT`, use AskUserQuestion to ask:
- Question: "同步此文档到 Obsidian vault？"
- Options: "Yes — sync to vault", "No — skip"

If yes: copy the file to `~/Documents/second-brain/Jobs/{project_name}/` where `{project_name}` is derived from `basename $(git rev-parse --show-toplevel)`. Create the directory if it doesn't exist.

---

## Entry Gate

Use AskUserQuestion to ask:
- Question: "How would you like to start?"
- Options: "Brainstorm from scratch", "I have a design — skip to planning", "I have a plan — skip to implementation"

---

## Path A: Brainstorm from scratch

### Step 0: Reuse Discovery

Before brainstorming, invoke Skill `everything-claude-code:search-first` with the feature request as context. Feed findings into the brainstorming session so the design leverages existing code.

### Step 1: Brainstorm → Design → Plan

Invoke Skill `superpowers:brainstorming` with the feature request above as context.

**Context hint:** Project architecture and conventions are already loaded from the project's CLAUDE.md. Use that as your starting point — only explore areas where CLAUDE.md lacks sufficient detail for the feature.

**Override:** Tell the skill to save design documents under `docs/superpowers/specs/` (the skill's default) — this aligns with DOCS_ROOT.

Follow the skill exactly. It will:
- Explore the codebase and ask questions one at a time
- Propose 2-3 approaches with trade-offs
- Present the design in sections for incremental validation
- Write the validated design to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
- Run spec review loop (auto-dispatch spec-document-reviewer, max 3 rounds)
- Ask user to review the written spec
- **Automatically invoke `superpowers:writing-plans`** to create the implementation plan

Let the skill complete its full flow — brainstorming will hand off to writing-plans seamlessly. The plan will be saved to `docs/superpowers/plans/`.

When the plan is ready, `writing-plans` will present the execution mode choice:
1. **Subagent-Driven** (recommended) — fresh subagent per task with two-stage review
2. **Inline Execution** — execute tasks in this session with checkpoints

Record the user's execution mode choice for Phase 3.

---

## Path B: I have a design — skip to planning

Use AskUserQuestion to ask:
- Question: "Provide the design document path or paste the design description:"
- Options: "I'll paste it in the next message", "It's in docs/superpowers/specs/"

Then invoke Skill `everything-claude-code:search-first` for reuse discovery, followed by Skill `superpowers:writing-plans`. The plan skill will present the execution mode choice — record it for Phase 3.

---

## Path C: I have a plan — skip to implementation

Use AskUserQuestion to ask:
- Question: "Where is the plan document?"
- Options: "It's in docs/superpowers/plans/", "I'll provide the path"

Read the plan, then return to the state machine to proceed to Phase 3 (Implement).

---

## Context Protection & Compact

Before suggesting compact, ensure:
1. Design document and plan file are saved to `docs/superpowers/`
2. TodoWrite records: execution mode choice, current phase

Then suggest: **"The brainstorm and planning phases used significant context. Consider running `/compact` now — all decisions are persisted in docs/superpowers/ and TodoWrite. After compact, I'll recover context by reading those files."**

Announce: **"Phase 2 complete — design and plan saved. Returning to state machine for Gate 2."**

Return to the state machine SKILL.md for Gate 2.
