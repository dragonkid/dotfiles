# Phase 0: Refactoring Justification

Before committing resources, evaluate whether this refactoring is justified. This phase produces a GO / NO-GO / DEFER verdict with documented rationale.

## Document Output

Plans (if written) are saved in the project repo:

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

## Step 1: Triage — Fast Track vs Full Assessment

**Step 1a:** Determine assessment depth.

Use AskUserQuestion to ask:
- Question: "How should we evaluate this refactoring?"
- Options: "Fast track — trigger is clear, skip justification analysis", "Full assessment — evaluate severity, cost, and benefit", "Skip Phase 0 — justification is already clear, go to Phase 1"

**If "Skip Phase 0":** Announce GO verdict and return to the state machine immediately.

**Step 1b:** Identify the trigger.

**If "Fast track"**, use AskUserQuestion to ask:
- Question: "What is triggering this refactoring?"
- Options: "Rule of Three — third instance of duplication found", "Comprehension — cannot understand the code well enough to work on it", "Preparatory — must refactor before adding a feature or fixing a bug"

Record trigger category, automatic GO verdict, skip to Step 3.

**If "Full assessment"**, use AskUserQuestion to ask:
- Question: "What is triggering this refactoring?"
- Options: "Code review finding — reviewer identified structural issues", "Proactive improvement — code works but could be better", "Technical debt — accumulated shortcuts causing friction"

Record trigger category, proceed to Step 2.

---

## Step 2: Evidence Gathering + Cost-Benefit Analysis (Full Assessment Only)

### 2a: Parallel Evidence Collection

Dispatch two Task agents in parallel:

```
Task(subagent_type="code-reviewer", prompt="Analyze the code area related to this refactoring goal: [refactoring goal]. Focus on STRUCTURAL quality issues only (not functional bugs). Categorize findings by severity: 1) CHANGE PREVENTERS (Divergent Change, Shotgun Surgery) — highest, multiplies cost of all future changes; 2) COUPLERS (Feature Envy, Inappropriate Intimacy) — high, makes isolated changes impossible; 3) BLOATERS (Long Method, Large Class, Long Parameter List) — medium, reduces comprehension; 4) DISPENSABLES (Dead Code, Duplicate Code, Lazy Class) — lower, cleanup improves clarity. For each finding report: category, severity, file:line, brief description, and change frequency (git log --oneline --since='6 months ago' <file> | wc -l).")

Task(subagent_type="architect", prompt="Evaluate architectural implications of this refactoring: [refactoring goal]. Analyze: 1) Current coupling — how many modules depend on the target code? (grep imports/references); 2) Change frequency — how often has this code changed in 6 months? (git log --since='6 months ago'); 3) Blast radius — how many files would this refactoring touch?; 4) Test coverage — do tests exist for the affected code?; 5) Anti-patterns — check for God Object, Tight Coupling, Big Ball of Mud. Return a structured assessment.")
```

### 2b: 4W Framework Interactive Evaluation

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

### 2c: Verdict

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

---

## Step 3: Record Decision

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

**If GO:** Announce: **"Phase 0 complete — refactoring justified. Returning to state machine for Gate 0."**
**If NO-GO:** Announce: **"Phase 0 complete — refactoring not justified. Workflow ended."**
**If DEFER:** Announce: **"Phase 0 complete — refactoring deferred. Decision recorded with trigger conditions."**

Return to the state machine SKILL.md for Gate 0.
