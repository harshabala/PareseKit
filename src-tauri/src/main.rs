#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    let instance = single_instance::SingleInstance::new("com.parsedock.app").unwrap();
    if !instance.is_single() {
        eprintln!("ParseDock is already running. Quit other copies in Activity Monitor, then try again.");
        std::process::exit(0);
    }
    parsedock_lib::run();
}