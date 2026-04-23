---
name: antfu-check
description: Audit files against Anthony Fu's best practices (@antfu/eslint-config + antfu/skills). Reports violations as a checklist with severity levels and links to the source skill for fixes. Covers Vue SFCs, TypeScript, pnpm monorepos, library publishing, and project setup.
disable-model-invocation: true
allowed-tools: Read Grep Glob Bash(git diff:*) Bash(git status:*) Bash(git ls-files:*) Bash(git rev-parse:*)
---

# antfu-check

Audit files against Anthony Fu's best practices and report violations as a checklist with fix references.

The authoritative source is **[antfu/skills](https://github.com/antfu/skills)** on GitHub. This skill does not modify files — it only reports. The user reads the checklist and decides what to fix.

## Report language

Always emit the report in **繁體中文台灣用語**. Keep these untranslated so downstream tools can parse them:

- Section markers: `## Summary`, `## Violations`, `## Clean files`, `## Skipped`, `## Possible additions`
- Field labels inside violations: `Evidence`, `Fix`, `Source`
- Rule IDs (`vue-sfc/sfc-script-setup`), file paths, code excerpts, and URLs
- Severity emoji (🔴 / 🟡 / 🔵) and the English token after them (`Error` / `Warning` / `Info`)

Translate to 繁體中文台灣用語: the short rule description after the em dash, every `Evidence` / `Fix` value, and any prose outside the structured blocks (summaries, skipped reasons, possible additions, questions to the user). Technical terms and API names stay in their original form (`<script setup>`, `ref`, `reactive`, `compilerOptions.strict`, etc.).

## Workflow

### 1. Determine scope

Default scope is **files changed since HEAD** (staged + unstaged):

```bash
git diff HEAD --name-only --diff-filter=ACMR
```

Overrides:

- If the user passed paths or globs in the invocation, use those instead.
- If `--all` was requested, use `git ls-files`.
- If `git` is unavailable or no changes exist, ask the user which files to audit.

Filter to auditable extensions: `.ts`, `.tsx`, `.js`, `.mjs`, `.cjs`, `.vue`, `.json`, `.yml`, `.yaml`, and known config filenames (`tsconfig.json`, `eslint.config.*`, `pnpm-workspace.yaml`, `tsdown.config.*`, `vitest.config.*`, `.gitignore`, `.vscode/*.json`, `.github/workflows/*.yml`).

### 2. Detect project stack

Read these once to build a stack profile. Use parallel Reads.

- **`package.json`**: scan `dependencies`/`devDependencies` for `vue`, `nuxt`, `vitest`, `pinia`, `vue-router`, `@vueuse/core`, `unocss`, `tsdown`, `tsup`, `@antfu/eslint-config`. Note `type`, `exports`, `files`, `packageManager`, `scripts`.
- **`pnpm-workspace.yaml`**: exists? → `isMonorepo = true`. Parse `catalogs` block if present.
- **`tsconfig.json`**: exists? note `compilerOptions.strict`, `module`, `moduleResolution`, `isolatedModules`.
- **`eslint.config.*`**: exists? uses `antfu()`?
- **Library vs app heuristic**: library if `package.json` has `exports` + `files` + uses `tsdown`/`tsup` in build script. Otherwise app.

Record a compact stack profile mentally (no need to print it to the user yet).

### 3. Select applicable references

Load only the reference files you need. Each one lists concrete rules with IDs, severity, detection hints, and fix links.

| Load this reference                | When                                                                  |
| ---------------------------------- | --------------------------------------------------------------------- |
| `references/project-setup.md`      | Always (covers tsconfig, eslint, vscode, gitignore, workflows)        |
| `references/pnpm-monorepo.md`      | `isMonorepo` OR `pnpm-workspace.yaml` in scope                        |
| `references/library-publishing.md` | `isLibrary` OR `tsdown.config.*`/`package.json` of a library in scope |
| `references/vue-sfc.md`            | Any `*.vue` in scope                                                  |
| `references/vue-reactivity.md`     | Any `*.vue` in scope OR composable files (`src/composables/**/*.ts`)  |
| `references/vue-router.md`         | `vue-router` in deps AND any `router/**` or route component in scope  |
| `references/vue-testing.md`        | `vitest` in deps AND any `*.{test,spec}.*` in scope                   |

If a reference would apply but no file in scope triggers its rules, skip loading it.

### 4. Audit

#### 4a. Decide: serial or parallel

Count `R` = number of references selected in Step 3 and `F` = number of files in scope.

- **Parallel** when `R >= 3` **OR** (`F >= 8` **AND** `R >= 2`) → go to 4c
- **Serial** otherwise → go to 4b

Rationale for the threshold: each reference is independent and audit is read-only, so parallelism is safe. The cost is context + orchestration overhead, which only pays off once references and files multiply. Below the threshold, running in the main agent is faster.

#### 4b. Serial audit (in this agent)

For each rule in each loaded reference:

1. Check whether the rule applies to any file in scope.
2. Run the detection (Grep for patterns, Read + reason for AST-level checks, parse JSON inline for config rules).
3. Record the result: pass / fail / not-applicable.

**Be concrete.** For every violation, capture `file:line` (or file-level for config rules). Cite the exact matched text when practical.

**Stay conservative.** If a rule's detection is ambiguous (e.g., could be a legitimate edge case), mark it 🔵 Info instead of 🟡/🔴. Don't claim violations you can't evidence.

Skip to Step 5.

#### 4c. Parallel audit (dispatch sub-agents)

Resolve each reference to an **absolute path** first (the skill lives at `~/.claude/skills/antfu-check/references/<name>.md`; use `git rev-parse --show-toplevel` if you need the repo root for the file list).

Spawn one `general-purpose` sub-agent per reference in a **single message with multiple `Agent` tool calls** so they run concurrently. Give each sub-agent exactly this brief, filling in the bracketed placeholders:

````
You are auditing files against ONE Anthony Fu best-practice reference. Report violations only — do not modify any file.

Reference (absolute path): [e.g. /Users/me/.claude/skills/antfu-check/references/vue-sfc.md]
Files in scope (absolute paths, newline-separated):
[file list]
Stack profile: [compact line from Step 2, e.g. "vue 3, vitest, pnpm monorepo, library=false"]

Steps:
1. Read the reference file in full.
2. For each rule in the reference, check whether it applies to any file in scope. Skip non-applicable rules silently.
3. For applicable rules, run the detection described (Grep for patterns, Read for AST-level checks, inline JSON parse for config rules). Only use Read, Grep, Glob. Do not write, edit, or run shell commands beyond what's needed for detection.
4. For each violation, capture file:line and the matched text. Be conservative — downgrade ambiguous cases to 🔵 Info.

Output format (繁體中文台灣用語 for prose; keep rule IDs, field labels, paths, and emoji+English token untranslated):

```
## <reference-slug>

### `<file-path>`

**🔴 Error <rule-id>** — <繁中簡述>
- Evidence: L<n> `<matched code>`
- Fix: <繁中修正說明>
- Source: [antfu/skills → <...>](<url>) (also: local skill `<name>`)

<repeat per violation; group by file>
```

If no violations found for this reference, return exactly:
```
## <reference-slug>
(無違規)
```

Also return a final line:
`__meta__ rules_checked=<n> files_audited=<n>`

Length: under 600 words unless violations genuinely require more.
````

#### 4d. Aggregate sub-agent results

The sub-agents group violations by reference (`## <reference-slug>` → `### <file>`). The final report in Step 5 groups by file instead. Transform:

1. Parse each sub-agent response. Drop `(無違規)` blocks. Collect `__meta__` lines.
2. Build a dict `violations_by_file: { <file-path>: [violation-entry, ...] }` by iterating each `### <file>` section across all sub-agents and appending its violation entries.
3. Emit the Step 5 report's `## Violations` section by iterating `violations_by_file` (one `### <file>` heading per key, all collected entries beneath — preserve the original entry text verbatim, including the `Source:` line).
4. Sum `rules_checked` from all `__meta__` lines → `Rules evaluated:` in the header.
5. If a sub-agent failed or timed out, note it in the `## Skipped` section (e.g., `規則集 vue-sfc(sub-agent 未回應,已略過)`) rather than re-running serially — the user can retry.

### 5. Emit the report

Use this exact structure. The header, summary, and violation entry shape matter — downstream tools parse them.

```markdown
# antfu-check Report

**Scope**: <e.g., `git diff HEAD` (6 files) | user-specified>
**Stack**: <e.g., vue, vitest, pnpm monorepo, library>
**References loaded**: <vue-sfc, vue-reactivity, project-setup>
**Rules evaluated**: <count>

## Summary

- 🔴 Errors: E
- 🟡 Warnings: W
- 🔵 Info: I

## Violations

### `src/components/UserCard.vue`

**🔴 Error vue-sfc/sfc-script-setup** — SFC 應使用 `<script setup lang="ts">`

- Evidence: L1 `export default defineComponent({ ... })`
- Fix: 改寫為 `<script setup lang="ts">`,將 `props`/`data`/`methods` 遷移到 Composition API。
- Source: [antfu/skills → vue-best-practices/references/sfc.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/sfc.md) (also: local skill `vue-best-practices`)

**🟡 Warning vue-sfc/style-scoped** — `<style>` 區塊缺少 `scoped`

- Evidence: L45 `<style lang="scss">`
- Fix: 除非這是全域樣式表,否則加上 `scoped`。
- Source: [antfu/skills → vue-best-practices/references/sfc.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/sfc.md)

### `tsconfig.json`

**🔴 Error project-setup/tsconfig-strict** — `compilerOptions.strict` 未設為 `true`

- Evidence: `"strict": false`
- Fix: 設為 `"strict": true`,啟用所有嚴格型別檢查。
- Source: [antfu/skills → antfu/SKILL.md](https://github.com/antfu/skills/blob/main/skills/antfu/SKILL.md) (also: local skill `antfu`)

## Clean files

- `src/composables/useCounter.ts` — 已檢查 7 條規則,無違規
- `package.json` — 已檢查 5 條規則,無違規

## Skipped

- `src/assets/logo.svg`(二進位檔)
- 規則 `pnpm-monorepo/catalog-usage`(專案無 `pnpm-workspace.yaml`)
```

## Severity guide

Assign severity based on how confidently and universally a rule applies:

- **🔴 Error** — Clear violation; almost always wrong in antfu's conventions.
  - Examples: Options API in new Vue code, `strict: false` in tsconfig, `v-if` and `v-for` on the same element, mutating `props.*`, destructuring the return value of `reactive()`, committed `yarn.lock` alongside `pnpm-lock.yaml`.
- **🟡 Warning** — antfu preference; usually right but context-dependent.
  - Examples: `shallowRef` instead of `ref` for primitives, missing `scoped` on `<style>`, catalog usage in pnpm workspace, no `simple-git-hooks` + `lint-staged` block.
- **🔵 Info** — Organization / nice-to-have.
  - Examples: extract types to `types.ts`, add `// @env node` header, prefer `useTemplateRef()` over `ref(null)` + `ref="foo"`.

When a detection is fuzzy, downgrade by one level. Prefer 🔵 over a false 🟡.

## Citation format

Every violation must end with a **Source:** line. Use this exact pattern:

```
- Source: [antfu/skills → <domain>/<file>.md](https://github.com/antfu/skills/blob/main/skills/<path>) (also: local skill `<skill-name>`)
```

If the rule has no direct local skill equivalent, drop the `(also: local skill …)` suffix.

## Boundaries

- **Report only.** Never modify files, never run `eslint --fix`, never commit.
- **Manual only.** This skill is `disable-model-invocation: true`; it runs only when the user explicitly invokes `/antfu-check` or references it by name.
- **No hallucinated rules.** Only report rules that appear in a loaded reference file. If you think something is an antfu rule but it's not in any reference, don't fabricate it — note it in a final `## Possible additions` section for the user instead.
- **Don't over-reach.** If the scope is 3 files, audit those 3 files. Don't audit sibling files unless they're config files the detected rules require (e.g., `tsconfig.json` for a TS rule).

## Reference files

Each reference in `references/` follows the same shape: a short intro, then one section per rule with:

- **ID**: `<domain>/<slug>` (e.g., `vue-sfc/sfc-script-setup`)
- **Severity**: 🔴 / 🟡 / 🔵
- **Applies to**: glob or description of target files
- **Detection**: how to check (regex, JSON lookup, AST pattern)
- **Fix**: what to change
- **Source**: link to antfu/skills + optional local skill

See `references/project-setup.md` for a worked example of this format.
