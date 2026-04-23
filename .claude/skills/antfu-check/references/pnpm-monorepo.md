# pnpm & monorepo rules

Rules covering package manager choice, workspace configuration, and monorepo hygiene.

Source: [antfu/skills — pnpm](https://github.com/antfu/skills/tree/main/skills/pnpm), [antfu/skills — antfu/references/monorepo.md](https://github.com/antfu/skills/blob/main/skills/antfu/references/monorepo.md). Local skills: `pnpm`, `antfu`.

---

## `pnpm-monorepo/use-pnpm`

- **Severity**: 🔴 Error
- **Applies to**: repo root
- **Detection**: `package-lock.json` or `yarn.lock` exists anywhere in the repo (other than inside `node_modules`), whether or not `pnpm-lock.yaml` is also present.
- **Fix**: Delete the non-pnpm lockfile. Add `packageManager` field to `package.json`:
  ```json
  { "packageManager": "pnpm@<version>" }
  ```
- **Source**: [antfu/skills → pnpm/SKILL.md](https://github.com/antfu/skills/blob/main/skills/pnpm/SKILL.md)

---

## `pnpm-monorepo/package-manager-pinned`

- **Severity**: 🟡 Warning
- **Applies to**: root `package.json`
- **Detection**: `packageManager` field missing, or doesn't pin a specific pnpm version (e.g., `"pnpm@9.15.0"`).
- **Fix**: Set `packageManager` to the pnpm version the project was verified with.
- **Source**: [antfu/skills → pnpm/SKILL.md](https://github.com/antfu/skills/blob/main/skills/pnpm/SKILL.md)

---

## `pnpm-monorepo/workspace-catalog`

- **Severity**: 🟡 Warning
- **Applies to**: `pnpm-workspace.yaml` in monorepos
- **Detection**: File exists but has no `catalogs:` / `catalog:` key. Rule passes for single-package repos (no `pnpm-workspace.yaml`).
- **Fix**: Define named catalogs for common dependency groups (`prod`, `dev`, `frontend`, `inlined`). Reference them in package `package.json` as `"vue": "catalog:frontend"`.
  ```yaml
  # pnpm-workspace.yaml
  packages:
    - packages/*
  catalogs:
    frontend:
      vue: ^3.5.0
      "@vue/compiler-sfc": ^3.5.0
    dev:
      typescript: ^5.6.0
      vitest: ^2.1.0
  ```
- **Source**: [antfu/skills → antfu/references/monorepo.md](https://github.com/antfu/skills/blob/main/skills/antfu/references/monorepo.md)

---

## `pnpm-monorepo/root-lint-script`

- **Severity**: 🟡 Warning
- **Applies to**: root `package.json` in monorepos (or any repo using antfu ESLint)
- **Detection**: `scripts.lint` missing, or doesn't include `eslint . --cache` (with or without `--concurrency=auto`).
- **Fix**:
  ```json
  {
    "scripts": {
      "lint": "eslint . --cache --concurrency=auto",
      "lint:fix": "eslint . --cache --concurrency=auto --fix"
    }
  }
  ```
- **Source**: [antfu/skills → antfu/references/monorepo.md](https://github.com/antfu/skills/blob/main/skills/antfu/references/monorepo.md)

---

## `pnpm-monorepo/recursive-build`

- **Severity**: 🔵 Info
- **Applies to**: root `package.json` in monorepos
- **Detection**: Missing `"build": "pnpm run -r build"` (or equivalent recursive script) while `packages/*` contains buildable packages.
- **Fix**: Add `"build": "pnpm run -r build"` so root build fans out across workspace packages.
- **Source**: [antfu/skills → antfu/references/monorepo.md](https://github.com/antfu/skills/blob/main/skills/antfu/references/monorepo.md)
