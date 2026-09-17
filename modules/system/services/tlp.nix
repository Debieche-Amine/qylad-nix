{pkgs, ...}: {
  # Ensure power-profiles-daemon is disabled, as it conflicts with TLP
  # services.power-profiles-daemon.enable = false;
  #
  # services.tlp = {
  #   enable = true;
  #   settings = {
  #     # Treat AC like battery to keep power draw low
  #     CPU_BOOST_ON_AC = 0;
  #     CPU_HWP_DYN_BOOST_ON_AC = 0;
  #
  #     # Force low-power states
  #     # PLATFORM_PROFILE_ON_AC = "low-power";
  #     # CPU_SCALING_GOVERNOR_ON_AC = "powersave";
  #     # CPU_ENERGY_PERF_POLICY_ON_AC = "power";
  #
  #     # Limit max CPU frequency to base clock
  #     CPU_SCALING_MAX_FREQ_ON_AC = 2200000;
  #   };
  # };
  # services.throttled = {
  #   enable = true;
  #   extraConfig =
  #     "\n\n"
  #     + ''
  #       [GENERAL]
  #       Update_Rate_s = 5
  #
  #       [AC]
  #       Update_Core_Watts = True
  #       PL1_Tdp_W = 20
  #       PL1_Duration_s = 28
  #       PL2_Tdp_W = 25
  #       PL2_Duration_s = 0.002
  #
  #       [BATTERY]
  #       Update_Core_Watts = True
  #       PL1_Tdp_W = 20
  #       PL1_Duration_s = 28
  #       PL2_Tdp_W = 25
  #       PL2_Duration_s = 0.002
  #     '';
  # };
}
