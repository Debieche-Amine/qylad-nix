# ESP32 Rust Minimal Template

Minimal Rust (`std` / `esp-idf`) template for ESP32.

## Quickstart

```bash
# 1. Initialize template in current directory
nix flake init -t github:Debieche-Amine/qylad-nix#esp32

# 2. Enter development shell
nix develop
espup install # First time setup if needed

# 3. Build & Flash
cargo build
espflash flash --monitor
```
