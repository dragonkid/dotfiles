---
name: python-project-toolchain
description: Use when starting a new Python project, auditing existing project toolchain, upgrading legacy project infrastructure, or onboarding to unfamiliar Python codebases that need standard development infrastructure.
---

# Python Project Toolchain

## Overview
Standard Python project toolchain components and configuration for modern development workflows with uv, ruff, pyright, pytest, and pre-commit hooks.

## When to Use
- Starting a new Python project
- Auditing existing project toolchain
- Upgrading legacy project infrastructure
- Onboarding to unfamiliar Python codebase

## Recommended Toolchain

| Category | Tool | Alternative |
|----------|------|-------------|
| Package Management | `uv` | poetry, pip + hatchling |
| Build Backend | `hatchling` | setuptools, flit |
| Task Runner | `Makefile` | just, invoke, taskipy |
| Linting/Formatting | `ruff` | black + isort + flake8 |
| Type Checking | `pyright` | mypy |
| Testing | `pytest` | unittest |
| Pre-commit | `pre-commit` | lefthook |
| CI/CD | GitHub Actions | GitLab CI, CircleCI |
| Containerization | Docker (multi-stage) | - |
| Debugging | `ipdb` | pdb++ |

## Quick Setup Commands

```bash
# Initialize with uv
uv init project-name
cd project-name

# Install dev dependencies
uv pip install -e ".[dev]"

# Setup pre-commit
pre-commit install

# Verify toolchain
make lint type-check test
```

## Configuration Files

```
project/
├── pyproject.toml      # Package config, tool settings
├── Makefile            # Common tasks
├── Dockerfile          # Container build
├── .gitignore
├── .env.example        # Environment template
├── .pre-commit-config.yaml
└── tests/
    └── conftest.py     # pytest fixtures
```

## Common Mistakes
- Not using task runner (Makefile/just) for common operations
- Forgetting to configure pre-commit hooks
- Not setting up proper type checking configuration
