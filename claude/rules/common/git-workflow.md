# Git Workflow

## Commit Message Format

```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

Commit only when explicitly requested. Omit Co-Authored-By lines.

Note: Attribution disabled globally via ~/.claude/settings.json.

## Commit Command Format (CRITICAL)

NEVER use `$(cat <<'EOF'...)` HEREDOC in git commit commands — it triggers Claude Code's `$()` security confirmation.

Instead, use `-F` with a temp file:
```bash
printf '%s' 'commit message here' > /tmp/commitmsg && git commit -F /tmp/commitmsg && rm -f /tmp/commitmsg
```

For multi-line messages:
```bash
printf '%s\n\n%s' 'feat: summary line' 'Body details here' > /tmp/commitmsg && git commit -F /tmp/commitmsg && rm -f /tmp/commitmsg
```

Also avoid quoting flag-like strings — Claude Code flags `"--anything"` or `"---"` in quotes as suspicious.

```bash
# WRONG - triggers "quoted characters in flag names" confirmation
echo "---"
echo "---separator---"

# RIGHT - no quotes needed for literal separators
echo ---
echo ===
printf '\n'
```

## Pull Request Workflow

When creating PRs:
1. Analyze full commit history (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft comprehensive PR summary
4. Include test plan with TODOs
5. Push with `-u` flag if new branch

