# Design Patterns for Skills

## Progressive Disclosure

Skills use a three-level loading system:
1. **Metadata** (name + description) — Always in context
2. **SKILL.md body** — Loaded when the skill triggers
3. **references/ files** — Read by the model on demand

**Principle:** Keep only the core workflow in SKILL.md; move detailed content to references/.

## Pattern 1: High-Level Guide + References

```markdown
## Advanced Features

- **Form filling**: See [FORMS.md](FORMS.md)
- **API reference**: See [REFERENCE.md](REFERENCE.md)
```

## Pattern 2: Domain-Based Split

```
bigquery-skill/
├── SKILL.md
└── references/
    ├── finance.md
    ├── sales.md
    └── product.md
```

When the user asks about sales data, only sales.md is read.

## Pattern 3: Variant-Based Split

```
cloud-deploy/
├── SKILL.md
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

## Pattern 4: Conditional Loading

```markdown
## Editing Documents

Simple edits: modify the XML directly.

**Track changes**: See [REDLINING.md](REDLINING.md)
**OOXML details**: See [OOXML.md](OOXML.md)
```

## Flexibility Levels

| Scenario | Flexibility | Format |
|----------|------------|--------|
| Multiple valid approaches | High | Text description |
| Preferred pattern with variants | Medium | Pseudocode / parameterized script |
| Fragile operations, order matters | Low | Concrete script |

## references/ File Guidelines

- Files over 100 lines should include a table of contents at the top
- Only reference from SKILL.md directly — no nested references
- Use semantic file names, e.g., `discord-api.md`, `schema.md`
