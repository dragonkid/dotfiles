#!/usr/bin/env python3
"""
Quick validation script for OpenClaw skills.

Validates SKILL.md frontmatter against the official OpenClaw specification:
https://docs.openclaw.ai/tools/skills

No external dependencies — uses simple YAML parsing for flat frontmatter.
"""

import json
import re
import sys
from pathlib import Path
from typing import Any


# All frontmatter fields supported by OpenClaw + AgentSkills spec
ALLOWED_PROPERTIES: set[str] = {
    # Required
    "name",
    "description",
    # Slash command control
    "user-invocable",
    "command-dispatch",
    "command-tool",
    "command-arg-mode",
    "disable-model-invocation",
    # Other optional
    "homepage",
    "version",
    "license",
    "allowed-tools",
    "metadata",
}


def _parse_flat_yaml(text: str) -> dict[str, Any]:
    """Parse flat (single-level) YAML frontmatter without external dependencies.

    OpenClaw's parser only supports single-line frontmatter keys, so this
    simple parser is sufficient. The `metadata` field is parsed as JSON.
    """
    result: dict[str, Any] = {}
    for line in text.strip().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        match = re.match(r"^([a-zA-Z][a-zA-Z0-9_-]*)\s*:\s*(.*)", line)
        if not match:
            continue
        key = match.group(1)
        value_str = match.group(2).strip()

        # Strip surrounding quotes
        if (value_str.startswith('"') and value_str.endswith('"')) or (
            value_str.startswith("'") and value_str.endswith("'")
        ):
            value_str = value_str[1:-1]

        # Parse typed values
        if key == "metadata":
            try:
                result[key] = json.loads(value_str)
            except json.JSONDecodeError:
                result[key] = value_str  # store raw; validation will catch it
        elif value_str.lower() == "true":
            result[key] = True
        elif value_str.lower() == "false":
            result[key] = False
        elif value_str.startswith("[") and value_str.endswith("]"):
            try:
                result[key] = json.loads(value_str)
            except json.JSONDecodeError:
                result[key] = value_str
        else:
            result[key] = value_str

    return result


def validate_skill(skill_path: str | Path) -> tuple[bool, str]:
    """Validate a skill directory against OpenClaw spec.

    Args:
        skill_path: Path to the skill directory.

    Returns:
        Tuple of (is_valid, message).
    """
    skill_path = Path(skill_path)

    # Check SKILL.md exists
    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        return False, "SKILL.md not found"

    # Read and validate frontmatter
    content = skill_md.read_text()
    if not content.startswith("---"):
        return False, "No YAML frontmatter found"

    # Extract frontmatter
    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return False, "Invalid frontmatter format"

    frontmatter = _parse_flat_yaml(match.group(1))

    if not frontmatter:
        return False, "Frontmatter is empty or could not be parsed"

    # Check for unexpected properties
    unexpected_keys = set(frontmatter.keys()) - ALLOWED_PROPERTIES
    if unexpected_keys:
        return False, (
            f"Unexpected key(s) in SKILL.md frontmatter: {', '.join(sorted(unexpected_keys))}. "
            f"Allowed properties are: {', '.join(sorted(ALLOWED_PROPERTIES))}"
        )

    # Check required fields
    if "name" not in frontmatter:
        return False, "Missing 'name' in frontmatter"
    if "description" not in frontmatter:
        return False, "Missing 'description' in frontmatter"

    # Validate name
    name: Any = frontmatter.get("name", "")
    if not isinstance(name, str):
        return False, f"Name must be a string, got {type(name).__name__}"
    name = name.strip()
    if name:
        if not re.match(r"^[a-z0-9-]+$", name):
            return False, (
                f"Name '{name}' should be hyphen-case "
                "(lowercase letters, digits, and hyphens only)"
            )
        if name.startswith("-") or name.endswith("-") or "--" in name:
            return False, (
                f"Name '{name}' cannot start/end with hyphen "
                "or contain consecutive hyphens"
            )
        if len(name) > 64:
            return False, (
                f"Name is too long ({len(name)} characters). "
                "Maximum is 64 characters."
            )

    # Validate description
    description: Any = frontmatter.get("description", "")
    if not isinstance(description, str):
        return False, f"Description must be a string, got {type(description).__name__}"
    description = description.strip()
    if description:
        if "<" in description or ">" in description:
            return False, "Description cannot contain angle brackets (< or >)"
        if len(description) > 1024:
            return False, (
                f"Description is too long ({len(description)} characters). "
                "Maximum is 1024 characters."
            )

    # Validate command-dispatch requires command-tool
    if frontmatter.get("command-dispatch") == "tool":
        if "command-tool" not in frontmatter:
            return False, (
                "command-dispatch: tool requires command-tool to be set. "
                "Without it, OpenClaw silently ignores the dispatch."
            )

    # Validate metadata is a dict if present
    metadata: Any = frontmatter.get("metadata")
    if metadata is not None and not isinstance(metadata, dict):
        return False, (
            f"metadata must be a JSON object (dict), got {type(metadata).__name__}. "
            "Remember: metadata must be a single-line JSON object in frontmatter."
        )

    return True, "Skill is valid!"


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python quick_validate.py <skill_directory>")
        sys.exit(1)

    valid, message = validate_skill(sys.argv[1])
    print(message)
    sys.exit(0 if valid else 1)
