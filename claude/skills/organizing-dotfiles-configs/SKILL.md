---
name: organizing-dotfiles-configs
description: Use when adding tool configurations to dotfiles repo, deciding directory structure, or reorganizing existing configs. Symptoms: "organize like existing pattern", uncertainty about flat vs nested structure, unsure which files to version-control, symlink paths breaking after reorganization.
---

Decision framework for structuring tool configs in dotfiles with symlinks.

## When to Use

- Adding new tool to dotfiles
- Deciding structure (flat vs nested)
- Choosing what to version-control
- Symlink issues

## Decision Framework

| Config Type | Structure | Example |
|------------|-----------|---------|
| Simple executables | Flat | hooks/*.sh |
| Complex with metadata | Nested | skills/*/SKILL.md |

Include: configs, scripts, preferences
Exclude: cache, logs, credentials

## Quick Reference

Hooks reorganization example:
- Before: `~/.claude/hooks/` (local only)
- After: `~/.dotfiles/claude/hooks/` + symlink
- Install: `link_config "${BASEDIR}/claude/hooks" ~/.claude/hooks`
- Verify: `ls -la ~/.claude/hooks`

## Common Mistakes

- Over-nesting simple scripts
- Forgetting install.sh update
- Path confusion (symlink resolves from target)
