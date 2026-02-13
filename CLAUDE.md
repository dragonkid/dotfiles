# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles repo managing dev environment configs across macOS and Linux. Configs are stored here and symlinked to home directory via install scripts.

## Key Commands

```bash
./install.sh                    # macOS full setup (idempotent)
./install.sh --brew             # Include Homebrew + Brewfile
./install.sh --hammerspoon      # Include Hammerspoon
./install.sh --openclaw         # Include OpenClaw
sudo ./init_server.sh           # Linux server (lighter, no vim/claude)
```

## Architecture

### Symlink Strategy

Install scripts use `link_config()` to create symlinks from this repo to `~/`. Existing non-symlink files are backed up before linking.

### Claude Code Config (`claude/` → `~/.claude/`)

The `claude/` directory is the source of truth for Claude Code configuration. Symlinked items:
- `claude.md` → global CLAUDE.md instructions
- `settings.json` → permissions, plugins, model, MCP servers
- `rules/` → ECC rules (common + language-specific)
- `skills/`, `commands/`, `hooks/`, `hooks.json`, `statusline.sh`

Not symlinked (runtime state): `sessions/`, `plans/`, `plugins/`, `cache/`, `history.jsonl`

### Git Clean Filter for Claude Settings

`.gitattributes` applies a `claude-settings` filter to `claude/settings.json`:
- **Clean** (on commit): `jq 'del(.fastMode, .model)'` strips volatile local settings
- **Smudge** (on checkout): passthrough

This means `model` and `fastMode` exist in the working copy but are never committed. After checkout, set them manually or they'll be absent from settings.json.

### Machine-Specific Git Config

`~/.gitconfig.local` (created by install scripts, not tracked) holds user email, signing keys, and credential helpers. Included via `[include]` in `gitconfig`.

## Editing Guidelines

- After modifying configs, verify `install.sh` still handles symlinks correctly
- `claude/settings.json`: volatile keys (`fastMode`, `model`) are stripped on commit by the clean filter — don't be surprised when they're missing in git diff/log
- `claude/rules/`: flat `.md` files, organized by `common/`, `golang/`, `python/`, `typescript/`
- `zshrc`: Claude Code env vars (`CLAUDE_CODE_EFFORT_LEVEL`, `MAX_THINKING_TOKENS`) are near the end

## TODO

- [ ] Configure per-agent model tiers to reduce costs: create `~/.claude/agents/` override files setting lightweight agents (build-error-resolver, refactor-cleaner, doc-updater) to `model: haiku`, mid-tier agents (code-reviewer, tdd-guide) to `model: sonnet`, and keep complex reasoning agents (architect, planner, security-reviewer) on `model: opus`
- [ ] After ECC upgrades, check if `everything-claude-code:verification-loop` has frontmatter — if so, delete local wrapper `claude/skills/verification-loop/SKILL.md` and update `feature-workflow.md` to use `everything-claude-code:verification-loop`
- [ ] After ECC upgrades, check if `observe.sh` (JSON triple-quote parse bug) and `suggest-compact.sh` (`$$` PID counter bug) are fixed upstream — if so, switch `settings.json` hooks back to plugin paths and remove `claude/hooks/{observe,suggest-compact}.sh`
- [ ] After ECC upgrades, check observer trigger mechanism — if fixed upstream (e.g., SessionStart hook), remove `/analyze-observations` command; if observer updated but command still needed, update command to align with new observer logic
