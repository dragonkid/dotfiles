---
name: prompt-improver
description: Improve prompts for clarity, specificity, and effectiveness using prompt engineering best practices
---

Use this skill when the user asks to improve, optimize, rewrite, or refine a prompt for an AI model.

## When to Use
- User asks to "improve this prompt" or "make this prompt better"
- User wants to optimize prompt effectiveness
- User requests prompt rewrite or refinement
- User needs help making prompts clearer or more specific
- User asks to fix or debug a prompt that isn't working well

## Optimization Process

1. **Analyze the original prompt** — Identify the core task, missing context, ambiguity, and verbosity
2. **Apply optimization priorities** — Rewrite following the framework below
3. **Verify against quality criteria** — Ensure the improved prompt meets all standards
4. **Present the result** — Show the improved prompt with brief explanation of key changes

## Optimization Framework

Apply these priorities in order:

1. **Explicit Instruction First** — Main instruction or task goal at the beginning
2. **Role & Context** — Brief relevant role (if needed) and essential background only
3. **Conciseness** — Remove filler, redundancy, unnecessary qualifiers. Every word serves purpose
4. **Specific Task Definition** — Precise, action-oriented verbs
5. **Output Schema or Format** — Clear response format definition
6. **Constraints** — Key limitations only. Avoid over-specification
7. **Examples (Few-Shot)** — One concise example only if it materially clarifies the pattern
8. **Neutrality & Safety** — Preserve factual tone, avoid assumptions, ensure objectivity

## Writing Guidelines

- Prefer bullet points or numbered steps for clarity
- Use positive instructions ("Do X") instead of negative ("Don't do X")
- Avoid vague words ("things," "somehow," "etc.")
- Combine related ideas into single, efficient statements
- Keep structure readable with delimiters or sections when logical
- When rephrasing variables, retain their exact identifiers
- Never invent new variables unless explicitly required

## Quality Criteria

A high-quality improved prompt must be:
- Clear enough that no further clarification is needed
- Structured for deterministic results
- Free from redundancy, filler, and ambiguity
