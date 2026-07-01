# UI Wiki Quick Wins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the top five UI/UX wiki findings from the ParseKit interface review — copyability, progress bar physics, typography polish, settings prefetch, and slider hit targets.

**Architecture:** CSS-only fixes live in `src/index.css` with existing design tokens. Deps prefetch uses a tiny session cache module consumed by `DependencyPreflight.svelte` so hover on the settings gear hides Settings mount latency. No new dependencies.

**Tech Stack:** Svelte 5, TypeScript, Vitest, Tauri invoke API, existing CSS custom properties (`--timing-fast`, `--accent-color`, `--focus-ring`).

## Global Constraints

- Do not change app version or release artifacts.
- Preserve `prefers-reduced-motion` behavior everywhere it already exists.
- Match existing naming: CSS classes, i18n keys unchanged unless required.
- Run `npm test` before each commit; all tests must pass with pristine output.
- One commit per task with conventional message: `fix(ui): <short description>`.
- Do not commit unrelated dirty files (`src-tauri/Cargo.lock`, `src-tauri/icons/icon.icns`).
- Minimum interactive target: 32px where wiki flagged undersized controls.
- Progress bar fill transitions use **linear** easing only.
- Selection styling uses `color-mix(in srgb, var(--accent-color) 35%, transparent)` for background.

---

### Task 1: Scoped text selection (copyability)

**Files:**
- Modify: `src/index.css` (body rule ~195, add new rules after body block)
- Test: `src/lib/copyability.test.ts` (create)

**Interfaces:**
- Produces: CSS classes `.selectable-content` and global `::selection` (Task 2 adds `::selection`; Task 1 only does user-select scoping)

- [ ] **Step 1: Write the failing test**

Create `src/lib/copyability.test.ts`:

```typescript
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

describe("copyability CSS", () => {
  const css = readFileSync(resolve("src/index.css"), "utf8");

  it("does not set user-select none on body", () => {
    expect(css).not.toMatch(/body\s*\{[^}]*user-select:\s*none/s);
  });

  it("defines selectable-content helper", () => {
    expect(css).toContain(".selectable-content");
    expect(css).toMatch(/\.selectable-content\s*\{[^}]*user-select:\s*text/s);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- src/lib/copyability.test.ts`
Expected: FAIL — body still has `user-select: none`

- [ ] **Step 3: Implement**

In `src/index.css`:
1. Remove `user-select: none` from the `body` rule.
2. Add after `body { ... }`:

```css
.shell,
header,
.section-title,
.config-summary-chip,
.file-status-badge .status-label,
.parse-spinner {
  user-select: none;
}

.selectable-content,
.settings-scroll,
.about-scroll,
.error-banner,
.notice-banner,
.deps-brew-hint,
.deps-error,
.file-error,
.gatekeeper-actions code,
.settings-hint--multiline {
  user-select: text;
}
```

3. Add class `selectable-content` to scroll regions in:
   - `src/components/SettingsScreen.svelte` — on `.settings-scroll` div (add class alongside existing)
   - `src/components/AboutScreen.svelte` — on `.settings-scroll.about-scroll` div

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test -- src/lib/copyability.test.ts`
Expected: PASS

- [ ] **Step 5: Run full suite and commit**

Run: `npm test`
```bash
git add src/index.css src/lib/copyability.test.ts src/components/SettingsScreen.svelte src/components/AboutScreen.svelte
git commit -m "fix(ui): allow text selection in settings and error content"
```

---

### Task 2: Progress bar linear easing and typography polish

**Files:**
- Modify: `src/index.css` (~536-542, ~1962-1970, ~2103-2110, add `::selection` after body/font rules ~199)
- Test: `src/lib/uiTokens.test.ts` (create)

**Interfaces:**
- Consumes: `.selectable-content` from Task 1 (no code dependency)

- [ ] **Step 1: Write the failing test**

Create `src/lib/uiTokens.test.ts`:

```typescript
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

describe("UI token CSS", () => {
  const css = readFileSync(resolve("src/index.css"), "utf8");

  it("uses linear easing on progress fill", () => {
    expect(css).toMatch(/\.progress-fill\s*\{[^}]*transition:[^}]*linear/s);
  });

  it("styles ::selection", () => {
    expect(css).toContain("::selection");
    expect(css).toMatch(/::selection\s*\{[^}]*background:/s);
  });

  it("offsets settings repo link underline", () => {
    expect(css).toMatch(/\.settings-repo-link[^{]*\{[^}]*text-underline-offset:\s*2px/s);
  });

  it("balances about section headings", () => {
    expect(css).toMatch(/\.about-section-title\s*\{[^}]*text-wrap:\s*balance/s);
    expect(css).toMatch(/\.about-hero\s*\{[^}]*text-wrap:\s*balance/s);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm test -- src/lib/uiTokens.test.ts`
Expected: FAIL

- [ ] **Step 3: Implement**

1. Change `.progress-fill` transition to:
```css
transition: transform var(--timing-fast) linear;
```

2. Add after `body` block (or near typography rules):
```css
::selection {
  background: color-mix(in srgb, var(--accent-color) 35%, transparent);
  color: var(--text-primary);
}
```

3. Update `.settings-repo-link`:
```css
.settings-repo-link {
  /* existing props */
  text-underline-offset: 2px;
}
.settings-repo-link:hover {
  text-decoration: underline;
}
```

4. Add to `.about-section-title` and `.about-hero`:
```css
text-wrap: balance;
```

5. Align `.about-section-title` uppercase tracking with `.section-title`:
```css
letter-spacing: 0.08em;
```

- [ ] **Step 4: Run tests**

Run: `npm test`
Expected: all PASS including new uiTokens tests

- [ ] **Step 5: Commit**

```bash
git add src/index.css src/lib/uiTokens.test.ts
git commit -m "fix(ui): linear progress bar and typography polish"
```

---

### Task 3: Prefetch dependencies on settings gear hover

**Files:**
- Create: `src/lib/depsCache.ts`
- Create: `src/lib/depsCache.test.ts`
- Modify: `src/App.svelte` (settings button ~816-836, openSettings ~184)
- Modify: `src/components/DependencyPreflight.svelte` (onMount refresh ~47-74)

**Interfaces:**
- Produces:
  - `export interface DepStatus { id, labelKey, installed, optional, brewHint }` (mirror invoke shape)
  - `export function warmDependencies(): void` — fire-and-forget, once per session
  - `export function peekCachedDependencies(): DepStatus[] | null`
  - `export function takeCachedDependencies(): DepStatus[] | null` — returns and clears cache
  - `export function resetDepsCacheForTests(): void`

- [ ] **Step 1: Write failing tests**

Create `src/lib/depsCache.ts` with stubs and `src/lib/depsCache.test.ts`:

```typescript
import { afterEach, describe, expect, it, vi } from "vitest";
import {
  peekCachedDependencies,
  resetDepsCacheForTests,
  setCachedDependenciesForTests,
  takeCachedDependencies,
} from "./depsCache";

describe("depsCache", () => {
  afterEach(() => resetDepsCacheForTests());

  it("peek returns null when empty", () => {
    expect(peekCachedDependencies()).toBeNull();
  });

  it("take returns cached deps and clears", () => {
    const deps = [{ id: "tesseract", labelKey: "x", installed: true, optional: false, brewHint: "" }];
    setCachedDependenciesForTests(deps);
    expect(takeCachedDependencies()).toEqual(deps);
    expect(peekCachedDependencies()).toBeNull();
  });
});
```

- [ ] **Step 2: Run test — expect FAIL** (module incomplete)

Run: `npm test -- src/lib/depsCache.test.ts`

- [ ] **Step 3: Implement depsCache.ts**

```typescript
import { invoke } from "@tauri-apps/api/core";

export interface DepStatus {
  id: string;
  labelKey: string;
  installed: boolean;
  optional: boolean;
  brewHint: string;
}

let cached: DepStatus[] | null = null;
let warmStarted = false;

export function peekCachedDependencies(): DepStatus[] | null {
  return cached;
}

export function takeCachedDependencies(): DepStatus[] | null {
  const value = cached;
  cached = null;
  return value;
}

export function warmDependencies(): void {
  if (warmStarted) return;
  warmStarted = true;
  void invoke<DepStatus[]>("check_dependencies")
    .then((result) => {
      cached = result;
    })
    .catch(() => {
      warmStarted = false;
    });
}

export function resetDepsCacheForTests(): void {
  cached = null;
  warmStarted = false;
}

export function setCachedDependenciesForTests(value: DepStatus[]): void {
  cached = value;
}
```

- [ ] **Step 4: Wire App.svelte**

Import `warmDependencies` from `./lib/depsCache`.

On settings button add:
```svelte
onmouseenter={warmDependencies}
onfocusin={warmDependencies}
```

- [ ] **Step 5: Wire DependencyPreflight.svelte**

Import `takeCachedDependencies` and `DepStatus` from `../lib/depsCache`.

At start of `refresh()`, before loading:
```typescript
const cached = takeCachedDependencies();
if (cached) {
  deps = cached;
  loading = false;
  listVisible = true;
  return;
}
```

Keep existing invoke path for recheck and when cache empty.

- [ ] **Step 6: Run full suite and commit**

Run: `npm test`
```bash
git add src/lib/depsCache.ts src/lib/depsCache.test.ts src/App.svelte src/components/DependencyPreflight.svelte
git commit -m "fix(ui): prefetch dependencies on settings hover"
```

---

### Task 4: Workers slider hit target expansion

**Files:**
- Modify: `src/index.css` (~680-760 workers-slider rules)
- Test: extend `src/lib/uiTokens.test.ts`

**Interfaces:**
- Consumes: none

- [ ] **Step 1: Write failing test**

Add to `src/lib/uiTokens.test.ts`:

```typescript
  it("expands workers slider hit area", () => {
    expect(css).toMatch(/\.workers-slider-track-wrap\s*\{[^}]*min-height:\s*44px/s);
    expect(css).toMatch(/\.workers-slider-input::-webkit-slider-thumb\s*\{[^}]*width:\s*22px/s);
  });
```

- [ ] **Step 2: Run test — expect FAIL**

Run: `npm test -- src/lib/uiTokens.test.ts`

- [ ] **Step 3: Implement**

```css
.workers-slider-track-wrap {
  /* existing */
  min-height: 44px;
  display: flex;
  align-items: center;
}

.workers-slider-input::-webkit-slider-thumb {
  width: 22px;
  height: 22px;
  /* keep existing border-radius, background, box-shadow */
}

.workers-slider-input::-moz-range-thumb {
  width: 22px;
  height: 22px;
}
```

- [ ] **Step 4: Run full suite and commit**

Run: `npm test`
```bash
git add src/index.css src/lib/uiTokens.test.ts
git commit -m "fix(ui): enlarge workers slider hit target"
```

---

## Verification (after all tasks)

Run: `npm test && npm run check`
Manual: open app, verify text selectable in About/settings, progress bar animates linearly, settings opens faster on second visit after hover prefetch.