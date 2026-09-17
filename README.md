# qylad-nixos

A Nix flake for my personal systems.

## Flake Outputs

### `qylad-msi`

Personal host configuration for my main laptop hardware. It is
hardware-dependent and not intended to be built or run on other machines.

### `qylad-msi-vm`

Virtual machine mirror to `qylad-msi`

```bash
nix run github:Debieche-Amine/qylad-nix#qylad-msi-vm
```

### `vm-test`

Test virtual machine environment.

```bash
nix run github:Debieche-Amine/qylad-nix#vm-test
```

### `just-a-vm`

Standalone test virtual machine instance.

```bash
nix run github:Debieche-Amine/qylad-nix#just-a-vm
```

### `cli-vm`

CLI-only NixOS virtual machine environment (without GUI, importing
`locale.nix`).

```bash
nix run github:Debieche-Amine/qylad-nix#cli-vm
```

### `hirara`

Headless NixOS virtual machine environment with Antigravity CLI
(`antigravity-cli`), Chromium, and `locale.nix`.

```bash
nix run github:Debieche-Amine/qylad-nix#hirara
```

### `albion-online`

Albion Online native Linux client packaged with `buildFHSEnv`.

```bash
nix run github:Debieche-Amine/qylad-nix#albion-online
```

### `devShells.esp32`

Development environment for ESP32 Rust (`std` / `esp-idf`) development.

```bash
nix develop github:Debieche-Amine/qylad-nix#esp32
```

### `templates.esp32`

Minimal ESP32 Rust starter template.

```bash
nix flake init -t github:Debieche-Amine/qylad-nix#esp32
```
