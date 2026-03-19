# Phase 5: Cleanup

Use the Task tool to dispatch the `refactor-cleaner` agent:

```
Task(subagent_type="refactor-cleaner", prompt="Analyze the codebase for dead code, unused exports, and unused dependencies created by the recent refactoring. Follow your safety checklist: grep for references, check dynamic imports, review git history, and test after each removal batch.")
```

Review the agent's findings. If it identifies safe removals, let it proceed. For risky removals, verify manually before approving.

Announce: **"Phase 5 complete — cleanup done. Returning to state machine."**

Return to the state machine SKILL.md.
