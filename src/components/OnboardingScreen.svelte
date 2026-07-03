<script lang="ts">
  import { fade } from "svelte/transition";
  import { prefersReducedMotion } from "svelte/motion";
  import { invoke } from "@tauri-apps/api/core";
  import { t } from "../lib/i18n.svelte";
  import { hintFadeIn, hintFadeOut } from "../lib/motion";
  import appIcon from "../assets/app-icon.png";

  const INSTALL_DOCS_URL =
    "https://github.com/harshabala/parsekit/blob/master/docs/INSTALL.md";

  let {
    initialStep,
    showInstallHint,
    outputDirSet,
    filesReady,
    onComplete,
    onPickOutput,
  }: {
    initialStep: number;
    showInstallHint: boolean;
    outputDirSet: boolean;
    filesReady: boolean;
    onComplete: () => void;
    onPickOutput: () => void;
  } = $props();

  const reducedMotion = $derived(prefersReducedMotion.current);
  const hintFadeInParams = $derived(hintFadeIn(reducedMotion));
  const hintFadeOutParams = $derived(hintFadeOut(reducedMotion));

  const totalSteps = $derived(showInstallHint ? 2 : 1);
  let step = $state(initialStep);

  let gatekeeperCopied = $state(false);
  let gatekeeperCopyError = $state<string | null>(null);
  let gatekeeperCommand = $state("");

  const step1Done = $derived(outputDirSet);
  const step2Done = $derived(filesReady);

  $effect(() => {
    void loadGatekeeperCommand();
  });

  async function loadGatekeeperCommand() {
    try {
      gatekeeperCommand = await invoke<string>("gatekeeper_fix_command");
    } catch {
      gatekeeperCommand =
        "xattr -cr /Applications/ParseKit.app && xattr -d com.apple.FinderInfo /Applications/ParseKit.app";
    }
  }

  async function copyGatekeeperCommand() {
    gatekeeperCopyError = null;
    try {
      await invoke("copy_text_to_clipboard", { text: gatekeeperCommand });
      try {
        await invoke("trigger_haptic");
      } catch {
        /* optional */
      }
      gatekeeperCopied = true;
      setTimeout(() => {
        gatekeeperCopied = false;
      }, 2500);
    } catch (e) {
      gatekeeperCopied = false;
      gatekeeperCopyError =
        e instanceof Error ? e.message : String(e) || t("gatekeeper.copyFailed");
    }
  }

  async function openApplications() {
    try {
      await invoke("open_in_finder", { path: "/Applications" });
    } catch {
      /* ignore */
    }
  }

  function learnMore() {
    window.open(INSTALL_DOCS_URL, "_blank", "noopener,noreferrer");
  }

  function continueInstall() {
    if (showInstallHint && step === 1) {
      step = 2;
      return;
    }
    onComplete();
  }
</script>

<div class="onboarding-root">
  <div class="onboarding-progress" aria-live="polite">
    <span>{t("onboarding.progress", { current: step, total: totalSteps })}</span>
    <div class="onboarding-progress-dots" aria-hidden="true">
      {#each Array(totalSteps) as _, i}
        {@const n = i + 1}
        {#if i > 0}<span class="onboarding-progress-line"></span>{/if}
        <span
          class="onboarding-progress-dot"
          class:active={n === step || (totalSteps === 1 && n === 1)}
        ></span>
      {/each}
    </div>
  </div>

  <div class="onboarding-content">
    {#if step === 1 && showInstallHint}
      <div class="onboarding-step-panel" in:fade={{ duration: reducedMotion ? 0 : 200 }}>
        <h1 class="onboarding-title">{t("onboarding.installTitle")}</h1>
        <p class="onboarding-subtitle">{t("onboarding.installSubtitle")}</p>

        <div class="onboarding-hero" aria-hidden="true">
          <div class="onboarding-hero-row">
            <div class="onboarding-icon-slot">
              <img
                class="onboarding-icon-img"
                src={appIcon}
                width="128"
                height="128"
                alt=""
              />
              <span class="onboarding-icon-label">ParseKit</span>
            </div>

            <div class="onboarding-arrow-col">
              <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
                <path
                  d="M12 5v12M12 17l-5-5M12 17l5-5"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
              </svg>
            </div>

            <div class="onboarding-icon-slot">
              <div class="onboarding-folder-icon">
                <svg viewBox="0 0 96 96" fill="currentColor" aria-hidden="true">
                  <path
                    d="M12 24c0-4.4 3.6-8 8-8h18l8 8h38c4.4 0 8 3.6 8 8v40c0 4.4-3.6 8-8 8H20c-4.4 0-8-3.6-8-8V24z"
                    opacity="0.9"
                  />
                </svg>
              </div>
              <span class="onboarding-icon-label">{t("onboarding.applications")}</span>
            </div>
          </div>
        </div>

        <p class="onboarding-helper">{t("onboarding.installHelper")}</p>

        <div class="onboarding-code-card" role="region" aria-label={t("gatekeeper.title")}>
          <div class="onboarding-code-toolbar">
            <div class="onboarding-traffic-lights" aria-hidden="true">
              <span></span><span></span><span></span>
            </div>
            <button
              type="button"
              class="onboarding-code-copy"
              onclick={copyGatekeeperCommand}
            >
              {#key gatekeeperCopied}
                <span in:fade={hintFadeInParams} out:fade={hintFadeOutParams}>
                  {gatekeeperCopied ? t("gatekeeper.copied") : t("onboarding.copyCommand")}
                </span>
              {/key}
            </button>
          </div>
          <div class="onboarding-code-body">
            <div><span class="prompt">$ </span><span class="cmd">{gatekeeperCommand}</span></div>
          </div>
        </div>
        {#if gatekeeperCopyError}
          <p class="onboarding-helper" role="alert">{gatekeeperCopyError}</p>
        {/if}

        <div class="onboarding-info-card">
          <svg class="onboarding-info-icon" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
            <path
              fill-rule="evenodd"
              d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
              clip-rule="evenodd"
            />
          </svg>
          <div>
            <p class="onboarding-info-title">{t("onboarding.fileSupportTitle")}</p>
            <p class="onboarding-info-body">{t("onboarding.fileSupportBody")}</p>
          </div>
        </div>

        <div class="onboarding-actions">
          <div class="onboarding-actions-row">
            <button type="button" class="onboarding-btn-primary" onclick={continueInstall}>
              {t("onboarding.continue")}
            </button>
            <button type="button" class="onboarding-btn-secondary" onclick={openApplications}>
              {t("onboarding.openApplications")}
            </button>
          </div>
          <button type="button" class="onboarding-link" onclick={learnMore}>
            {t("onboarding.learnMore")}
          </button>
        </div>
      </div>
    {:else}
      <div class="onboarding-step-panel" in:fade={{ duration: reducedMotion ? 0 : 200 }}>
        <h1 class="onboarding-title">{t("onboarding.getStartedTitle")}</h1>
        <p class="onboarding-subtitle">{t("onboarding.getStartedSubtitle")}</p>

        <ol class="onboarding-steps-list">
          <li class:done={step1Done}>
            <span class="onboarding-step-badge">{step1Done ? "✓" : "1"}</span>
            <div class="onboarding-step-content">
              <span>{t("onboarding.stepOutput")}</span>
              {#if !step1Done}
                <button type="button" class="onboarding-btn-secondary" onclick={onPickOutput}>
                  {t("onboarding.chooseOutput")}
                </button>
              {/if}
            </div>
          </li>
          <li class:done={step2Done}>
            <span class="onboarding-step-badge">{step2Done ? "✓" : "2"}</span>
            <span>{t("onboarding.stepFiles")}</span>
          </li>
          <li>
            <span class="onboarding-step-badge">3</span>
            <span>{t("onboarding.stepRun")}</span>
          </li>
        </ol>

        <div class="onboarding-info-card">
          <svg class="onboarding-info-icon" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
            <path
              fill-rule="evenodd"
              d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
              clip-rule="evenodd"
            />
          </svg>
          <div>
            <p class="onboarding-info-title">{t("onboarding.fileSupportTitle")}</p>
            <p class="onboarding-info-body">{t("onboarding.fileSupportBody")}</p>
          </div>
        </div>

        <div class="onboarding-actions">
          <button type="button" class="onboarding-btn-primary" onclick={onComplete}>
            {t("onboarding.continue")}
          </button>
          <p class="onboarding-tray-note">{t("onboarding.trayHint")}</p>
        </div>
      </div>
    {/if}
  </div>
</div>