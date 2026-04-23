# Vue Router rules

Rules covering Vue Router 4 navigation guards, params, and route-component lifecycle.

Source: [antfu/skills — vue-router-best-practices](https://github.com/antfu/skills/tree/main/skills/vue-router-best-practices). Local skill: `vue-router-best-practices`.

These rules apply only when `vue-router` is a dependency.

---

## `vue-router/no-this-in-before-enter`

- **Severity**: 🔴 Error
- **Applies to**: `**/*.vue` (components using in-component guards), `src/router/**/*.ts`
- **Detection**: Inside `beforeRouteEnter(to, from, next)` the code references `this`. At this guard point the component instance does not exist yet.
- **Fix**: Use the callback form `next(vm => vm.doThing())` to access the instance after navigation:
  ```ts
  beforeRouteEnter(to, from, next) {
    next(vm => vm.loadData())
  }
  ```
  Or in `<script setup>`, prefer `onBeforeRouteEnter(to => { /* */ })` from `vue-router`.
- **Source**: [antfu/skills → vue-router-best-practices/SKILL.md](https://github.com/antfu/skills/blob/main/skills/vue-router-best-practices/SKILL.md)

---

## `vue-router/prefer-return-over-next`

- **Severity**: 🟡 Warning
- **Applies to**: `src/router/**/*.ts` global guards, in-component guards
- **Detection**: Guard function signature takes `next` and calls `next(...)` with values (not just `next()` bare). Vue Router 4 prefers returning the target.
- **Fix**: Return the target instead:

  ```ts
  // before
  router.beforeEach((to, from, next) => {
    if (!auth.user) return next({ name: "login" });
    next();
  });

  // after
  router.beforeEach((to) => {
    if (!auth.user) return { name: "login" };
  });
  ```

- **Source**: [antfu/skills → vue-router-best-practices/SKILL.md](https://github.com/antfu/skills/blob/main/skills/vue-router-best-practices/SKILL.md)

---

## `vue-router/watch-param-changes`

- **Severity**: 🟡 Warning
- **Applies to**: `**/*.vue` components consumed by parametric routes
- **Detection**: Component does initial data-fetch based on `route.params.*` in `onMounted` / `<script setup>` top-level, but doesn't re-fetch when params change (no `watch(() => route.params, ...)` or `beforeRouteUpdate`).
- **Fix**: Add a watcher:
  ```ts
  const route = useRoute();
  watch(
    () => route.params.id,
    (id) => fetchUser(id),
    { immediate: true },
  );
  ```
- **Source**: [antfu/skills → vue-router-best-practices/SKILL.md](https://github.com/antfu/skills/blob/main/skills/vue-router-best-practices/SKILL.md)

---

## `vue-router/router-link-over-push`

- **Severity**: 🔵 Info
- **Applies to**: `**/*.vue`
- **Detection**: `<a @click="router.push('/path')">` pattern in templates when a plain `<RouterLink to="/path">` would suffice (no conditional logic around the navigation).
- **Fix**: Use `<RouterLink>` for declarative navigation; reserve `router.push()` for imperative cases (after form submit, guard redirect).
- **Source**: [antfu/skills → vue-router-best-practices/SKILL.md](https://github.com/antfu/skills/blob/main/skills/vue-router-best-practices/SKILL.md)
