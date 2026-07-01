import { invoke } from "@tauri-apps/api/core";
import { t } from "./i18n.svelte";

export class FinderActionState {
  installed = $state(false);
  busy = $state(false);
  notice = $state<string | null>(null);

  async refreshStatus() {
    try {
      this.installed = await invoke<boolean>("finder_quick_action_installed");
    } catch {
      this.installed = false;
    }
  }

  async install() {
    this.busy = true;
    this.notice = null;
    try {
      const msg = await invoke<string>("install_finder_quick_action");
      this.notice = msg || t("settings.finderInstalled");
      await this.refreshStatus();
    } catch (e) {
      this.notice =
        (e instanceof Error ? e.message : String(e)) || t("settings.finderInstallFailed");
    } finally {
      this.busy = false;
    }
  }
}

export const finderActionState = new FinderActionState();
