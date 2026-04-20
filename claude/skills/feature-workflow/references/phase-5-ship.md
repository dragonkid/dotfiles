# Phase 5: Ship

Invoke Skill `superpowers:finishing-a-development-branch`.

Follow the skill exactly. It will:
1. Verify tests pass
2. Present 4 options: merge locally / push + PR / keep as-is / discard
3. Execute the chosen option
4. Clean up worktree if applicable

**Default recommendation:** When presenting the 4 options, recommend "Push and create a Pull Request" as the default choice — this is the safest integration path since it allows code review before merging.

## PR URL Output (mandatory)

When a PR is created, you MUST output the full clickable URL — not just `owner/repo#number` format (which doesn't render as a link in terminals). Extract the URL from the PR creation response and output it as plain text:

```
PR created: https://git.example.com/owner/repo/pull/123
```

The user needs to be able to click or copy-paste the URL directly into their browser. If the PR creation API response contains an `html_url` or `_links.html.href` field, use that. Otherwise construct it from the base URL + PR number.

Announce: **"Feature workflow complete."**
