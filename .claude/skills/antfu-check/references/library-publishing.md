# Library publishing rules

Rules covering TypeScript library packaging, bundler choice, and `package.json` export surface.

Source: [antfu/skills — tsdown](https://github.com/antfu/skills/tree/main/skills/tsdown), [antfu/skills — antfu/references/library-development.md](https://github.com/antfu/skills/blob/main/skills/antfu/references/library-development.md). Local skills: `tsdown`, `antfu`.

These rules apply only when the audited package is a **library** (detected by `package.json` having `exports` + `files`, or by `tsdown`/`tsup` in build scripts).

---

## `library-publishing/type-module`

- **Severity**: 🔴 Error
- **Applies to**: library `package.json`
- **Detection**: `"type"` is not `"module"`, or field is missing.
- **Fix**: Set `"type": "module"`. Modern antfu libraries ship ESM-first.
- **Source**: [antfu/skills → antfu/references/library-development.md](https://github.com/antfu/skills/blob/main/skills/antfu/references/library-development.md)

---

## `library-publishing/use-tsdown`

- **Severity**: 🟡 Warning
- **Applies to**: library `package.json`
- **Detection**: `scripts.build` uses `tsup`, `rollup`, `unbuild`, or `tsc` directly (not `tsdown`). `tsdown.config.*` does not exist.
- **Fix**: Migrate to tsdown. Use the `tsdown-migrate` local skill for `tsup → tsdown` conversions.
  ```ts
  // tsdown.config.ts
  import { defineConfig } from 'tsdown'
  export default defineConfig({
    entry: ['src/index.ts'],
    format: ['esm'],
    dts: true,
    exports: true,
  })
  ```
- **Source**: [antfu/skills → tsdown/SKILL.md](https://github.com/antfu/skills/blob/main/skills/tsdown/SKILL.md)

---

## `library-publishing/tsdown-config`

- **Severity**: 🟡 Warning
- **Applies to**: `tsdown.config.{ts,js,mjs}`
- **Detection**: Missing any of these options:
  - `format: ['esm']` (or at least includes `'esm'`)
  - `dts: true`
  - `exports: true`
- **Fix**: Add the missing options. `exports: true` auto-writes `package.json` exports field on build.
- **Source**: [antfu/skills → tsdown/SKILL.md](https://github.com/antfu/skills/blob/main/skills/tsdown/SKILL.md)

---

## `library-publishing/prepack-script`

- **Severity**: 🔴 Error
- **Applies to**: library `package.json`
- **Detection**: `scripts.prepack` missing or doesn't invoke the project's build command (e.g., `"prepack": "pnpm build"`).
- **Fix**: Add `"prepack": "pnpm build"`. Ensures published tarball contains freshly built output.
- **Source**: [antfu/skills → antfu/references/library-development.md](https://github.com/antfu/skills/blob/main/skills/antfu/references/library-development.md)

---

## `library-publishing/files-field`

- **Severity**: 🔴 Error
- **Applies to**: library `package.json`
- **Detection**: `"files"` is missing, or does not include `"dist"` (or whatever the build output dir is).
- **Fix**: Set `"files": ["dist"]`. Prevents publishing source and dev files.
- **Source**: [antfu/skills → antfu/references/library-development.md](https://github.com/antfu/skills/blob/main/skills/antfu/references/library-development.md)

---

## `library-publishing/exports-field`

- **Severity**: 🟡 Warning
- **Applies to**: library `package.json`
- **Detection**: Missing top-level `"exports"` field, or no `import` condition for the main entry.
- **Fix**: Let `tsdown` auto-generate (`exports: true`), or hand-write:
  ```json
  {
    "exports": {
      ".": {
        "types": "./dist/index.d.ts",
        "import": "./dist/index.js"
      }
    }
  }
  ```
- **Source**: [antfu/skills → antfu/references/library-development.md](https://github.com/antfu/skills/blob/main/skills/antfu/references/library-development.md)
