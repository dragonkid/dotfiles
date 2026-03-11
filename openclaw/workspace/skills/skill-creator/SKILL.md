---
name: skill-creator
description: Use when creating a new skill, updating an existing skill, or troubleshooting skill frontmatter, gating, or slash command registration issues in OpenClaw.
---

# Skill Creator

## Structure

```
skill-name/
├── SKILL.md          # Required
├── scripts/          # Executable scripts (Python/Bash)
├── references/       # Reference docs (loaded on demand)
└── assets/           # Output files (templates, images, etc.)
```

## Creation Workflow

1. **Understand requirements** — Clarify use cases and trigger conditions
2. **Plan resources** — Decide which scripts/references/assets are needed
3. **Initialize** — Run `init_skill.py` (for new skills)
4. **Write content** — Write resource files first, then SKILL.md
5. **Install locally** — Place in `~/.openclaw/workspace/skills/` and restart
6. **Iterate** — Improve based on real usage feedback

### Skill Loading Precedence

Skills are loaded from three locations (highest to lowest priority):

1. **Workspace skills**: `<workspace>/skills/`
2. **Managed/local skills**: `~/.openclaw/skills/`
3. **Bundled skills**: shipped with OpenClaw

Additional directories can be configured via `skills.load.extraDirs` in `openclaw.json`.

## Frontmatter Fields

### Required

```yaml
---
name: skill-name           # Hyphen-case identifier
description: ...           # Trigger conditions only (see rules below)
---
```

### Optional — Slash Command Control

```yaml
user-invocable: true            # Expose as slash command (default: true)
command-dispatch: tool           # Bypass model, dispatch directly to a tool
command-tool: <tool-name>        # Required when command-dispatch: tool
command-arg-mode: raw            # Forward raw args without parsing (default: raw)
disable-model-invocation: true   # Exclude from model prompt (still user-invocable)
```

### Optional — Other

```yaml
homepage: https://...      # "Website" link in macOS Skills UI
version: 1.0.0             # Semver (for distribution)
license: MIT               # License info (for distribution)
allowed-tools: [...]       # AgentSkills spec field
```

### metadata.openclaw

The `metadata` value **must be a single-line JSON object** (parser limitation).

```yaml
metadata: {"openclaw": {"emoji": "🛠️", "requires": {"bins": ["rg"]}, "install": [{"id": "brew", "kind": "brew", "formula": "ripgrep", "bins": ["rg"]}]}}
```

Complete sub-fields under `metadata.openclaw`:

| Field | Type | Description |
|-------|------|-------------|
| `always` | boolean | Skip all gates, always load |
| `emoji` | string | Display emoji in macOS Skills UI |
| `os` | string[] | Platform filter: `"darwin"`, `"linux"`, `"win32"` |
| `skillKey` | string | Override config key (instead of `name`) |
| `primaryEnv` | string | Env var for `skills.entries.<name>.apiKey` |
| `requires.bins` | string[] | All must exist on PATH |
| `requires.anyBins` | string[] | At least one must exist |
| `requires.env` | string[] | Env vars that must be set |
| `requires.config` | string[] | Dot-paths in openclaw.json that must be truthy |
| `install` | object[] | Installer specs (see below) |

### Install Specs

Each entry in the `install` array supports `kind`:

| Kind | Key Fields | Notes |
|------|-----------|-------|
| `brew` | `formula`, `bins` | Homebrew formula |
| `node` | `bins` | Honors `skills.install.nodeManager` config |
| `go` | `bins` | Auto-installs Go via brew if missing |
| `uv` | `bins` | Python package manager |
| `download` | `url`, `archive`, `targetDir` | Direct download |

## Parser Limitations

- Frontmatter keys must be **single-line only** (no multi-line values)
- `metadata` must be a **single-line JSON object**
- Use `{baseDir}` as a template variable to reference the skill folder path at runtime

## Description Writing Rules

**Core principle: describe trigger conditions only, never summarize the workflow.**

When a description contains workflow steps, the model may act on the summary directly and skip reading SKILL.md.

```yaml
# WRONG: contains workflow summary
description: Create skills - initialize directory, write SKILL.md, package for distribution

# WRONG: too vague
description: A guide for skills

# CORRECT: trigger conditions only
description: Use when creating or updating a skill, or troubleshooting frontmatter issues
```

**Guidelines:**
- Start with `Use when...`
- Include specific trigger scenarios, symptoms, and tool names
- Third person
- Keep under 500 characters
- Do not summarize execution steps

## Token Efficiency

| Type | Target |
|------|--------|
| Frequently loaded skills | < 200 words |
| General skills | < 500 words |
| SKILL.md total lines | < 500 |

**Token cost formula:** `195 + Σ(97 + len(name) + len(description) + len(location))` chars per eligible skill. Approximately 4 chars per token.

**Tips:**
- Move large reference material to `references/` for on-demand loading
- One good example beats multiple mediocre ones
- Don't repeat general knowledge the model already has

## SKILL.md Body Structure

```markdown
# Skill Name

## Overview (1-2 sentences)

## Workflow / Steps

## Key Parameters / Configuration

## Common Errors
```

See `references/design-patterns.md` for detailed patterns.

## Gating / Load-Time Filtering

Skills are filtered at load time based on `metadata.openclaw`:

1. `always: true` → always included
2. No `metadata.openclaw` → always eligible (unless disabled in config)
3. `os` → checked against current platform
4. `requires.bins` → all must exist on host PATH
5. `requires.anyBins` → at least one must exist
6. `requires.env` → must exist in environment or config
7. `requires.config` → dot-path must be truthy in openclaw.json
8. `enabled: false` in config → disabled regardless of gates

## Discord Slash Command Notes

After adding a new skill and restarting the gateway, Discord clients cache commands. New commands won't appear immediately — remind users to press `Cmd+R` (Mac) / `Ctrl+R` (Windows/Linux) to force refresh.

## Anti-Patterns

- **Narrative style** — "During a session we discovered..." → Use reusable pattern descriptions
- **Multi-language examples** — Same pattern in 5 languages → Pick the most relevant one
- **Workflow summary in description** — Causes the model to skip reading the body
- **Redundant explanations** — Don't explain what the model already knows
- **Unnecessary auxiliary files** — Don't create README.md, CHANGELOG.md, etc.
- **Multi-line metadata JSON** — Parser only supports single-line JSON objects
- **`command-dispatch: tool` without `command-tool`** — OpenClaw silently ignores the dispatch; the slash command won't register (logs: `Ignoring dispatch`)
