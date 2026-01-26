# Python Project Toolchain

**Extracted:** 2026-01-26
**Context:** Setting up or reviewing Python project development infrastructure

## Problem
Need a reference for standard Python project toolchain components and configuration.

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

## pyproject.toml Template

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "project-name"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-asyncio>=0.24",
    "ruff>=0.8",
    "pyright>=1.1",
    "ipdb>=0.13",
]

[tool.ruff]
line-length = 100
target-version = "py311"
select = ["E", "F", "I", "W"]

[tool.pyright]
pythonVersion = "3.12"
typeCheckingMode = "basic"

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

## Makefile Template

```makefile
.PHONY: install test lint format type-check clean

install:
	uv pip install -e ".[dev]"

test:
	pytest tests/ -v

lint:
	ruff check .

format:
	ruff format .

type-check:
	pyright

clean:
	rm -rf .ruff_cache .pytest_cache __pycache__ dist build *.egg-info
```

## .pre-commit-config.yaml Template

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/RobertCraiworthy/pyright-python
    rev: v1.1.390
    hooks:
      - id: pyright
```

## When to Use

- Starting a new Python project
- Auditing existing project toolchain
- Upgrading legacy project infrastructure
- Onboarding to unfamiliar Python codebase

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
