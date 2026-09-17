{pkgs, ...}: {
  services.hypridle = {
    enable = true;
    systemdTarget = "graphical-session.target";
    settings = {
      general = {
        lock_cmd = "${pkgs.procps}/bin/pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
        before_sleep_cmd = "${pkgs.procps}/bin/pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
        after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
      };

      listener = [
        {
          timeout = 540; # 9 minutes: dim display
          on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 20%-";
          on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
        }
        {
          timeout = 600; # 10 minutes: lock session
          on-timeout = "${pkgs.procps}/bin/pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
        }
        {
          timeout = 660; # 11 minutes (1 min after lock): turn off display (DPMS)
          on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
          on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
