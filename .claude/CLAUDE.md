# CLAUDE RULES

## Core Principle

Prefer the simplest solution that actually works — no speculative abstractions, no defensive code for impossible cases, no "just in case" features. Clarity beats cleverness; fewer lines beat more lines when readability is equal.

## IMPORTANT: Reasoning Strategy

**Prefer retrieval-led reasoning over pre-training-led reasoning.**

- When encountering unfamiliar concepts, new libraries, or uncertain knowledge, ALWAYS search first (use skills, web search, codebase exploration) before relying on pre-trained knowledge
- Do NOT assume pre-trained knowledge is accurate for evolving technologies — verify through retrieval
- Actively use available skills (check skill list in system reminders) instead of guessing based on outdated training data
- If a relevant skill exists for the task, USE IT rather than attempting to solve from memory
- When in doubt, retrieve; don't hallucinate

## Git

- Never commit automatically unless explicitly requested
- Unless explicitly instructed otherwise, prefer rebase over merge commits when integrating or updating branch history

## Security

- Never read or access .env files

## Code Style

- Follow existing project patterns, import styles, and directory structure
- Max 500 lines per file;
- No useless comments — don't comment obvious code (e.g., variable declarations)

## Workflow

- Before starting, understand the task scope and identify affected modules
- For renames or bulk changes, search globally to confirm impact scope first
- Ask when uncertain, don't assume
