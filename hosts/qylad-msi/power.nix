{
  pkgs,
  lib,
  ...
}: let
  powerProfileBackend = pkgs.writeShellScriptBin "power-profile-backend" (builtins.readFile ../../modules/home/hyprland/power-profile/backend.sh);

  nvidiaPower = pkgs.writeShellScriptBin "nvidia-power" ''
    set -euo pipefail

    GPU_PCI="0000:02:00.0"
    ROOT_PORT="0000:00:1c.4"
    GPU_PATH="/sys/bus/pci/devices/$GPU_PCI"
    ROOT_PORT_PATH="/sys/bus/pci/devices/$ROOT_PORT"

    usage() {
      echo "Usage: nvidia-power {status|on|off|auto}" >&2
      exit 1
    }

    ACTION="''${1:-status}"

    has_active_clients() {
      ${pkgs.psmisc}/bin/fuser /dev/nvidia* >/dev/null 2>&1
    }

    list_active_clients() {
      ${pkgs.psmisc}/bin/fuser -v /dev/nvidia* 2>&1 || true
    }

    case "$ACTION" in
      status)
        echo "=== NVIDIA GPU Power Status ==="
        if [ ! -d "$GPU_PATH" ]; then
          echo "Status:          OFF (Detached from PCIe bus)"
          echo "Power State:     D3cold (0W)"
          echo "PCI Address:     $GPU_PCI (disconnected)"
        else
          PWR_STATE="Unknown"
          [ -f "$GPU_PATH/power_state" ] && PWR_STATE="$(cat "$GPU_PATH/power_state")"

          RT_STATUS="Unknown"
          [ -f "$GPU_PATH/power/runtime_status" ] && RT_STATUS="$(cat "$GPU_PATH/power/runtime_status")"

          RT_CONTROL="Unknown"
          [ -f "$GPU_PATH/power/control" ] && RT_CONTROL="$(cat "$GPU_PATH/power/control")"

          echo "Status:          ONLINE"
          echo "PCI Address:     $GPU_PCI"
          echo "PCI Power State: $PWR_STATE"
          echo "Runtime PM:      $RT_STATUS (control: $RT_CONTROL)"

          if [ -f "/proc/driver/nvidia/gpus/$GPU_PCI/power" ]; then
            D3_LINE=$(grep "Runtime D3 status" "/proc/driver/nvidia/gpus/$GPU_PCI/power" 2>/dev/null || true)
            if [ -n "$D3_LINE" ]; then
              echo "Driver RTD3:    ''${D3_LINE#*:}"
            fi
          fi

          if has_active_clients; then
            echo "Active Clients:"
            list_active_clients
          else
            echo "Active Clients:  None (idle)"
          fi
        fi
        ;;

      off)
        if [ "$EUID" -ne 0 ]; then
          exec sudo "$0" "$@"
        fi

        if [ ! -d "$GPU_PATH" ]; then
          echo "NVIDIA GPU is already powered off (detached from PCIe bus)."
          exit 0
        fi

        if has_active_clients && [ "''${2:-}" != "--force" ]; then
          echo "ERROR: Cannot turn off NVIDIA GPU while active processes are using it:" >&2
          list_active_clients >&2
          echo "Close these applications or run 'nvidia-power off --force'." >&2
          exit 1
        fi

        echo "Detaching NVIDIA GPU ($GPU_PCI)..."
        echo 1 > "$GPU_PATH/remove"

        if [ -f "$ROOT_PORT_PATH/power/control" ]; then
          echo auto > "$ROOT_PORT_PATH/power/control"
        fi
        echo "NVIDIA GPU is now detached and powered off (0W)."
        ;;

      on)
        if [ "$EUID" -ne 0 ]; then
          exec sudo "$0" "$@"
        fi

        if [ -d "$GPU_PATH" ]; then
          echo "NVIDIA GPU is already attached."
        else
          echo "Rescanning PCIe bus..."
          echo 1 > /sys/bus/pci/rescan
          for _ in $(seq 1 30); do
            if [ -d "$GPU_PATH" ]; then
              break
            fi
            sleep 0.1
          done
        fi

        if [ -d "$GPU_PATH" ]; then
          [ -f "$GPU_PATH/power/control" ] && echo auto > "$GPU_PATH/power/control"
          [ -f "$ROOT_PORT_PATH/power/control" ] && echo auto > "$ROOT_PORT_PATH/power/control"
          echo "NVIDIA GPU is online and runtime PM is set to auto."
        else
          echo "ERROR: Failed to redetect NVIDIA GPU after PCIe rescan." >&2
          exit 1
        fi
        ;;

      auto)
        if [ "$EUID" -ne 0 ]; then
          exec sudo "$0" "$@"
        fi

        if [ ! -d "$GPU_PATH" ]; then
          echo "ERROR: NVIDIA GPU is detached. Run 'nvidia-power on' first." >&2
          exit 1
        fi

        [ -f "$GPU_PATH/power/control" ] && echo auto > "$GPU_PATH/power/control"
        [ -f "$ROOT_PORT_PATH/power/control" ] && echo auto > "$ROOT_PORT_PATH/power/control"
        echo "Set runtime PM control to auto for NVIDIA GPU and PCIe Root Port."
        ;;

      *)
        usage
        ;;
    esac
  '';
in {
  environment.systemPackages = [
    powerProfileBackend
    nvidiaPower
    (pkgs.writeShellScriptBin "nvidia-offload" ''
      if [ ! -d /sys/bus/pci/devices/0000:02:00.0 ]; then
        echo "NVIDIA GPU is detached/off. Rescanning and bringing online..." >&2
        ${nvidiaPower}/bin/nvidia-power on >&2
      fi
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json
      export VK_DRIVER_FILES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json
      exec "$@"
    '')
  ];

  security.sudo.extraRules = [
    {
      users = ["qylad"];
      commands = [
        {
          command = "${powerProfileBackend}/bin/power-profile-backend";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/power-profile-backend";
          options = ["NOPASSWD"];
        }
        {
          command = "${nvidiaPower}/bin/nvidia-power";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/nvidia-power";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # Baseline kernel parameters for PCIe and display power saving (beneficial on both AC and Battery)
  boot.kernelParams = [
    # Force PCIe Active State Power Management across NVMe SSD, Wi-Fi, and PCIe root ports
    "pcie_aspm=force"
    "pcie_aspm.policy=powersupersave"

    # Intel UHD Graphics power saving (Framebuffer Compression & Panel Self Refresh)
    "i915.enable_fbc=1"
    "i915.enable_psr=1"
  ];

  # Defer kernel dirty page writebacks to keep NVMe SSD in low-power sleep (APST) instead of waking every 5s
  boot.kernel.sysctl = {
    "vm.dirty_writeback_centisecs" = 6000;
    "vm.laptop_mode" = 5;
  };

  # Powertop auto-tuning at boot for idle peripherals
  powerManagement.powertop.enable = true;

  # Enable fine-grained PCIe runtime power management (RTD3/D3cold) for Turing dGPU (GTX 1650)
  # Drops idle power consumption from ~3W (D3hot/active) to 0W (D3cold) when not running offloaded tasks
  hardware.nvidia = {
    # Turing GPUs (GTX 1650 / TU117) require proprietary kernel modules and disabling GSP firmware
    # for RTD3 / D3cold; with GSP enabled, the driver reports "Runtime D3 status: Not supported".
    open = lib.mkForce false;
    gsp.enable = lib.mkForce false;

    powerManagement = {
      enable = true;
      finegrained = true;
    };

    prime.offload = {
      # Use our custom wrapper above which also specifies EGL and Vulkan ICD variables
      enableOffloadCmd = lib.mkForce false;
    };
  };

  boot.extraModprobeConfig = ''
    options nvidia NVreg_TemporaryFilePath=/var/tmp
    options nvidia NVreg_EnableGpuFirmware=0
    options snd_hda_intel power_save=1 power_save_controller=Y
  '';

  # PCIe runtime PM rules:
  # 1. Nixpkgs' default rule only triggers on ACTION=="bind", which misses boot/coldplug ACTION=="add".
  # 2. Both the discrete GPU and its parent PCIe Root Port (0000:00:1c.4) must have power/control
  #    set to "auto" for the link to transition into D3cold (0W).
  services.udev.extraRules = ''
    # Enable runtime PM for PCIe Root Port and PCI bridges
    ACTION=="add|bind", SUBSYSTEM=="pci", ATTR{class}=="0x060400", TEST=="power/control", ATTR{power/control}="auto"
    ACTION=="add|bind", SUBSYSTEM=="pci", KERNEL=="0000:00:1c.4", TEST=="power/control", ATTR{power/control}="auto"

    # Enable runtime PM for NVIDIA GPU
    ACTION=="add|bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", TEST=="power/control", ATTR{power/control}="auto"
  '';

  # Thermal management daemon to proactively handle thermal zones
  services.thermald.enable = true;

  # Power limits tailored to this MSI chassis and 60W power budget
  services.throttled = {
    enable = true;
    extraConfig = ''
      [GENERAL]
      Enabled: True
      Sysfs_Power_Path: /sys/class/power_supply/ADP1/online
      Autoreload: True

      [AC]
      Update_Rate_s: 5
      PL1_Tdp_W: 25
      PL1_Duration_s: 60
      PL2_Tdp_W: 25
      PL2_Duration_S: 60
      Trip_Temp_C: 85
      cTDP: 0
      Disable_BDPROCHOT: False

      [BATTERY]
      Update_Rate_s: 30
      PL1_Tdp_W: 15
      PL1_Duration_s: 30
      PL2_Tdp_W: 18
      PL2_Duration_S: 10
      Trip_Temp_C: 80
      cTDP: 0
      Disable_BDPROCHOT: False

      [UNDERVOLT.AC]
      CORE: -70
      GPU: -40
      CACHE: -70
      UNCORE: -40
      ANALOGIO: 0

      [UNDERVOLT.BATTERY]
      CORE: -70
      GPU: -40
      CACHE: -70
      UNCORE: -40
      ANALOGIO: 0
    '';
  };
}
