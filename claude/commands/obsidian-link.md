---
description: Find related notes and suggest wikilinks for a given note
---

Analyze a note and find related notes in the Obsidian vault at ~/Documents/second-brain.

Input: $ARGUMENTS (path to a note, relative or absolute; if relative, resolve from ~/Documents/second-brain)

Steps:
1. Read the target note
2. Extract key topics, terms, and concepts
3. Use mgrep to search the vault for notes containing related content
4. For each related note found, suggest a [[wikilink]] with context on why it's related
5. Ask the user which links to add, then insert them into a "## Related" section at the end of the note
