#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    parsedock_lib::startup_trace(&format!(
        "main() entered pid={}",
        std::process::id()
    ));
    let instance = single_instance::SingleInstance::new("com.parsedock.app").unwrap();
    if !instance.is_single() {
        parsedock_lib::startup_trace(
            "single-instance guard: another ParseDock is running, exiting",
        );
        eprintln!("ParseDock is already running. Quit other copies in Activity Monitor, then try again.");
        std::process::exit(0);
    }
    parsedock_lib::startup_trace("single-instance OK, entering tauri::run");
    parsedock_lib::run();
}