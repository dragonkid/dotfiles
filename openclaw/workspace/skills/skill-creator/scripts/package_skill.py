#!/usr/bin/env python3
"""
Skill Packager - Creates a distributable .skill file from a skill folder.

Usage:
    package_skill.py <path/to/skill-folder> [output-directory]

Examples:
    package_skill.py ~/.openclaw/workspace/skills/my-skill
    package_skill.py ~/.openclaw/workspace/skills/my-skill ./dist
"""

import sys
import zipfile
from pathlib import Path

# Support running from any directory by adding the script's own dir to path
_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from quick_validate import validate_skill  # noqa: E402


def package_skill(
    skill_path: str | Path, output_dir: str | Path | None = None
) -> Path | None:
    """Package a skill folder into a .skill file.

    Args:
        skill_path: Path to the skill folder.
        output_dir: Output directory for the .skill file (defaults to cwd).

    Returns:
        Path to the created .skill file, or None on error.
    """
    skill_path = Path(skill_path).resolve()

    if not skill_path.exists():
        print(f"Error: Skill folder not found: {skill_path}")
        return None

    if not skill_path.is_dir():
        print(f"Error: Path is not a directory: {skill_path}")
        return None

    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        print(f"Error: SKILL.md not found in {skill_path}")
        return None

    # Validate before packaging
    print("Validating skill...")
    valid, message = validate_skill(skill_path)
    if not valid:
        print(f"Validation failed: {message}")
        print("Please fix the validation errors before packaging.")
        return None
    print(f"{message}\n")

    # Determine output location
    skill_name = skill_path.name
    if output_dir:
        output_path = Path(output_dir).resolve()
        output_path.mkdir(parents=True, exist_ok=True)
    else:
        output_path = Path.cwd()

    skill_filename = output_path / f"{skill_name}.skill"

    try:
        with zipfile.ZipFile(skill_filename, "w", zipfile.ZIP_DEFLATED) as zipf:
            for file_path in skill_path.rglob("*"):
                if file_path.is_file():
                    arcname = file_path.relative_to(skill_path.parent)
                    zipf.write(file_path, arcname)
                    print(f"  Added: {arcname}")

        print(f"\nSuccessfully packaged skill to: {skill_filename}")
        return skill_filename

    except Exception as e:
        print(f"Error creating .skill file: {e}")
        return None


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: package_skill.py <path/to/skill-folder> [output-directory]")
        print()
        print("Examples:")
        print("  package_skill.py ~/.openclaw/workspace/skills/my-skill")
        print("  package_skill.py ~/.openclaw/workspace/skills/my-skill ./dist")
        sys.exit(1)

    skill_path = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else None

    print(f"Packaging skill: {skill_path}")
    if output_dir:
        print(f"  Output directory: {output_dir}")
    print()

    result = package_skill(skill_path, output_dir)
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
