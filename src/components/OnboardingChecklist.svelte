<script lang="ts">
  import { fade } from "svelte/transition";
  import { prefersReducedMotion } from "svelte/motion";
  import { invoke } from "@tauri-apps/api/core";
  import { t } from "../lib/i18n.svelte";
  import { hintFadeIn, hintFadeOut } from "../lib/motion";

  let {
    outputDirSet,
    filesReady,
    onDismiss,
    onPickOutput,
    showInstallHint = false,
  }: {
    outputDirSet: boolean;
    filesReady: boolean;
    onDismiss: () => void;
    onPickOutput: () => void;
    showInstallHint?: boolean;
  } = $props();

  const reducedMotion = $derived(prefersReducedMotion.current);
  const hintFadeInParams = $derived(hintFadeIn(reducedMotion));
  const hintFadeOutParams = $derived(hintFadeOut(reducedMotion));

  let gatekeeperCopied = $state(false);
  let gatekeeperCopyError = $state<string | null>(null);

  const step1Done = $derived(outputDirSet);
  const step2Done = $derived(filesReady);
  const step3Ready = $derived(outputDirSet && filesReady);

  async function copyGatekeeperCommand() {
    gatekeeperCopyError = null;
    try {
      const cmd = await invoke<string>("gatekeeper_fix_command");
      await invoke("copy_text_to_clipboard", { text: cmd });
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
</script>

<div class="onboarding-card" role="region" aria-labelledby="onboarding-title">
  <div class="onboarding-header">
    <span id="onboarding-title" class="onboarding-title">{t("onboarding.title")}</span>
    <button type="button" class="onboarding-dismiss" onclick={onDismiss}>
      {t("onboarding.dismiss")}
    </button>
  </div>
  <p class="settings-hint onboarding-lead">{t("onboarding.lead")}</p>
  {#if showInstallHint}
    <p class="settings-hint onboarding-install-hint">{t("onboarding.installHint")}</p>
    <div class="onboarding-gatekeeper">
      <button
        type="button"
        class="secondary gatekeeper-copy-btn"
        class:gatekeeper-copy-success={gatekeeperCopied}
        onclick={copyGatekeeperCommand}
      >
        {#key gatekeeperCopied}
          <span in:fade={hintFadeInParams} out:fade={hintFadeOutParams}>
            {gatekeeperCopied ? t("gatekeeper.copied") : t("gatekeeper.copyCommand")}
          </span>
        {/key}
      </button>
      {#if gatekeeperCopyError}
        <p class="settings-hint deps-error" role="alert">{gatekeeperCopyError}</p>
      {/if}
    </div>
  {/if}
  <p class="settings-hint onboarding-formats-hint">{t("onboarding.formatsHint")}</p>
  <ol class="onboarding-steps">
    <li class:done={step1Done}>
      <span class="onboarding-step-num">1</span>
      <div class="onboarding-step-body">
        <span>{t("onboarding.stepOutput")}</span>
        {#if !step1Done}
          <button type="button" class="secondary onboarding-step-btn" onclick={onPickOutput}>
            {t("onboarding.chooseOutput")}
          </button>
        {/if}
      </div>
    </li>
    <li class:done={step2Done}>
      <span class="onboarding-step-num">2</span>
      <span>{t("onboarding.stepFiles")}</span>
    </li>
    <li class:done={step3Ready}>
      <span class="onboarding-step-num">3</span>
      <span>{t("onboarding.stepRun")}</span>
    </li>
  </ol>
  <p class="settings-hint onboarding-tray-hint">{t("onboarding.trayHint")}</p>
</div>