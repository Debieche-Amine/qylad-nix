{
  config,
  pkgs,
  ...
}: let
  colors = config.lib.stylix.colors;

  swayosdStyle = pkgs.writeText "swayosd-style.css" ''
    @define-color base00 #${colors.base00};
    @define-color base01 #${colors.base01};
    @define-color base02 #${colors.base02};
    @define-color base03 #${colors.base03};
    @define-color base04 #${colors.base04};
    @define-color base05 #${colors.base05};
    @define-color base08 #${colors.base08};
    @define-color base09 #${colors.base09};
    @define-color base0A #${colors.base0A};
    @define-color base0B #${colors.base0B};
    @define-color base0C #${colors.base0C};
    @define-color base0D #${colors.base0D};
    @define-color base0E #${colors.base0E};

    window#osd {
      border-radius: 20px;
      border: 1px solid alpha(@base0D, 0.45);
      background: alpha(@base00, 0.82);
      box-shadow: 0 10px 30px alpha(@base00, 0.65), 0 0 15px alpha(@base0D, 0.18);
    }

    window#osd #container {
      margin: 14px 22px;
    }

    window#osd image,
    window#osd label {
      color: @base05;
      font-family: "Maple Mono NF", monospace;
      font-size: 13px;
      font-weight: bold;
    }

    window#osd progressbar:disabled,
    window#osd image:disabled {
      opacity: 0.55;
      color: @base08;
    }

    window#osd progressbar,
    window#osd segmentedprogress {
      min-height: 8px;
      border-radius: 999px;
      background: transparent;
      border: none;
    }

    window#osd trough,
    window#osd segment {
      min-height: inherit;
      border-radius: inherit;
      border: 1px solid alpha(@base05, 0.08);
      background: alpha(@base02, 0.75);
    }

    window#osd progress,
    window#osd segment.active {
      min-height: inherit;
      border-radius: inherit;
      border: none;
      background: linear-gradient(90deg, @base0D, @base0E);
    }

    window#osd progressbar:disabled progress {
      background: @base08;
    }

    window#osd segment {
      margin-left: 8px;
    }

    window#osd segment:first-child {
      margin-left: 0;
    }
  '';
  batteryNotify = pkgs.writeShellScriptBin "battery-notify" ''
    set -eu

    notified_levels=""
    levels=(50 35 25 20 15 10 7 5 4 3 2 1)

    while true; do
      battery=""
      for path in /sys/class/power_supply/BAT*; do
        [ -r "$path/capacity" ] && [ -r "$path/status" ] || continue
        battery="$path"
        break
      done

      if [ -z "$battery" ]; then
        ${pkgs.coreutils}/bin/sleep 300
        continue
      fi

      capacity="$(< "$battery/capacity")"
      status="$(< "$battery/status")"

      if [ "$status" = Discharging ]; then
        if [ "$capacity" -le 1 ]; then
          ${pkgs.libnotify}/bin/notify-send -u critical "Battery Critical" "Battery is at $capacity%. Shutting down immediately to protect hardware..."
          ${pkgs.coreutils}/bin/sleep 2
          ${pkgs.systemd}/bin/systemctl poweroff
          exit 0
        fi

        for level in "''${levels[@]}"; do
          if [ "$capacity" -le "$level" ]; then
            if [[ " $notified_levels " != *" $level "* ]]; then
              ${pkgs.libnotify}/bin/notify-send -u critical "Low Battery" "Battery is at $capacity% (below $level%)."
              for higher in "''${levels[@]}"; do
                [ "$higher" -ge "$level" ] && notified_levels="$notified_levels $higher"
              done
              break
            fi
          fi
        done
      else
        notified_levels=""
      fi

      ${pkgs.coreutils}/bin/sleep 60
    done
  '';
in {
  services.hyprpolkitagent.enable = true;

  services.swayosd = {
    enable = true;
    stylePath = swayosdStyle;
    topMargin = 0.86;
  };

  xdg.configFile."swayosd/config.toml".text = ''
    [server]
    min_brightness = 0
    show_percentage = true
  '';

  home.packages = with pkgs; [
    batteryNotify
  ];

  systemd.user.services = {
    battery-notify = {
      Unit = {
        Description = "Desktop battery threshold notifications";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = "${batteryNotify}/bin/battery-notify";
        Restart = "on-failure";
        RestartSec = 10;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
