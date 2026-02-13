---
name: verification-loop
description: Run structured 6-phase verification (build, types, lint, tests, security, diff) and produce a PASS/FAIL report. Use after completing features, before PRs, or after refactoring.
---

# Verification Loop Skill

A comprehensive verification system for Claude Code sessions. Auto-detect project language and run appropriate commands.

## When to Use

Invoke this skill:
- After completing a feature or significant code change
- Before creating a PR
- When you want to ensure quality gates pass
- After refactoring

## Language Detection

Detect project type from files in the root directory:

| File | Language |
|------|----------|
| `package.json` | JavaScript/TypeScript |
| `go.mod` | Go |
| `pyproject.toml` / `requirements.txt` | Python |
| `pom.xml` | Java (Maven) |
| `build.gradle` / `build.gradle.kts` | Java (Gradle) |
| `Cargo.toml` | Rust |

If multiple are present, run verification for each detected language.

## Verification Phases

### Phase 1: Build Verification

```bash
# JavaScript/TypeScript
npm run build 2>&1 | tail -20

# Go
go build ./... 2>&1 | tail -20

# Python
python -m py_compile <main_module> 2>&1  # or: python -m compileall src/

# Java (Maven)
mvn compile -q 2>&1 | tail -20

# Java (Gradle)
./gradlew compileJava -q 2>&1 | tail -20

# Rust
cargo build 2>&1 | tail -20
```

If build fails, STOP and fix before continuing.

### Phase 2: Type Check / Vet

```bash
# TypeScript
npx tsc --noEmit 2>&1 | head -30

# Go
go vet ./... 2>&1 | head -30

# Python
pyright . 2>&1 | head -30   # or: mypy . 2>&1 | head -30

# Java — type checking is part of compilation (Phase 1)
```

Report all errors. Fix critical ones before continuing.

### Phase 3: Lint Check

```bash
# JavaScript/TypeScript
npm run lint 2>&1 | head -30

# Go
golangci-lint run ./... 2>&1 | head -30  # or: staticcheck ./...

# Python
ruff check . 2>&1 | head -30  # or: flake8 . 2>&1 | head -30

# Java (Maven with Checkstyle/SpotBugs)
mvn checkstyle:check -q 2>&1 | head -30

# Java (Gradle with Checkstyle/SpotBugs)
./gradlew checkstyleMain -q 2>&1 | head -30
```

### Phase 4: Test Suite

```bash
# JavaScript/TypeScript
npm run test -- --coverage 2>&1 | tail -50

# Go
go test -cover ./... 2>&1 | tail -50

# Python
pytest --cov --cov-report=term-missing 2>&1 | tail -50

# Java (Maven)
mvn test -q 2>&1 | tail -50

# Java (Gradle)
./gradlew test 2>&1 | tail -50

# Rust
cargo test 2>&1 | tail -50
```

Report:
- Total tests: X
- Passed: X
- Failed: X
- Coverage: X% (target: 80% minimum)

### Phase 5: Security Scan

```bash
# JavaScript/TypeScript — check for secrets and debug artifacts
grep -rn "sk-\|api_key\|password\s*=" --include="*.ts" --include="*.js" . 2>/dev/null | head -10
grep -rn "console.log" --include="*.ts" --include="*.tsx" src/ 2>/dev/null | head -10

# Go — check for secrets and debug artifacts
grep -rn "sk-\|api_key\|password\s*=" --include="*.go" . 2>/dev/null | head -10
grep -rn "fmt.Print" --include="*.go" . 2>/dev/null | grep -v "_test.go" | head -10

# Python — check for secrets and debug artifacts
grep -rn "sk-\|api_key\|password\s*=" --include="*.py" . 2>/dev/null | head -10
grep -rn "print(" --include="*.py" src/ 2>/dev/null | grep -v "test_\|_test" | head -10

# Java — check for secrets and debug artifacts
grep -rn "sk-\|api_key\|password\s*=" --include="*.java" --include="*.properties" --include="*.yml" . 2>/dev/null | head -10
grep -rn "System.out.print" --include="*.java" src/ 2>/dev/null | grep -v "Test.java" | head -10
```

### Phase 6: Diff Review

```bash
# Show what changed
git diff --stat
git diff HEAD~1 --name-only
```

Review each changed file for:
- Unintended changes
- Missing error handling
- Potential edge cases

## Output Format

After running all phases, produce a verification report:

```
VERIFICATION REPORT
==================
Language:  [detected language(s)]

Build:     [PASS/FAIL]
Types:     [PASS/FAIL] (X errors)
Lint:      [PASS/FAIL] (X warnings)
Tests:     [PASS/FAIL] (X/Y passed, Z% coverage)
Security:  [PASS/FAIL] (X issues)
Diff:      [X files changed]

Overall:   [READY/NOT READY] for PR

Issues to Fix:
1. ...
2. ...
```

## Continuous Mode

For long sessions, run verification every 15 minutes or after major changes:

- After completing each function
- After finishing a component
- Before moving to next task

## Integration with Hooks

This skill complements PostToolUse hooks but provides deeper verification.
Hooks catch issues immediately; this skill provides comprehensive review.
