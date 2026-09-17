use esp_idf_sys as _; // Link ESP-IDF sys bindings
use std::thread;
use std::time::Duration;

fn main() {
    // It is necessary to call this function once at startup to bind ESP-IDF sys patches
    esp_idf_sys::link_patches();

    // Initialize logger
    esp_idf_svc::log::EspLogger::initialize_default();

    log::info!("Hello from ESP32 Rust std environment!");

    let mut counter = 0;
    loop {
        counter += 1;
        log::info!("Loop tick #{}", counter);
        thread::sleep(Duration::from_secs(1));
    }
}
