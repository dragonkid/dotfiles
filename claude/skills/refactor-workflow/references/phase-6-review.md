# Phase 6: Verify & Review

Read TodoWrite to recover: base branch name from Phase 2, test baseline from Phase 1.

## Step 1: Scope Analysis — Determine Review Matrix

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
HAS_JAVA=$(test -f pom.xml -o -f build.gradle -o -f build.gradle.kts && echo yes || echo no)
HAS_KOTLIN=$(find . -maxdepth 3 -name "*.kt" -quit 2>/dev/null && echo yes || echo no)
TESTS_CHANGED=$(git diff --name-only $BASE..HEAD | grep -c '_test\.\|\.test\.\|test_\|_spec\.' || true)
HAS_CODEX=$(command -v codex >/dev/null 2>&1 && echo yes || echo no)
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
| Java review | HAS_JAVA = yes | Conditional |
| Go review | HAS_GO = yes | Conditional |
| Python review | HAS_PYTHON = yes | Conditional |
| TypeScript review | HAS_TS = yes | Conditional |
| Rust review | HAS_RUST = yes | Conditional |
| C++ review | HAS_CPP = yes | Conditional |
| Kotlin review | HAS_KOTLIN = yes | Conditional |
| Test coverage analysis | TESTS_CHANGED > 0 or no tests exist for changed code | Conditional |
| Codex cross-model review | HAS_CODEX = yes | Conditional |

Announce which agents will be dispatched.

## Step 2: Dispatch All Reviews in Parallel

Dispatch every agent from the matrix in a **single parallel batch**:

**Always:**
```
Agent(description="Run verification loop",
      subagent_type="general-purpose",
      prompt="Run the verification loop for this project.
        Invoke Skill `everything-claude-code:verification-loop`. Follow it exactly — run all 6 phases
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

        FRAMEWORK HOOK EXECUTION PATH CHECK:
        If the refactoring touches any framework hook, callback, validator, middleware,
        signal, or lifecycle method, verify:
        1. TRIGGER CONDITIONS — Under what conditions does the framework actually
           invoke this code? Check the framework docs, not just whether the logic
           looks correct. Common gotchas: Pydantic validators skipping defaults,
           Django clean methods skipping blank fields, ORM events not firing on
           bulk operations, middleware short-circuiting.
        2. ALL INPUT PATHS — Enumerate every way data can arrive at this hook
           (explicit value, null, absent/omitted, empty). Confirm the hook fires
           for each path. 'Sent as null' and 'field omitted' are often distinct
           framework code paths.
        3. TEST COVERAGE — Verify tests exist for each distinct input path, not
           just the original behavior.
        Flag any hook that lacks full path coverage as Critical.

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

Agent(description="Run Java review",
      subagent_type="everything-claude-code:java-reviewer",
      prompt="Java/Spring Boot review of this branch's changes.
        Check for: layered architecture violations, JPA/Hibernate anti-patterns,
        Spring Security misconfigurations, concurrency issues, Optional misuse,
        resource leaks, and Java coding standards.
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
      subagent_type="everything-claude-code:typescript-reviewer",
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

Agent(description="Run Codex cross-model review",
      subagent_type="general-purpose",
      prompt="Run a Codex native code review on this branch's changes.
        1. Run: codex review --base <BASE_BRANCH>
           Replace <BASE_BRANCH> with the actual base branch.
        2. Parse the markdown output. Map findings to the workflow convention:
           - Findings about security, data loss, race conditions → Critical
           - Findings about design issues, missing edge cases → Important
           - Findings about style, naming, minor improvements → Minor
        3. Return formatted as:
           CODEX CROSS-MODEL REVIEW (GPT-5.4)
           Verdict: [approve/needs-attention]
           Critical: [count]
           - [finding summary] (file:line)
           Important: [count]
           - [finding summary] (file:line)
           Minor: [count]
           - [finding summary] (file:line)")
```

## Step 3: Collect and Act on Findings

When all agents return, consolidate results into a summary table:

```
| Agent              | Status | Critical | Important | Minor |
|--------------------|--------|----------|-----------|-------|
| Verification       | PASS   | 0        | -         | -     |
| Security           | PASS   | 0        | 1         | 2     |
| Code Review        | PASS   | 0        | 2         | 3     |
| Codex Cross-Model  | PASS   | 0        | 1         | 2     |
| ...                |        |          |           |       |
```

**Fix priority:** Critical (all agents) > Important (all agents) > Minor (skip unless trivial).

If fixes were needed, re-run only the affected agent(s) to confirm.

## Step 4: Update Project Docs

Check if the following files need updates based on the changes made:
- **CLAUDE.md**: Module boundaries, file organization, or architectural patterns
- **README.md**: New features, usage examples, configuration options, API endpoints
- **Makefile**: New commands, updated targets, new dependencies
- **Install scripts**: New dependencies, setup steps, environment variables
- **Other project docs**: CHANGELOG, API docs, deployment guides, docker-compose, etc.

For each file: read current content, compare against actual changes, update only what is factually outdated or missing. Do not rewrite unchanged sections.

## CHECKPOINT — Do NOT announce phase complete until ALL items are confirmed:
- [ ] Step 1: Scope analysis done, review matrix determined
- [ ] Step 2: All agents dispatched and returned
- [ ] Step 3: All Critical/Important findings resolved
- [ ] Step 4: Project docs checked and updated if needed
- [ ] Gate: User confirmed to ship (handled in state machine)

If any item is unchecked, go back and complete it now.

Announce: **"Phase 6 complete — verified and reviewed. Returning to state machine for Gate 6."**

Return to the state machine SKILL.md for Gate 6.
