import { Command } from "@tauri-apps/plugin-shell";
import { resolveResource } from "@tauri-apps/api/path";

export interface ParseConfig {
  inputDir: string;
  outputDir: string;
  format: "md" | "json" | "txt";
  ocrLanguage?: string;
  workers?: number;
}

export interface ParseEvent {
  type: "start" | "progress" | "done" | "error";
  file?: string;
  status?: string;
  path?: string;
  message?: string;
  total?: number;
  parsed?: number;
  skipped?: number;
  errors?: number;
  error?: string;
}

export function runParse(
  config: ParseConfig,
  onEvent: (event: ParseEvent) => void
): Promise<void> {
  return new Promise(async (resolve, reject) => {
    try {
      // In dev mode, use a relative path (cwd is the project root which has sidecar/).
      // In production, resolve via Tauri's resource dir where the file is bundled.
      const scriptPath = import.meta.env.DEV
        ? "sidecar/index.js"
        : await resolveResource("sidecar/index.js");

      const command = Command.create("node", [scriptPath]);

      command.on("error", (error) => {
        onEvent({ type: "error", message: String(error) });
        reject(new Error(String(error)));
      });

      command.stdout.on("data", (line) => {
        // stdout data may contain multiple JSON lines
        const lines = line.split("\n").filter(Boolean);
        for (const l of lines) {
          try {
            const event: ParseEvent = JSON.parse(l);
            onEvent(event);
            if (event.type === "done") {
              resolve();
            }
          } catch (e) {
            console.error("Failed to parse sidecar output:", l);
          }
        }
      });

      command.stderr.on("data", (line) => {
        console.warn("[sidecar stderr]", line);
      });

      command.on("close", (data) => {
        if (data.code !== 0) {
          reject(new Error(`Sidecar exited with code ${data.code}`));
        }
      });

      const child = await command.spawn();
      // Write config as a single JSON line (readline expects \n)
      await child.write(JSON.stringify(config) + "\n");
    } catch (err) {
      reject(err);
    }
  });
}
