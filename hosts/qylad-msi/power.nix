{pkgs, ...}: let
  powerProfileBackend = pkgs.writeShellScriptBin "power-profile-backend" (builtins.readFile ../../modules/home/hyprland/power-profile/backend.sh);
in {
  environment.systemPackages = [powerProfileBackend];

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
  # Drops idle power consumption from ~3W to 0W when not running offloaded tasks
  hardware.nvidia.powerManagement = {
    enable = true;
    finegrained = true;
  };

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
