<script lang="ts">
  import { onMount } from "svelte";
  import { invoke } from "@tauri-apps/api/core";
  import { downloadDir } from "@tauri-apps/api/path";
  import { getCurrentWindow } from "@tauri-apps/api/window";
  import { getSetting, setSetting } from "./lib/store";
  import { initLocale, normalizeLocale, localeFromLegacyOcr } from "./lib/i18n.svelte";
  import { applyTheme, DEFAULT_THEME, normalizeThemeMode } from "./lib/theme";
  import { pickOutputFolder } from "./lib/picker";
  import OnboardingScreen from "./components/OnboardingScreen.svelte";
  import "./onboarding.css";

  let showInstallHint = $state(false);
  let outputDir = $state("");
  let inputFileCount = $state(0);
  let ready = $state(false);

  const outputDirSet = $derived(!!outputDir);
  const filesReady = $derived(inputFileCount > 0);

  onMount(() => {
    document.body.dataset.window = "onboarding";
    void bootstrap();
    return () => {
      delete document.body.dataset.window;
    };
  });

  async function bootstrap() {
    const theme = normalizeThemeMode(await getSetting("theme", DEFAULT_THEME));
    applyTheme(theme);

    const savedLocale = await getSetting<import("./lib/i18n.svelte").AppLocale | null>("locale", null);
    const resolvedLocale = savedLocale
      ? normalizeLocale(savedLocale)
      : localeFromLegacyOcr(await getSetting("ocrLanguage", "eng"));
    initLocale(resolvedLocale);

    const onboardingDone = await getSetting("hasCompletedOnboarding", false);
    if (onboardingDone) {
      await finishOnboarding();
      return;
    }

    outputDir = await getSetting("outputDir", "");
    if (!outputDir) {
      outputDir = await downloadDir();
      await setSetting("outputDir", outputDir);
    }

    try {
      showInstallHint = !(await invoke<boolean>("is_installed_in_applications"));
    } catch {
      showInstallHint = false;
    }

    ready = true;
    try {
      await getCurrentWindow().setFocus();
    } catch {
      /* ignore */
    }
  }

  async function handlePickOutput() {
    const selected = await pickOutputFolder();
    if (selected) {
      outputDir = selected;
      await setSetting("outputDir", selected);
    }
  }

  async function finishOnboarding() {
    await setSetting("hasCompletedOnboarding", true);
    try {
      await invoke("close_onboarding_window");
      await invoke("show_main_window");
    } catch {
      /* ignore */
    }
  }
</script>

{#if ready}
  <OnboardingScreen
    initialStep={showInstallHint ? 1 : 2}
    {showInstallHint}
    {outputDirSet}
    {filesReady}
    onComplete={finishOnboarding}
    onPickOutput={handlePickOutput}
  />
{/if}