{pkgs, ...}: let
  scripts = import ./scripts.nix {inherit pkgs;};
in {
  services.swayidle = {
    enable = true;
    package = pkgs.swayidle;
    timeouts = [
      {
        timeout = 570;
        command = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10%";
        resumeCommand = "${pkgs.brightnessctl}/bin/brightnessctl -r";
      }
      {
        timeout = 600;
        command = "${scripts.lock}/bin/sway-lock";
      }
      {
        timeout = 620;
        command = ''${pkgs.sway}/bin/swaymsg "output * power off"'';
        resumeCommand = ''${pkgs.sway}/bin/swaymsg "output * power on"'';
      }
    ];
    events = {
      before-sleep = "${scripts.lock}/bin/sway-lock";
    };
    systemdTarget = "sway-session.target";
  };
}
