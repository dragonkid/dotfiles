---
name: wrapping-external-skills
description: Use when an external plugin skill lacks YAML frontmatter and cannot be invoked via the Skill tool
---

# Wrapping External Skills

Create local wrapper skills for external plugin skills that lack YAML frontmatter.

## Problem

Plugin skills without `name`/`description` frontmatter are invisible to the Skill tool. They exist in the plugin cache but cannot be invoked via `Skill("namespace:skill-name")`.

## Solution

1. Create `~/.claude/skills/<skill-name>/SKILL.md`
2. Add frontmatter (`name` + `description`)
3. Copy original skill content below frontmatter
4. Add TODO to track upstream fix

### Frontmatter Template

```yaml
---
name: skill-name
description: Use when [triggering conditions from original skill]
---
```

## Maintenance

Local wrapper is a temporary shim. Track removal:

```markdown
- [ ] After [plugin] upgrades, check if `namespace:skill-name` has frontmatter — if so, delete local wrapper
```

## When to Use

- Plugin skill exists but has no frontmatter
- Need to invoke it via Skill tool in commands or workflows

## When NOT to Use

- Skill already has frontmatter — invoke directly
- One-time use — read and follow manually
