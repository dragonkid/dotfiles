---
description: "Update the project's CLAUDE.md to reflect current architecture, modules, and conventions"
---

# Update Project Context

Review the project's CLAUDE.md against the current state of the codebase. Only update sections that are factually outdated — do not rewrite unchanged sections.

## Steps

1. Read the project's CLAUDE.md (at the repo root).
2. Compare each section against the actual codebase:
   - **Overview**: Does it still accurately describe the project?
   - **Architecture**: Are module boundaries, key directories, and entry points current?
   - **Key Commands**: Do listed commands still work? Any new ones missing?
   - **Conventions/Guidelines**: Do they match actual patterns in the code?
3. Check for undocumented additions since the last CLAUDE.md update:
   - New top-level directories or modules
   - New entry points, schemas, or config files
   - Changed build/deploy tooling
4. Apply minimal edits to bring outdated sections up to date. Preserve the existing structure and tone.
5. If nothing is outdated, report that and do not modify the file.
