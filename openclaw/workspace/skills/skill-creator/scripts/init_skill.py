#!/usr/bin/env python3
"""
Skill Initializer - Creates a new OpenClaw skill from template.

Usage:
    init_skill.py <skill-name> --path <path>

Examples:
    init_skill.py my-new-skill --path ~/.openclaw/workspace/skills
    init_skill.py my-api-helper --path /custom/location
"""

import sys
from pathlib import Path


SKILL_TEMPLATE = """---
name: {skill_name}
description: "Use when [TODO: describe specific trigger conditions — user phrases, scenarios, or symptoms that should activate this skill. Do NOT summarize the workflow or execution steps here.]"
---

# {skill_title}

## Overview

[TODO: 1-2 sentences explaining what this skill enables]

## Structuring This Skill

[TODO: Choose the structure that best fits this skill's purpose:

**1. Workflow-Based** (sequential processes)
- Clear step-by-step procedures
- Structure: ## Overview → ## Workflow → ## Step 1 → ## Step 2...

**2. Task-Based** (tool collections)
- Different operations/capabilities
- Structure: ## Overview → ## Quick Start → ## Task Category 1 → ## Task Category 2...

**3. Reference/Guidelines** (standards or specifications)
- Brand guidelines, coding standards, requirements
- Structure: ## Overview → ## Guidelines → ## Specifications → ## Usage...

**4. Capabilities-Based** (integrated systems)
- Multiple interrelated features
- Structure: ## Overview → ## Core Capabilities → ### 1. Feature → ### 2. Feature...

See references/design-patterns.md for detailed patterns.
Delete this section when done — it's just guidance.]

## [TODO: First main section]

[TODO: Add content here]

## Resources

### scripts/
Executable code (Python/Bash) for deterministic tasks.
Scripts may be executed without loading into context.

### references/
Documentation loaded into context on demand.
Keep large docs here instead of in SKILL.md.

### assets/
Files used in output (templates, images, fonts).
Not loaded into context — used within the output the model produces.

**Delete any unneeded directories.** Not every skill requires all three.
"""

EXAMPLE_SCRIPT = '''#!/usr/bin/env python3
"""
Example helper script for {skill_name}.

Replace with actual implementation or delete if not needed.
"""


def main() -> None:
    print("This is an example script for {skill_name}")
    # TODO: Add actual script logic


if __name__ == "__main__":
    main()
'''

EXAMPLE_REFERENCE = """# Reference Documentation for {skill_title}

Replace with actual reference content or delete if not needed.

## When Reference Docs Are Useful

- Comprehensive API documentation
- Detailed workflow guides
- Complex multi-step processes
- Information too lengthy for SKILL.md
- Content only needed for specific use cases
"""


def title_case_skill_name(skill_name: str) -> str:
    """Convert hyphenated skill name to Title Case for display."""
    return " ".join(word.capitalize() for word in skill_name.split("-"))


def init_skill(skill_name: str, path: str) -> Path | None:
    """Initialize a new skill directory with template SKILL.md.

    Args:
        skill_name: Name of the skill (hyphen-case).
        path: Parent directory where the skill folder will be created.

    Returns:
        Path to the created skill directory, or None on error.
    """
    skill_dir = Path(path).resolve() / skill_name

    if skill_dir.exists():
        print(f"Error: Skill directory already exists: {skill_dir}")
        return None

    try:
        skill_dir.mkdir(parents=True, exist_ok=False)
        print(f"Created skill directory: {skill_dir}")
    except Exception as e:
        print(f"Error creating directory: {e}")
        return None

    # Create SKILL.md from template
    skill_title = title_case_skill_name(skill_name)
    skill_content = SKILL_TEMPLATE.format(
        skill_name=skill_name,
        skill_title=skill_title,
    )

    skill_md_path = skill_dir / "SKILL.md"
    try:
        skill_md_path.write_text(skill_content)
        print("Created SKILL.md")
    except Exception as e:
        print(f"Error creating SKILL.md: {e}")
        return None

    # Create resource directories with examples
    try:
        scripts_dir = skill_dir / "scripts"
        scripts_dir.mkdir(exist_ok=True)
        example_script = scripts_dir / "example.py"
        example_script.write_text(EXAMPLE_SCRIPT.format(skill_name=skill_name))
        example_script.chmod(0o755)
        print("Created scripts/example.py")

        references_dir = skill_dir / "references"
        references_dir.mkdir(exist_ok=True)
        example_reference = references_dir / "reference.md"
        example_reference.write_text(
            EXAMPLE_REFERENCE.format(skill_title=skill_title)
        )
        print("Created references/reference.md")
    except Exception as e:
        print(f"Error creating resource directories: {e}")
        return None

    print(f"\nSkill '{skill_name}' initialized at {skill_dir}")
    print("\nNext steps:")
    print("1. Edit SKILL.md — complete the TODO items and write the description")
    print("2. Customize or delete the example files in scripts/ and references/")
    print("3. Run quick_validate.py to check the skill structure")

    return skill_dir


def main() -> None:
    if len(sys.argv) < 4 or sys.argv[2] != "--path":
        print("Usage: init_skill.py <skill-name> --path <path>")
        print()
        print("Skill name requirements:")
        print("  - Hyphen-case (e.g., 'data-analyzer')")
        print("  - Lowercase letters, digits, and hyphens only")
        print("  - Max 64 characters")
        print()
        print("Examples:")
        print("  init_skill.py my-skill --path ~/.openclaw/workspace/skills")
        print("  init_skill.py my-api-helper --path /custom/location")
        sys.exit(1)

    skill_name = sys.argv[1]
    path = sys.argv[3]

    print(f"Initializing skill: {skill_name}")
    print(f"  Location: {path}")
    print()

    result = init_skill(skill_name, path)
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
