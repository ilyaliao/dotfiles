# Vue SFC rules

Rules covering `<script>`, `<template>`, and `<style>` blocks inside `.vue` files.

Source: [antfu/skills — vue-best-practices](https://github.com/antfu/skills/tree/main/skills/vue-best-practices). Local skills: `vue-best-practices`, `vue`.

---

## `vue-sfc/script-setup`

- **Severity**: 🔴 Error
- **Applies to**: `**/*.vue`
- **Detection**: File contains `<script>` but not `<script setup>`. Also flag when `export default defineComponent({ ... })` or `export default { ... }` (Options API) is present.
- **Fix**: Rewrite as `<script setup lang="ts">`. Move `props` → `defineProps<T>()`, `emits` → `defineEmits<T>()`, `data()`/`computed`/`methods` → Composition API equivalents.
- **Source**: [antfu/skills → vue-best-practices/references/sfc.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/sfc.md)

---

## `vue-sfc/script-lang-ts`

- **Severity**: 🟡 Warning
- **Applies to**: `**/*.vue` in TypeScript projects (`tsconfig.json` present)
- **Detection**: `<script setup>` without `lang="ts"`.
- **Fix**: Add `lang="ts"`. Enables `defineProps<T>()`/`defineEmits<T>()` generics.
- **Source**: [antfu/skills → vue-best-practices/references/sfc.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/sfc.md)

---

## `vue-sfc/block-order`

- **Severity**: 🔵 Info
- **Applies to**: `**/*.vue`
- **Detection**: Block order is not `<script>` → `<template>` → `<style>`.
- **Fix**: Reorder blocks. `@antfu/eslint-config` enforces this via `vue/block-order` rule and can auto-fix.
- **Source**: [antfu/skills → vue-best-practices/references/sfc.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/sfc.md)

---

## `vue-sfc/style-scoped`

- **Severity**: 🟡 Warning
- **Applies to**: `**/*.vue`
- **Detection**: `<style>` block without `scoped` attribute. Skip if filename suggests global styles (e.g., `app.vue`, `layouts/*.vue` when styles are intentionally global — judgment call; only flag component SFCs).
- **Fix**: Add `scoped`: `<style scoped>`. Use `:deep()` selector if you need to style children.
- **Source**: [antfu/skills → vue-best-practices/references/sfc.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/sfc.md)

---

## `vue-sfc/scoped-class-selectors`

- **Severity**: 🔵 Info
- **Applies to**: `<style scoped>` blocks in `**/*.vue`
- **Detection**: Scoped style targets bare element selectors (`div { ... }`, `button { ... }`) rather than class selectors.
- **Fix**: Use class selectors (`.my-button { ... }`). Reduces accidental descendant styling.
- **Source**: [antfu/skills → vue-best-practices/references/sfc.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/sfc.md)

---

## `vue-sfc/filename-pascalcase`

- **Severity**: 🟡 Warning
- **Applies to**: `**/*.vue` (excluding special files: `index.vue`, `[*].vue` route files, `default.vue` / `error.vue` layout names)
- **Detection**: Filename is not PascalCase (e.g., `user-card.vue`, `userCard.vue`, `user_card.vue`).
- **Fix**: Rename to PascalCase: `UserCard.vue`. Update imports accordingly.
- **Source**: [antfu/skills → vue-best-practices/references/sfc.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/sfc.md)

---

## `vue-sfc/no-v-if-v-for`

- **Severity**: 🔴 Error
- **Applies to**: `**/*.vue`
- **Detection**: Same element carries both `v-if` and `v-for` directives. Grep pattern: element with both `v-if="..."` and `v-for="..."` attributes.
- **Fix**: Move the filter into a `computed`:

  ```vue
  <!-- bad -->
  <li v-for="u in users" v-if="u.active">{{ u.name }}</li>

  <!-- good -->
  <li v-for="u in activeUsers" :key="u.id">{{ u.name }}</li>

  <script setup lang="ts">
  const activeUsers = computed(() => users.value.filter((u) => u.active));
  </script>
  ```

- **Source**: [antfu/skills → vue-best-practices/references/sfc.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/sfc.md)

---

## `vue-sfc/v-for-key`

- **Severity**: 🔴 Error
- **Applies to**: `**/*.vue`
- **Detection**: Element with `v-for` lacks `:key` binding.
- **Fix**: Add `:key="item.id"` (prefer primitive stable IDs over array index).
- **Source**: [antfu/skills → vue-best-practices/references/sfc.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/sfc.md)

---

## `vue-sfc/v-html-safety`

- **Severity**: 🟡 Warning
- **Applies to**: `**/*.vue`
- **Detection**: `v-html="<expression>"` where expression refers to props, route params, or user input without visible sanitization (e.g., `DOMPurify.sanitize(...)`, `sanitizeHtml(...)`).
- **Fix**: Either eliminate `v-html` (use text interpolation) or wrap the source with a sanitizer. If the source is statically trusted, leave a `// safe: <reason>` comment so the reviewer can confirm.
- **Source**: [antfu/skills → vue-best-practices/references/sfc.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/sfc.md)

---

## `vue-sfc/style-binding-camelcase`

- **Severity**: 🔵 Info
- **Applies to**: `**/*.vue`
- **Detection**: `:style="{ 'font-size': ... }"` with kebab-case keys instead of camelCase.
- **Fix**: Use camelCase: `:style="{ fontSize: ... }"`.
- **Source**: [antfu/skills → vue-best-practices/references/sfc.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/sfc.md)

---

## `vue-sfc/use-template-ref`

- **Severity**: 🔵 Info
- **Applies to**: `**/*.vue` in projects on Vue 3.5+
- **Detection**: Template ref pattern using `const foo = ref(null)` paired with `ref="foo"` in template (Vue 3.5 introduced `useTemplateRef`).
- **Fix**:

  ```ts
  // before
  const input = ref<HTMLInputElement | null>(null);
  // <input ref="input">

  // after
  const input = useTemplateRef<HTMLInputElement>("input");
  // <input ref="input">
  ```

- **Source**: [antfu/skills → vue-best-practices/references/sfc.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/sfc.md)
