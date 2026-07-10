<script lang="ts">
  import { fade } from "svelte/transition";
  import { prefersReducedMotion } from "svelte/motion";
  import { t } from "../lib/i18n.svelte";
  import { hintFadeIn, hintFadeOut } from "../lib/motion";
  import {
    approximateChatGptMessages,
    formatTokenCount,
    tokensSavedToday,
    type TokenStats,
  } from "../lib/tokenStats";
  import type { ConvertDestination } from "../lib/activation";
  import type { BatchTokenSavings } from "../lib/progress";

  let {
    batch,
    stats,
    successCount,
    failedCount,
    successRateLabel,
    showDestinationPrompt = false,
    onOpenOutput,
    onConvertMore,
    onDestination,
  }: {
    batch: BatchTokenSavings;
    stats: TokenStats | null;
    successCount: number;
    failedCount: number;
    successRateLabel: string;
    showDestinationPrompt?: boolean;
    onOpenOutput: () => void;
    onConvertMore: () => void;
    onDestination: (value: ConvertDestination) => void;
  } = $props();

  const reducedMotion = $derived(prefersReducedMotion.current);
  const fadeIn = $derived(hintFadeIn(reducedMotion));
  const fadeOut = $derived(hintFadeOut(reducedMotion));

  const batchTokens = $derived(batch.tokensSaved);
  const todayTokens = $derived(stats ? tokensSavedToday(stats) : 0);
  const lifetimeTokens = $derived(stats?.total_tokens_saved ?? 0);
  const lifetimeFiles = $derived(stats?.total_files_converted ?? 0);
  const chatApprox = $derived(approximateChatGptMessages(lifetimeTokens));
  const partialFail = $derived(failedCount > 0 && successCount > 0);
  const allFailed = $derived(failedCount > 0 && successCount === 0);
</script>

<section
  class="batch-scoreboard"
  aria-label={t("scoreboard.aria")}
  in:fade={fadeIn}
  out:fade={fadeOut}
>
  <h2 class="batch-scoreboard-title">
    {#if allFailed}
      {t("scoreboard.titleFailed")}
    {:else if partialFail}
      {t("scoreboard.titlePartial")}
    {:else}
      {t("scoreboard.titleSuccess")}
    {/if}
  </h2>

  <div class="batch-scoreboard-hero">
    <span class="batch-scoreboard-hero-value">{formatTokenCount(batchTokens)}</span>
    <span class="batch-scoreboard-hero-label">{t("scoreboard.thisBatch")}</span>
    {#if batchTokens > 0}
      <p class="batch-scoreboard-hero-sub">
        {t("scoreboard.chatApprox", {
          count: formatTokenCount(approximateChatGptMessages(batchTokens)),
        })}
      </p>
    {/if}
  </div>

  <dl class="batch-scoreboard-stats">
    <div>
      <dt>{t("scoreboard.today")}</dt>
      <dd>{formatTokenCount(todayTokens)}</dd>
    </div>
    <div>
      <dt>{t("scoreboard.allTime")}</dt>
      <dd>{formatTokenCount(lifetimeTokens)}</dd>
    </div>
    <div>
      <dt>{t("scoreboard.filesAllTime")}</dt>
      <dd>{formatTokenCount(lifetimeFiles)}</dd>
    </div>
    <div>
      <dt>{t("scoreboard.successRate")}</dt>
      <dd title={t("scoreboard.successRateHint")}>{successRateLabel}</dd>
    </div>
  </dl>

  {#if partialFail || allFailed}
    <p class="batch-scoreboard-fail-hint" role="status">
      {t("scoreboard.failHint", {
        ok: successCount,
        fail: failedCount,
      })}
    </p>
  {/if}

  <p class="batch-scoreboard-method">{t("scoreboard.method")}</p>
  <p class="batch-scoreboard-privacy">{t("scoreboard.privacy")}</p>

  <div class="batch-scoreboard-actions">
    <button type="button" class="run-parse-btn" onclick={onOpenOutput}>
      {t("run.openOutput")}
    </button>
    <button type="button" class="secondary" onclick={onConvertMore}>
      {t("scoreboard.convertMore")}
    </button>
  </div>

  {#if showDestinationPrompt && successCount > 0}
    <div class="batch-scoreboard-dest" role="group" aria-label={t("scoreboard.destAria")}>
      <p class="batch-scoreboard-dest-title">{t("scoreboard.destTitle")}</p>
      <div class="batch-scoreboard-dest-btns">
        <button type="button" class="secondary" onclick={() => onDestination("claude")}>
          Claude
        </button>
        <button type="button" class="secondary" onclick={() => onDestination("chatgpt")}>
          ChatGPT
        </button>
        <button type="button" class="secondary" onclick={() => onDestination("gemini")}>
          Gemini
        </button>
        <button type="button" class="secondary" onclick={() => onDestination("obsidian")}>
          Obsidian
        </button>
        <button type="button" class="secondary" onclick={() => onDestination("other")}>
          {t("scoreboard.destOther")}
        </button>
        <button type="button" class="secondary" onclick={() => onDestination("skipped")}>
          {t("scoreboard.destSkip")}
        </button>
      </div>
    </div>
  {/if}

  {#if lifetimeTokens > 0}
    <p class="batch-scoreboard-lifetime-note">
      {t("tokenSavings.chatGptApprox", { count: formatTokenCount(chatApprox) })}
      <span class="token-savings-approx-label">{t("tokenSavings.approximateLabel")}</span>
    </p>
  {/if}
</section>

<style>
  .batch-scoreboard {
    margin-top: 12px;
    padding: 14px 14px 12px;
    border-radius: var(--radius-md, 10px);
    border: 1px solid var(--border, rgba(0, 0, 0, 0.08));
    background: var(--bg-elevated, var(--surface, #fff));
  }
  .batch-scoreboard-title {
    margin: 0 0 10px;
    font-size: 0.95rem;
    font-weight: 600;
  }
  .batch-scoreboard-hero {
    text-align: center;
    margin-bottom: 12px;
  }
  .batch-scoreboard-hero-value {
    display: block;
    font-size: 1.85rem;
    font-weight: 650;
    font-variant-numeric: tabular-nums;
    letter-spacing: -0.02em;
  }
  .batch-scoreboard-hero-label {
    display: block;
    font-size: 0.75rem;
    opacity: 0.7;
    margin-top: 2px;
  }
  .batch-scoreboard-hero-sub {
    margin: 6px 0 0;
    font-size: 0.75rem;
    opacity: 0.75;
  }
  .batch-scoreboard-stats {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 8px 12px;
    margin: 0 0 10px;
  }
  .batch-scoreboard-stats dt {
    font-size: 0.7rem;
    opacity: 0.65;
    margin: 0;
  }
  .batch-scoreboard-stats dd {
    margin: 2px 0 0;
    font-size: 0.95rem;
    font-weight: 600;
    font-variant-numeric: tabular-nums;
  }
  .batch-scoreboard-method,
  .batch-scoreboard-privacy,
  .batch-scoreboard-fail-hint,
  .batch-scoreboard-lifetime-note {
    margin: 0 0 6px;
    font-size: 0.7rem;
    line-height: 1.4;
    opacity: 0.72;
  }
  .batch-scoreboard-privacy {
    margin-bottom: 10px;
  }
  .batch-scoreboard-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
  }
  .batch-scoreboard-dest {
    margin-top: 12px;
    padding-top: 10px;
    border-top: 1px solid var(--border, rgba(0, 0, 0, 0.06));
  }
  .batch-scoreboard-dest-title {
    margin: 0 0 8px;
    font-size: 0.8rem;
  }
  .batch-scoreboard-dest-btns {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
  }
</style>
