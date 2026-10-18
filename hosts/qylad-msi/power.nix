{
  pkgs,
  lib,
  ...
}: let
  powerProfileBackend = pkgs.writeShellScriptBin "power-profile-backend" (builtins.readFile ../../modules/home/hyprland/power-profile/backend.sh);
in {
  environment.systemPackages = [
    powerProfileBackend
    (pkgs.writeShellScriptBin "nvidia-offload" ''
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
      ];
    }
  ];

  # High performance governor for instant responsiveness
  powerManagement.cpuFreqGovernor = "performance";

  # Enable fine-grained PCIe runtime power management (RTD3/D3cold) for Turing dGPU (GTX 1650)
  # Drops idle power consumption from ~3W (D3hot/active) to 0W (D3cold) when not running offloaded tasks
  hardware.nvidia = {
    # Turing GPUs (GTX 1650 / TU117) require proprietary kernel modules for RTD3 / D3cold;
    # the open kernel modules report "Runtime D3 status: Not supported" on Turing.
    open = lib.mkForce false;

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
      CORE: 0
      GPU: 0
      CACHE: 0
      UNCORE: 0
      ANALOGIO: 0

      [UNDERVOLT.BATTERY]
      CORE: 0
      GPU: 0
      CACHE: 0
      UNCORE: 0
      ANALOGIO: 0
    '';
  };
}
