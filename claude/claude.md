# Global Preferences

## General
- Use best practices as much as possible

## Git Commits
- Do not execute commits unless explicitly requested by the user
- Do not add "Co-Authored-By: Claude <noreply@anthropic.com>" to commit messages
- Keep commit messages concise and focused on the "what" and "why"
- Use conventional commit format when appropriate (feat, fix, docs, refactor, etc.)

## Code Style
- Prefer simplicity over complexity
- Avoid over-engineering - only add what's explicitly needed
- Don't add comments, docstrings, or type annotations unless requested
- Keep solutions minimal and focused on the task at hand

## Communication
- Be concise - skip unnecessary explanations
- Don't use emojis unless explicitly requested
- Avoid superlatives and excessive praise
- Focus on technical accuracy over validation

## Tool Usage
- Use specialized tools (Read, Edit, Grep, Glob) over bash commands for file operations
- Run independent commands in parallel when possible
- Always read files before editing them
- Use context7 to get up-to-date documentation for libraries and frameworks

## Security
- Never commit files with secrets (.env, credentials, API keys)
- Warn about security vulnerabilities when detected
- Prefer secure patterns (parameterized queries, input validation at boundaries)
