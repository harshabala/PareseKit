//! macOS-specific popover window configuration so the panel appears above the menu bar.

use std::sync::atomic::{AtomicBool, Ordering};

static WINDOW_CONFIGURED: AtomicBool = AtomicBool::new(false);

#[cfg(target_os = "macos")]
use objc2::MainThreadMarker;
#[cfg(target_os = "macos")]
use objc2_app_kit::{
    NSApplication, NSColor, NSFloatingWindowLevel, NSWindow, NSWindowCollectionBehavior,
};
#[cfg(target_os = "macos")]
use tauri::WebviewWindow;

/// Apply NSWindow popover settings once (defer until first open so webview init is stable).
pub fn ensure_popover_window_configured<R: tauri::Runtime>(window: &WebviewWindow<R>) {
    if WINDOW_CONFIGURED.swap(true, Ordering::SeqCst) {
        return;
    }
    configure_popover_window(window);
}

/// Raise the app and popover window so a borderless panel is actually visible.
#[cfg(target_os = "macos")]
pub fn activate_app_for_popover<R: tauri::Runtime>(window: &WebviewWindow<R>) {
    ensure_popover_window_configured(window);
    let Some(mtm) = MainThreadMarker::new() else {
        let _ = window.show();
        let _ = window.set_focus();
        return;
    };
    let app = NSApplication::sharedApplication(mtm);
    app.activate();
    let _ = window.set_always_on_top(true);
    let _ = window.show();
    let _ = window.set_focus();
}

/// Configure the webview window as a floating popover (above menu bar, all spaces).
#[cfg(target_os = "macos")]
pub fn configure_popover_window<R: tauri::Runtime>(window: &WebviewWindow<R>) {
    let Ok(ns_ptr) = window.ns_window() else {
        return;
    };
    unsafe {
        let ns_window: &NSWindow = &*ns_ptr.cast();
        ns_window.setLevel(NSFloatingWindowLevel);
        let behavior = NSWindowCollectionBehavior::CanJoinAllSpaces
            | NSWindowCollectionBehavior::FullScreenAuxiliary;
        ns_window.setCollectionBehavior(behavior);
        ns_window.setHasShadow(true);
        ns_window.setOpaque(false);
        ns_window.setBackgroundColor(Some(&NSColor::clearColor()));
    }
}

#[cfg(not(target_os = "macos"))]
pub fn activate_app_for_popover<R: tauri::Runtime>(window: &WebviewWindow<R>) {
    ensure_popover_window_configured(window);
    let _ = window.set_always_on_top(true);
    let _ = window.show();
    let _ = window.set_focus();
}

#[cfg(not(target_os = "macos"))]
pub fn configure_popover_window<R: tauri::Runtime>(_window: &WebviewWindow<R>) {}