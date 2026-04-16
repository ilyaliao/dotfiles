---
name: antfu-check
description: Audit files against Anthony Fu's best practices (@antfu/eslint-config + antfu/skills). Reports violations as a checklist with severity levels and links to the source skill for fixes. Covers Vue SFCs, TypeScript, pnpm monorepos, library publishing, and project setup.
disable-model-invocation: true
allowed-tools: Read Grep Glob Bash(git diff:*) Bash(git status:*) Bash(git ls-files:*) Bash(git rev-parse:*)
---

# antfu-check

Audit files against Anthony Fu's best practices and report violations as a checklist with fix references.

The authoritative source is **[antfu/skills](https://github.com/antfu/skills)** on GitHub. This skill does not modify files — it only reports. The user reads the checklist and decides what to fix.

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

| Load this reference | When |
|---|---|
| `references/project-setup.md` | Always (covers tsconfig, eslint, vscode, gitignore, workflows) |
| `references/pnpm-monorepo.md` | `isMonorepo` OR `pnpm-workspace.yaml` in scope |
| `references/library-publishing.md` | `isLibrary` OR `tsdown.config.*`/`package.json` of a library in scope |
| `references/vue-sfc.md` | Any `*.vue` in scope |
| `references/vue-reactivity.md` | Any `*.vue` in scope OR composable files (`src/composables/**/*.ts`) |
| `references/vue-router.md` | `vue-router` in deps AND any `router/**` or route component in scope |
| `references/vue-testing.md` | `vitest` in deps AND any `*.{test,spec}.*` in scope |

If a reference would apply but no file in scope triggers its rules, skip loading it.

### 4. Audit

For each rule in each loaded reference:

1. Check whether the rule applies to any file in scope.
2. Run the detection (Grep for patterns, Read + reason for AST-level checks, parse JSON inline for config rules).
3. Record the result: pass / fail / not-applicable.

**Be concrete.** For every violation, capture `file:line` (or file-level for config rules). Cite the exact matched text when practical.

**Stay conservative.** If a rule's detection is ambiguous (e.g., could be a legitimate edge case), mark it 🔵 Info instead of 🟡/🔴. Don't claim violations you can't evidence.

### 5. Emit the report

Use this exact structure. The header, summary, and violation entry shape matter — downstream tools parse them.

````markdown
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

**🔴 vue-sfc/sfc-script-setup** — SFC should use `<script setup lang="ts">`
- Evidence: L1 `export default defineComponent({ ... })`
- Fix: Rewrite with `<script setup lang="ts">`; move `props`/`data`/`methods` to Composition API.
- Source: [antfu/skills → vue-best-practices/references/sfc.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/sfc.md) (also: local skill `vue-best-practices`)

**🟡 vue-sfc/style-scoped** — `<style>` block is missing `scoped`
- Evidence: L45 `<style lang="scss">`
- Fix: Add `scoped` unless this is a global stylesheet.
- Source: [antfu/skills → vue-best-practices/references/sfc.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/sfc.md)

### `tsconfig.json`

**🔴 project-setup/tsconfig-strict** — `compilerOptions.strict` is not `true`
- Evidence: `"strict": false`
- Fix: Set `"strict": true`. Enables all strict type-checking options.
- Source: [antfu/skills → antfu/SKILL.md](https://github.com/antfu/skills/blob/main/skills/antfu/SKILL.md) (also: local skill `antfu`)

## Clean files

- `src/composables/useCounter.ts` — 7 rules checked, no violations
- `package.json` — 5 rules checked, no violations

## Skipped

- `src/assets/logo.svg` (binary)
- Rule `pnpm-monorepo/catalog-usage` (no `pnpm-workspace.yaml` present)
````

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
