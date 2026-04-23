# Project setup rules

Rules covering repository-level tooling: ESLint, TypeScript, VSCode, Git, CI, and code organization.

Source: [antfu/skills — antfu](https://github.com/antfu/skills/tree/main/skills/antfu). Local skill: `antfu`.

---

## `project-setup/eslint-antfu-config`

- **Severity**: 🔴 Error
- **Applies to**: `eslint.config.{js,mjs,ts,cjs}` at repo root
- **Detection**:
  - File exists, AND
  - Imports `@antfu/eslint-config` (Grep for `from ['"]@antfu/eslint-config['"]`)
  - Calls `antfu(...)` as default export or inside it
- **Fix**:
  ```ts
  // eslint.config.mjs
  import antfu from "@antfu/eslint-config";
  export default antfu();
  ```
  Add `@antfu/eslint-config` to `devDependencies`.
- **Source**: [antfu/skills → antfu/references/antfu-eslint-config.md](https://github.com/antfu/skills/blob/main/skills/antfu/references/antfu-eslint-config.md)

---

## `project-setup/no-prettier`

- **Severity**: 🔴 Error
- **Applies to**: repo root
- **Detection**: any of these is a violation
  - `.prettierrc`, `.prettierrc.{js,cjs,mjs,json,yml,yaml,toml}`, `prettier.config.{js,cjs,mjs}` exists
  - `package.json` contains a top-level `"prettier"` key
  - `devDependencies` contains `prettier`
- **Fix**: Remove the config file(s) and the `prettier` dependency. `@antfu/eslint-config` handles formatting via ESLint rules.
- **Source**: [antfu/skills → antfu/references/antfu-eslint-config.md](https://github.com/antfu/skills/blob/main/skills/antfu/references/antfu-eslint-config.md)

---

## `project-setup/tsconfig-strict`

- **Severity**: 🔴 Error
- **Applies to**: `tsconfig.json`
- **Detection**: Read `compilerOptions`. Flag if any of these is missing or wrong:
  - `"strict": true`
  - `"module": "ESNext"` (or the newer ESM-aware value the project targets)
  - `"moduleResolution": "bundler"` for app/library projects
  - `"isolatedModules": true`
  - `"esModuleInterop": true`
  - `"skipLibCheck": true`
  - `"resolveJsonModule": true`
- **Fix**: Merge the missing options into `compilerOptions`. See the canonical config below.
- **Reference config**:
  ```json
  {
    "compilerOptions": {
      "target": "ESNext",
      "module": "ESNext",
      "moduleResolution": "bundler",
      "strict": true,
      "esModuleInterop": true,
      "skipLibCheck": true,
      "resolveJsonModule": true,
      "isolatedModules": true,
      "noEmit": true
    }
  }
  ```
- **Source**: [antfu/skills → antfu/SKILL.md](https://github.com/antfu/skills/blob/main/skills/antfu/SKILL.md) (TypeScript Config section)

---

## `project-setup/vscode-eslint-formatter`

- **Severity**: 🟡 Warning
- **Applies to**: `.vscode/settings.json`
- **Detection**: Read the JSON. Flag if any of these is missing:
  - `"prettier.enable": false`
  - `"editor.formatOnSave": false`
  - `"editor.codeActionsOnSave"` contains `"source.fixAll.eslint": "explicit"`
- **Fix**: Merge missing keys.
- **Reference**:
  ```json
  {
    "prettier.enable": false,
    "editor.formatOnSave": false,
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": "explicit",
      "source.organizeImports": "never"
    }
  }
  ```
- **Source**: [antfu/skills → antfu/references/antfu-eslint-config.md](https://github.com/antfu/skills/blob/main/skills/antfu/references/antfu-eslint-config.md)

---

## `project-setup/vscode-extensions-recommended`

- **Severity**: 🔵 Info
- **Applies to**: `.vscode/extensions.json`
- **Detection**: File exists and its `recommendations` array does NOT include `dbaeumer.vscode-eslint`. If the file does not exist at all, skip this rule (don't demand its creation) — report it in the **Skipped** section.
- **Fix**: Add `dbaeumer.vscode-eslint` to `recommendations`:
  ```json
  { "recommendations": ["dbaeumer.vscode-eslint"] }
  ```
- **Source**: [antfu/skills → antfu/references/antfu-eslint-config.md](https://github.com/antfu/skills/blob/main/skills/antfu/references/antfu-eslint-config.md)

---

## `project-setup/git-hooks`

- **Severity**: 🟡 Warning
- **Applies to**: root `package.json`
- **Detection**: Missing any of:
  - `devDependencies` includes `simple-git-hooks` and `lint-staged`
  - Top-level `"simple-git-hooks"` block with a `pre-commit` hook
  - Top-level `"lint-staged"` block that runs `eslint --fix` on a glob (typically `"*": "eslint --fix"`)
- **Fix**:
  ```json
  {
    "simple-git-hooks": {
      "pre-commit": "pnpm i --frozen-lockfile --ignore-scripts --offline && npx lint-staged"
    },
    "lint-staged": { "*": "eslint --fix" }
  }
  ```
  Run `npx simple-git-hooks` once after install to register the hook.
- **Source**: [antfu/skills → antfu/SKILL.md](https://github.com/antfu/skills/blob/main/skills/antfu/SKILL.md) (Git Hooks section)

---

## `project-setup/gitignore-basics`

- **Severity**: 🟡 Warning
- **Applies to**: `.gitignore` at repo root
- **Detection**: Missing any of: `node_modules`, `dist`, `.eslintcache`, `.env`, `.DS_Store`, `coverage`.
- **Fix**: Append missing entries.
- **Source**: [antfu/skills → antfu/references/setting-up.md](https://github.com/antfu/skills/blob/main/skills/antfu/references/setting-up.md)

---

## `project-setup/github-workflows`

- **Severity**: 🔵 Info
- **Applies to**: `.github/workflows/`
- **Detection**: Missing `autofix.yml` and/or `unit-test.yml`. Either is acceptable on its own, but new antfu projects usually have both.
- **Fix**: Follow the patterns in [sxzz/workflows](https://github.com/sxzz/workflows).
- **Source**: [antfu/skills → antfu/references/setting-up.md](https://github.com/antfu/skills/blob/main/skills/antfu/references/setting-up.md)

---

## `project-setup/types-separated`

- **Severity**: 🔵 Info
- **Applies to**: `src/**/*.ts` (especially `src/index.ts` and large modules)
- **Detection**: File declares many `type`/`interface` alongside runtime code, and no sibling `types.ts` / `types/*.ts` exists.
  - Heuristic: same file contains >3 top-level `export (type|interface)` declarations AND non-type exports. If a dedicated `types.ts` exists nearby, this rule passes.
- **Fix**: Move type/interface declarations to `types.ts` (or `types/` directory). Re-export from `index.ts` if needed.
- **Source**: [antfu/skills → antfu/SKILL.md](https://github.com/antfu/skills/blob/main/skills/antfu/SKILL.md) (Code Organization)

---

## `project-setup/env-comment`

- **Severity**: 🔵 Info
- **Applies to**: `src/**/*.ts` where the module is environment-specific (uses `node:*` imports, or browser-only APIs like `document`/`window`)
- **Detection**:
  - File imports from `node:*` or uses `process.*`/`fs.*` at top level, AND
  - First non-empty line is NOT `// @env node`
  - Mirror the check for browser files (`document`/`window` without corresponding `// @env browser`)
- **Fix**: Add a single-line comment at the top: `// @env node` or `// @env browser`.
- **Source**: [antfu/skills → antfu/SKILL.md](https://github.com/antfu/skills/blob/main/skills/antfu/SKILL.md) (Runtime Environment)

---

## `project-setup/test-colocated`

- **Severity**: 🔵 Info
- **Applies to**: `**/*.test.{ts,tsx}`, `**/*.spec.{ts,tsx}`
- **Detection**: Test file lives in a top-level `tests/` or `__tests__/` directory separate from its source. antfu convention is `foo.ts` + `foo.test.ts` in the same directory.
- **Fix**: Move the test next to the source file it covers.
- **Source**: [antfu/skills → antfu/SKILL.md](https://github.com/antfu/skills/blob/main/skills/antfu/SKILL.md) (Testing section)
