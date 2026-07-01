//! Global hotkey: parse Finder selection or clipboard file paths in the background.

use std::path::Path;
use std::sync::Mutex;

use tauri::{AppHandle, Emitter, Manager, Runtime};
use tauri_plugin_global_shortcut::{GlobalShortcutExt, ShortcutState};

pub const DEFAULT_GLOBAL_SHORTCUT: &str = "Control+Shift+KeyM";
const SETTINGS_KEY: &str = "globalShortcut";

#[derive(Default)]
pub struct GlobalHotkeyState {
    current_shortcut: Mutex<String>,
}

fn settings_path() -> Result<std::path::PathBuf, String> {
    let home = std::env::var("HOME").map_err(|e| e.to_string())?;
    Ok(std::path::PathBuf::from(home)
        .join("Library/Application Support/com.harshabala.parsekit/settings.json"))
}

pub fn read_global_shortcut_from_settings() -> String {
    let path = match settings_path() {
        Ok(path) => path,
        Err(_) => return DEFAULT_GLOBAL_SHORTCUT.to_string(),
    };
    let raw = match std::fs::read_to_string(path) {
        Ok(raw) => raw,
        Err(_) => return DEFAULT_GLOBAL_SHORTCUT.to_string(),
    };
    let value: serde_json::Value = match serde_json::from_str(&raw) {
        Ok(value) => value,
        Err(_) => return DEFAULT_GLOBAL_SHORTCUT.to_string(),
    };
    value
        .get(SETTINGS_KEY)
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(str::to_string)
        .unwrap_or_else(|| DEFAULT_GLOBAL_SHORTCUT.to_string())
}

fn normalize_user_path(path: String) -> String {
    let trimmed = path.trim();
    if trimmed.starts_with("file://") {
        if let Ok(url) = url::Url::parse(trimmed) {
            if let Ok(p) = url.to_file_path() {
                return p.to_string_lossy().into_owned();
            }
        }
    }
    trimmed.to_string()
}

fn is_supported_extension(path: &str) -> bool {
    Path::new(path)
        .extension()
        .and_then(|e| e.to_str())
        .map(|ext| crate::SUPPORTED_EXTENSIONS.contains(&ext.to_lowercase().as_str()))
        .unwrap_or(false)
}

fn expand_path_to_supported_files(path: &str) -> Vec<String> {
    let normalized = normalize_user_path(path.to_string());
    if normalized.is_empty() {
        return Vec::new();
    }
    let p = Path::new(&normalized);
    if p.is_file() {
        return if is_supported_extension(&normalized) {
            vec![normalized]
        } else {
            Vec::new()
        };
    }
    if p.is_dir() {
        return crate::scan_directory_sync(normalized)
            .unwrap_or_default();
    }
    Vec::new()
}

#[cfg(target_os = "macos")]
fn run_osascript(script: &str) -> Option<String> {
    let output = std::process::Command::new("osascript")
        .arg("-e")
        .arg(script)
        .output()
        .ok()?;
    if !output.status.success() {
        return None;
    }
    let text = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if text.is_empty() {
        None
    } else {
        Some(text)
    }
}

#[cfg(target_os = "macos")]
fn get_finder_selection_paths() -> Vec<String> {
    let script = r#"
tell application "Finder"
    set sel to selection
    if sel is {} then return ""
    set out to ""
    repeat with itemRef in sel
        set end of out to (POSIX path of (itemRef as alias)) & linefeed
    end repeat
    return text 1 thru -2 of out
end tell
"#;
    run_osascript(script)
        .map(|text| {
            text.lines()
                .map(str::trim)
                .filter(|line| !line.is_empty())
                .map(str::to_string)
                .collect()
        })
        .unwrap_or_default()
}

#[cfg(not(target_os = "macos"))]
fn get_finder_selection_paths() -> Vec<String> {
    Vec::new()
}

pub fn resolve_hotkey_input_paths() -> Vec<String> {
    let mut raw_paths = get_finder_selection_paths();
    if raw_paths.is_empty() {
        raw_paths = crate::clipboard_paths::get_clipboard_file_paths();
    }

    let mut files = Vec::new();
    for path in raw_paths {
        files.extend(expand_path_to_supported_files(&path));
    }

    files.sort();
    files.dedup();
    files
}

fn handle_hotkey_pressed<R: Runtime>(app: &AppHandle<R>) {
    let finder_paths = get_finder_selection_paths();
    if !finder_paths.is_empty() {
        let mut files = Vec::new();
        for path in finder_paths {
            files.extend(expand_path_to_supported_files(&path));
        }
        files.sort();
        files.dedup();
        if files.is_empty() {
            let _ = crate::display_notification(
                "ParseKit",
                "No supported files in Finder selection.",
            );
            return;
        }
        let _ = app.emit("background-parse", files);
        return;
    }

    let clipboard_files = crate::clipboard_convert::resolve_clipboard_supported_files();
    if !clipboard_files.is_empty() {
        tauri::async_runtime::spawn_blocking(|| {
            crate::clipboard_convert::run_clipboard_convert_with_notification(
                "ParseKit",
                "Markdown copied to clipboard",
                "Clipboard convert failed",
            );
        });
        return;
    }

    let _ = crate::display_notification(
        "ParseKit",
        "No supported files in Finder selection or clipboard.",
    );
}

pub fn register_global_hotkey<R: Runtime>(
    app: &AppHandle<R>,
    shortcut: &str,
    state: &GlobalHotkeyState,
) -> Result<(), String> {
    let gs = app.global_shortcut();
    if let Ok(mut current) = state.current_shortcut.lock() {
        if !current.is_empty() && current.as_str() != shortcut {
            let _ = gs.unregister(current.as_str());
        }
        gs.on_shortcut(shortcut, |app, _shortcut, event| {
            if event.state == ShortcutState::Pressed {
                handle_hotkey_pressed(app);
            }
        })
        .map_err(|e| e.to_string())?;
        *current = shortcut.to_string();
    }
    Ok(())
}

pub fn setup_global_hotkey<R: Runtime>(app: &AppHandle<R>) -> Result<(), String> {
    let shortcut = read_global_shortcut_from_settings();
    let state = app
        .try_state::<GlobalHotkeyState>()
        .ok_or_else(|| "GlobalHotkeyState missing".to_string())?;
    register_global_hotkey(app, &shortcut, state.inner())
}

#[tauri::command]
pub fn get_global_shortcut(state: tauri::State<'_, GlobalHotkeyState>) -> String {
    state
        .current_shortcut
        .lock()
        .map(|s| s.clone())
        .unwrap_or_else(|_| DEFAULT_GLOBAL_SHORTCUT.to_string())
}

#[tauri::command]
pub fn update_global_shortcut<R: Runtime>(
    app: AppHandle<R>,
    state: tauri::State<'_, GlobalHotkeyState>,
    shortcut: String,
) -> Result<(), String> {
    let shortcut = shortcut.trim();
    if shortcut.is_empty() {
        return Err("Shortcut cannot be empty".into());
    }
    register_global_hotkey(&app, shortcut, state.inner())
}