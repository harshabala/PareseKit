# Clean Code Refactoring Plan - ParseKit

This plan aims to refactor `src/App.svelte` to address Single Responsibility Principle (SRP) violations and clean up monolithic state management by extracting cohesive concerns (app updates and Finder Quick Actions) into separate, testable Svelte 5 state classes/utilities.

## Tasks

### [ ] Task 1: Extract App Update Logic
- **Goal**: Move all update checking, downloading, and UI notification states from `src/App.svelte` to a dedicated `src/lib/updateState.svelte.ts` store.
- **Details**:
  - Extract states: `updateAvailable`, `isInstallingUpdate`, `updateError`, `updateCheckBusy`, `updateStatusNote`, `updateStatusOk`.
  - Extract actions: `checkForUpdate`, `installUpdate`, `dismissUpdateBanner`, `scheduleBackgroundUpdateCheck`.
  - Expose a clean reactive class/state object.
  - Update `src/App.svelte` and `src/components/SettingsScreen.svelte` to use `updateState`.

### [ ] Task 2: Extract Finder Quick Action Logic
- **Goal**: Move all Finder Quick Action state and ipc-invokes from `src/App.svelte` to a dedicated `src/lib/finderActionState.svelte.ts`.
- **Details**:
  - Extract states: `finderActionInstalled`, `finderActionBusy`, `finderActionNotice`.
  - Extract actions: `refreshFinderActionStatus`, `installFinderQuickAction`.
  - Expose a clean reactive class/state object.
  - Update `src/App.svelte` and `src/components/SettingsScreen.svelte` to use `finderActionState`.

### [ ] Task 3: Run Validation & Verification
- **Goal**: Verify the app builds, Svelte components typecheck, and all unit tests pass.
- **Details**:
  - Run `npm run check` (Svelte Check).
  - Run `npm run test` (Vitest unit tests).
