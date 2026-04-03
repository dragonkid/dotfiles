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

## Codex Plan Challenge

After the plan is finalized, use Codex (GPT-5.4) for a cross-model adversarial assessment of the plan itself (not a code review).

### Guard

```bash
HAS_CODEX=$(command -v codex >/dev/null 2>&1 && echo yes || echo no)
```

If `HAS_CODEX != yes`, skip this section entirely and proceed to Context Protection.

### Run Challenge

Use the plan file path from the writing-plans output (recorded in TodoWrite or the previous step). Read its content with the Read tool, then pipe it to Codex exec via stdin:

```bash
cat <PLAN_FILE_PATH> | codex exec "<adversarial prompt>"
```

The prompt should follow this structure:

```
You are performing an adversarial review of an implementation plan.
Your job is to break confidence in this plan, not to validate it.
Default to skepticism.

Attack surface — prioritize these failure modes:
- Flawed assumptions that stop being true under real conditions
- Missing edge cases, error paths, or rollback scenarios
- Better alternatives not considered
- Task sequencing issues (dependencies, parallelism opportunities)
- Risks the plan author may have rationalized away
- Whether the design covers all stated user requirements
- Feasibility of the proposed architecture under production load

Rules:
- Report only material findings backed by evidence from the plan
- Do not give credit for good intent or likely follow-up work
- Keep response under 500 words
- First line: SOLID / HAS_RISKS / RECONSIDER
- Then numbered findings, each with: what can go wrong + why + recommendation

PLAN DOCUMENT:
<plan content here>
```

### Present Findings

Present the Codex assessment results. **Do not auto-modify the plan** — these findings serve as additional input for the Gate decision.

- If verdict is **RECONSIDER**: prominently highlight before the Gate question
- If verdict is **HAS_RISKS**: list risk items so the user can decide at the Gate whether to adjust
- If verdict is **SOLID**: briefly note "Codex found no major risks"

---

## Context Protection & Compact

Before suggesting compact, ensure:
1. Design document and plan file are saved to `docs/superpowers/`
2. TodoWrite records: execution mode choice, current phase

Then suggest: **"The brainstorm and planning phases used significant context. Consider running `/compact` now — all decisions are persisted in docs/superpowers/ and TodoWrite. After compact, I'll recover context by reading those files."**

Announce: **"Phase 2 complete — design and plan saved. Returning to state machine for Gate 2."**

Return to the state machine SKILL.md for Gate 2.
