---
name: guide
description: Use when need quick reference for installed plugins, workflow optimization patterns, or database MCP configuration
---

# Documentation Guide

Quick access to setup documentation. Call with topic name or without arguments to see all topics.

## Available Topics

| Topic | Content |
|-------|---------|
| `plugins` | 17 installed plugins overview, decision tree, workflows |
| `workflow` | Workflow optimization patterns from 169 sessions data |
| `database-mcp` | Database MCP configuration, security, troubleshooting |

## Usage

```bash
# Show specific topic
/guide plugins
/guide workflow
/guide database-mcp

# Show all topics (this overview)
/guide
```

## Quick Links

- **Plugins**: See `plugins.md` for complete plugin ecosystem guide
- **Workflow**: See `workflow.md` for optimization patterns and best practices
- **Database MCP**: See `database-mcp.md` for production-ready configurations

## How It Works

This skill reads detailed reference files on demand. Each topic file contains comprehensive documentation that would be too large to load in every conversation.

When you specify a topic, the relevant reference file is loaded and summarized.
