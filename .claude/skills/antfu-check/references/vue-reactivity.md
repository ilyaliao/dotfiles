# Vue reactivity & data flow rules

Rules covering `ref`/`reactive`/`computed`/`watch` usage, props/emits, and composables.

Source: [antfu/skills — vue-best-practices/references/reactivity.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/reactivity.md), [component-data-flow.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/component-data-flow.md), [composables.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/composables.md). Local skills: `vue-best-practices`, `vue`.

---

## `vue-reactivity/prefer-shallowref`

- **Severity**: 🟡 Warning
- **Applies to**: `**/*.vue`, `src/composables/**/*.ts`, `src/stores/**/*.ts`
- **Detection**: `ref(<primitive>)` or `ref(<immutable object>)` — the contained value is never mutated through nested paths; it's replaced wholesale.
  - Signals: surrounded code reads `foo.value = …` but never `foo.value.x = …`.
- **Fix**: Use `shallowRef` for primitives and objects whose internals you don't mutate. Skips deep reactivity overhead.
- **Source**: [antfu/skills → vue-best-practices/references/reactivity.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/reactivity.md)

---

## `vue-reactivity/no-reactive-destructure`

- **Severity**: 🔴 Error
- **Applies to**: `**/*.vue`, composable/store files
- **Detection**: Pattern like `const { foo, bar } = reactive({ ... })` or `const { x } = someReactiveObject`. Destructuring loses reactivity.
- **Fix**: Keep the reactive object whole, or use `toRefs(...)`:
  ```ts
  const state = reactive({ foo: 1, bar: 2 });
  const { foo, bar } = toRefs(state); // each is a Ref
  ```
- **Source**: [antfu/skills → vue-best-practices/references/reactivity.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/reactivity.md)

---

## `vue-reactivity/watch-source-getter`

- **Severity**: 🔴 Error
- **Applies to**: `**/*.vue`, composable files
- **Detection**: `watch(reactiveObj.prop, ...)` — passing a property directly from a `reactive()` object. Vue warns, and the watcher won't fire.
- **Fix**: Pass a getter: `watch(() => reactiveObj.prop, ...)`. Or extract via `toRef`: `watch(toRef(reactiveObj, 'prop'), ...)`.
- **Source**: [antfu/skills → vue-best-practices/references/reactivity.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/reactivity.md)

---

## `vue-reactivity/prefer-computed-over-watch`

- **Severity**: 🟡 Warning
- **Applies to**: `**/*.vue`, composable files
- **Detection**: `watch(source, (v) => { otherRef.value = derive(v) })` — using `watch` to produce a derived value.
- **Fix**: Replace with `computed`:

  ```ts
  // before
  const doubled = ref(0);
  watch(count, (v) => {
    doubled.value = v * 2;
  });

  // after
  const doubled = computed(() => count.value * 2);
  ```

- **Source**: [antfu/skills → vue-best-practices/references/reactivity.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/reactivity.md)

---

## `vue-reactivity/no-inline-template-computation`

- **Severity**: 🔵 Info
- **Applies to**: `**/*.vue` template blocks
- **Detection**: Template expression chains `.filter`, `.map`, `.sort`, `.reduce` on reactive arrays, e.g., `{{ items.filter(...).map(...) }}` or `v-for="x in items.filter(...)"`.
- **Fix**: Move to a `computed` in `<script setup>`. Template should reference named computed values.
- **Source**: [antfu/skills → vue-best-practices/references/reactivity.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/reactivity.md)

---

## `vue-reactivity/typed-define-props`

- **Severity**: 🟡 Warning
- **Applies to**: `**/*.vue` in TypeScript projects
- **Detection**: `defineProps({...})` (runtime form) instead of `defineProps<Props>()` (type form). Also flag untyped `defineEmits([...])` in TS projects.
- **Fix**:
  ```ts
  interface Props {
    title: string;
    count?: number;
  }
  const props = defineProps<Props>();
  const emit = defineEmits<{
    change: [value: number];
  }>();
  ```
- **Source**: [antfu/skills → vue-best-practices/references/component-data-flow.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/component-data-flow.md)

---

## `vue-reactivity/no-props-mutation`

- **Severity**: 🔴 Error
- **Applies to**: `**/*.vue`
- **Detection**: Assignment to `props.<anything>` or mutation of props nested properties. Vue warns at runtime; antfu flags it at lint.
- **Fix**: Emit an event and let the parent update. For two-way binding, use `defineModel`.
- **Source**: [antfu/skills → vue-best-practices/references/component-data-flow.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/component-data-flow.md)

---

## `vue-reactivity/prefer-define-model`

- **Severity**: 🟡 Warning
- **Applies to**: `**/*.vue` in projects on Vue 3.4+
- **Detection**: Component declares both a `modelValue` prop and a `'update:modelValue'` emit manually, instead of using `defineModel`.
- **Fix**:

  ```ts
  // before
  const props = defineProps<{ modelValue: string }>();
  const emit = defineEmits<{ "update:modelValue": [value: string] }>();

  // after
  const model = defineModel<string>();
  ```

- **Source**: [antfu/skills → vue-best-practices/references/component-data-flow.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/component-data-flow.md)

---

## `vue-reactivity/inject-symbol-key`

- **Severity**: 🔵 Info
- **Applies to**: `**/*.vue`, composables
- **Detection**: `inject('<string-key>')` or `provide('<string-key>', ...)` using raw strings.
- **Fix**: Use `InjectionKey<T>` / `Symbol` keys exported from a shared module for type safety:
  ```ts
  // keys.ts
  export const countKey: InjectionKey<Ref<number>> = Symbol("count");
  ```
- **Source**: [antfu/skills → vue-best-practices/references/component-data-flow.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/component-data-flow.md)

---

## `vue-reactivity/composable-naming`

- **Severity**: 🔵 Info
- **Applies to**: `src/composables/**/*.ts`
- **Detection**: Exported function doesn't start with `use` prefix.
- **Fix**: Rename to `use<Noun>()` (e.g., `useCounter`, `useUserSession`). Convention for Vue composables.
- **Source**: [antfu/skills → vue-best-practices/references/composables.md](https://github.com/antfu/skills/blob/main/skills/vue-best-practices/references/composables.md)

---

## `vue-reactivity/prefer-vueuse`

- **Severity**: 🔵 Info
- **Applies to**: `**/*.vue`, composable files
- **Detection**: Code hand-rolls common patterns that VueUse already solves (e.g., window event listeners with manual cleanup, localStorage reactive storage, media queries, clipboard). Hard to detect precisely — rely on obvious signals:
  - `onMounted(() => window.addEventListener(...))` + `onUnmounted(() => window.removeEventListener(...))` → `useEventListener`
  - `ref(localStorage.getItem(...))` → `useLocalStorage`
  - `matchMedia(...)` → `useMediaQuery`
- **Fix**: Replace with the matching VueUse composable.
- **Source**: [antfu/skills → vueuse-functions/SKILL.md](https://github.com/antfu/skills/blob/main/skills/vueuse-functions/SKILL.md). Local skill: `vueuse-functions`.
