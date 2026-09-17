{
  config,
  lib,
  pkgs,
  ...
}: let
  scripts = import ./scripts.nix {inherit pkgs;};
  modules = import ./modules.nix {inherit config lib pkgs scripts;};
  style = import ./style.nix;
in {
  home.packages = [
    scripts.waybarLane
    scripts.waybarScratchpad
    scripts.waybarNetUsage
    scripts.waybarNetReset
    scripts.waybarMic
    scripts.waybarRecorder
    pkgs.waybar
    pkgs.socat
    pkgs.jq
  ];

  programs.waybar = {
    enable = true;
    package = pkgs.waybar;
    systemd = {
      enable = true;
      targets = ["graphical-session.target"];
    };
    settings.mainBar = modules;
    style = style;
  };

  systemd.user.services.waybar = {
    Unit = {
      StartLimitIntervalSec = 30;
      StartLimitBurst = 10;
    };
    Service.RestartSec = 2;
  };
}
