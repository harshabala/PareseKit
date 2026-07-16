<script lang="ts">
  /**
   * Monochrome section icons for Settings.
   * Paths adapted from Lucide Icons (https://lucide.dev) — ISC License.
   * Stroke icons match header controls; recolored via currentColor.
   */
  let {
    name,
    size = 14,
  }: {
    name:
      | "globe"
      | "palette"
      | "power"
      | "keyboard"
      | "chart"
      | "shield"
      | "folder"
      | "download"
      | "info";
    size?: number;
  } = $props();
</script>

<svg
  class="settings-section-icon"
  width={size}
  height={size}
  viewBox="0 0 24 24"
  fill="none"
  aria-hidden="true"
>
  {#if name === "globe"}
    <!-- lucide:globe -->
    <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" />
    <path
      d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10Z"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
    <path
      d="M2 12h20"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
    />
  {:else if name === "palette"}
    <!-- lucide:palette -->
    <path
      d="M12 22a10 10 0 1 1 10-10c0 2.2-1.8 3-3 3h-1.5a2.5 2.5 0 0 0-2.5 2.5c0 .7.3 1.4.7 1.9.5.6.8 1.3.8 2.1A2.5 2.5 0 0 1 12 22Z"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
    <circle cx="7.5" cy="10.5" r="1" fill="currentColor" />
    <circle cx="12" cy="7.5" r="1" fill="currentColor" />
    <circle cx="16.5" cy="10.5" r="1" fill="currentColor" />
  {:else if name === "power"}
    <!-- lucide:power -->
    <path
      d="M12 2v10"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
    />
    <path
      d="M18.4 6.6a9 9 0 1 1-12.8 0"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
    />
  {:else if name === "keyboard"}
    <!-- lucide:keyboard -->
    <rect
      x="2"
      y="6"
      width="20"
      height="12"
      rx="2"
      stroke="currentColor"
      stroke-width="2"
    />
    <path
      d="M6 10h.01M10 10h.01M14 10h.01M18 10h.01M8 14h8"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
    />
  {:else if name === "chart"}
    <!-- lucide:chart-column -->
    <path
      d="M3 3v18h18"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
    <path
      d="M8 17V9M13 17V5M18 17v-7"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
  {:else if name === "shield"}
    <!-- lucide:shield -->
    <path
      d="M20 13c0 5-3.5 7.5-8 9-4.5-1.5-8-4-8-9V6l8-3 8 3v7Z"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
  {:else if name === "folder"}
    <!-- lucide:folder -->
    <path
      d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9l-.81-1.2A2 2 0 0 0 8.07 2H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2Z"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
  {:else if name === "download"}
    <!-- lucide:download -->
    <path
      d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
    <path
      d="m7 10 5 5 5-5M12 15V3"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
  {:else if name === "info"}
    <!-- lucide:info -->
    <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" />
    <path
      d="M12 16v-4M12 8h.01"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
    />
  {/if}
</svg>
