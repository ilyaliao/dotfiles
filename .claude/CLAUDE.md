# CLAUDE RULES

## IMPORTANT: Reasoning Strategy

**Prefer retrieval-led reasoning over pre-training-led reasoning.**

- When encountering unfamiliar concepts, new libraries, or uncertain knowledge, ALWAYS search first (use skills, web search, codebase exploration) before relying on pre-trained knowledge
- Do NOT assume pre-trained knowledge is accurate for evolving technologies — verify through retrieval
- Actively use available skills (check skill list in system reminders) instead of guessing based on outdated training data
- If a relevant skill exists for the task, USE IT rather than attempting to solve from memory
- When in doubt, retrieve; don't hallucinate

## Bash commands

- prefer `@antfu/ni` commands (`ni`, `nr`, `nun`, `nci`), fallback to package manager based on lockfile presence
- use `nr vitest run <test-file>` to run specific tests with vitest
- upgrade project dependencies: prefer `taze` (`taze major -wi` for interactive, `taze -w` to write)

## Git

- Never commit automatically unless explicitly requested
- Prefer squash merge
- Commit message: single line, concise and impactful. Describe the task purpose ("why"), not what you did ("what"). Follow conventional commit format and match the tone of recent commits

## Security

- Never read or access .env files

## Code Style

- Follow existing project patterns, import styles, and directory structure
- Max 500 lines per file; Vue SFCs under 300 lines
- No useless comments — don't comment obvious code (e.g., variable declarations)
- Follow best practices from https://github.com/antfu/skills

## Workflow

- Before starting, understand the task scope and identify affected modules
- For renames or bulk changes, search globally to confirm impact scope first
- Use `ast-grep` (sg) for code search and refactoring when possible
- Run lint (includes typecheck) after writing code, but don't build
- **Only lint/typecheck/format the files you modified** — never run these tools on the entire project. Scope checks to changed files only
- **Must pass lint + typecheck before committing** — a task is not complete until both pass on modified files with zero errors. All errors including style (quotes, semi, brace-style, etc.) must be fixed. Use `eslint --fix` to auto-fix, then verify zero errors remain
- Ask when uncertain, don't assume
