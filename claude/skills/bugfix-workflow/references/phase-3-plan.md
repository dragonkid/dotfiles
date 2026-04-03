# Phase 3: Plan

## Document Output

Plans are saved in the project repo:

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

## Step 0: Reuse Discovery

Before writing the plan, invoke Skill `everything-claude-code:search-first` with the root cause description as context. Feed findings into the plan — reference existing code rather than proposing new implementations of already-available functionality.

## Step 1: Write the Plan

Invoke Skill `superpowers:writing-plans`.

Follow the skill exactly. It will:
- Create a detailed implementation plan based on the Phase 1 diagnosis
- Structure tasks with TDD steps (write test -> verify fail -> implement -> verify pass -> commit)
- Save the plan to `docs/superpowers/plans/YYYY-MM-DD-<bug-summary>.md`
- Present the execution mode choice at the end:
  1. **Subagent-Driven** (recommended) — fresh subagent per task with two-stage review
  2. **Inline Execution** — execute tasks in this session with checkpoints

Record the user's execution mode choice for Phase 4.

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
- Whether the fix actually targets the root cause (not just symptoms)
- Regression risk to existing functionality

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
1. Plan file is saved to `docs/superpowers/`
2. TodoWrite records: root cause, BRANCH_MODE (branch/worktree), base branch name, execution mode choice, current phase

Then suggest: **"The diagnosis and planning phases used significant context. Consider running `/compact` now — all decisions are persisted in TodoWrite and docs/superpowers/. After compact, I'll recover context by reading those files."**

Announce: **"Phase 3 complete — plan saved. Returning to state machine for Gate 3."**

Return to the state machine SKILL.md for Gate 3.
