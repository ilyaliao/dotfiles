# Vue testing rules

Rules covering Vitest + Vue Test Utils conventions.

Source: [antfu/skills — vue-testing-best-practices](https://github.com/antfu/skills/tree/main/skills/vue-testing-best-practices), [antfu/skills — vitest](https://github.com/antfu/skills/tree/main/skills/vitest). Local skills: `vue-testing-best-practices`, `vitest`.

These rules apply only when `vitest` is a dependency.

---

## `vue-testing/use-vitest-not-jest`

- **Severity**: 🔴 Error
- **Applies to**: repo root
- **Detection**: Test files import from `@jest/globals` or `jest.config.*` exists. `jest` is in `devDependencies`.
- **Fix**: Migrate to Vitest. Vitest is Jest-API-compatible in most places.
- **Source**: [antfu/skills → vitest/SKILL.md](https://github.com/antfu/skills/blob/main/skills/vitest/SKILL.md)

---

## `vue-testing/describe-it-api`

- **Severity**: 🔵 Info
- **Applies to**: `**/*.{test,spec}.{ts,tsx,js}`
- **Detection**: Test file uses `test(...)` top-level instead of `describe` + `it`.
- **Fix**: Wrap in `describe('<subject>', () => { it('<behavior>', () => { ... }) })`.
- **Source**: [antfu/skills → antfu/SKILL.md](https://github.com/antfu/skills/blob/main/skills/antfu/SKILL.md) (Testing section)

---

## `vue-testing/pinia-setup`

- **Severity**: 🟡 Warning
- **Applies to**: `**/*.{test,spec}.{ts,tsx}` that import Pinia stores
- **Detection**: Test calls `useSomeStore()` without installing a Pinia instance first (missing `createTestingPinia()` or `setActivePinia(createPinia())`).
- **Fix**:

  ```ts
  import { createTestingPinia } from "@pinia/testing";
  import { mount } from "@vue/test-utils";

  const wrapper = mount(MyComponent, {
    global: { plugins: [createTestingPinia()] },
  });
  ```

- **Source**: [antfu/skills → vue-testing-best-practices/SKILL.md](https://github.com/antfu/skills/blob/main/skills/vue-testing-best-practices/SKILL.md)

---

## `vue-testing/await-flush-promises`

- **Severity**: 🟡 Warning
- **Applies to**: `**/*.{test,spec}.{ts,tsx}`
- **Detection**: Async behavior tests (e.g., after `await wrapper.find('button').trigger('click')` that triggers an async handler) assert state without `await flushPromises()`, or mix `nextTick()` chains inconsistently.
- **Fix**: Use `await flushPromises()` from `@vue/test-utils` after triggering async actions.
- **Source**: [antfu/skills → vue-testing-best-practices/SKILL.md](https://github.com/antfu/skills/blob/main/skills/vue-testing-best-practices/SKILL.md)

---

## `vue-testing/behavior-over-snapshot`

- **Severity**: 🔵 Info
- **Applies to**: `**/*.{test,spec}.{ts,tsx}`
- **Detection**: Test body contains only `expect(wrapper.html()).toMatchSnapshot()` (or equivalent) without any behavioral assertion like `expect(wrapper.text()).toContain(...)` or `expect(emitted).toHaveBeenCalled()`.
- **Fix**: Add at least one behavioral assertion per test. Snapshots are a safety net, not a substitute for testing behavior.
- **Source**: [antfu/skills → vue-testing-best-practices/SKILL.md](https://github.com/antfu/skills/blob/main/skills/vue-testing-best-practices/SKILL.md)
