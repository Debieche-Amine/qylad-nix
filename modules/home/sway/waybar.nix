{pkgs, ...}: let
  scripts = import ./scripts.nix {inherit pkgs;};
in {
  home.packages = [pkgs.playerctl];
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;
    systemd = {
      enable = true;
      target = "sway-session.target";
    };

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 8;
        modules-left = [
          "custom/lane"
          "sway/workspaces"
          "sway/mode"
        ];
        modules-center = [
          "clock"
          # -- test --
          "sway/scratchpad"
          "sway/language"
          "cpu"
          "memory"
          "disk"
          "temperature"
          # "idle_inhibitor"
          "mpris"
          # -- end test --
        ];
        modules-right = [
          "tray"
          "custom/netusage"
          "network"
          # "bluetooth"
          "backlight"
          "pulseaudio"
          "custom/mic"
          "battery"
        ];
        "custom/mic" = {
          exec = "waybar-mic";
          return-type = "json";
          interval = 10;
          signal = 9;
          on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && pkill -RTMIN+9 waybar";
        };
        "custom/netusage" = {
          exec = "${scripts.waybarNetUsage}/bin/waybar-net-usage";
          interval = 1;
          return-type = "json";

          on-click = "${scripts.waybarNetReset}/bin/waybar-net-reset";
        };

        # -- test --
        "sway/scratchpad" = {
          format = "󰖯 {count}";
          show-empty = false;
          tooltip = true;
          tooltip-format = "{app}: {title}";
        };

        "sway/language" = {
          format = "󰌌 {short}";
        };

        cpu = {
          format = " {usage}%";
          interval = 2;
        };

        memory = {
          format = " {percentage}%";
          interval = 5;
        };

        temperature = {
          thermal-zone = 3;
          critical-threshold = 80;
          format = " {temperatureC}°C";
        };

        mpris = {
          format = "{player_icon}  {artist} - {title}";
          format-paused = "  {artist} - {title}";
          format-stopped = "No music";

          player-icons = {
            default = "";
            spotify = "";
            firefox = "";
            vlc = "󰕼";
          };

          "status-icons" = {
            playing = "";
            paused = "";
            stopped = "";
          };
          tooltip-format = "{player}\n{artist} - {title}\n{album}";
        };

        disk = {
          format = "󰋊 {percentage_used}%";
          path = "/";
        };

        backlight = {
          format = "󰃠 {percent}%";
          reverse-scrolling = true;
        };

        bluetooth = {
          format = " on";
          format-disabled = "󰂲 off";
          format-connected = " {num_connections}";
          tooltip-format = "{controller_alias}\t{controller_address}";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󰈈";
            deactivated = "󰈉";
          };
        };

        # -- end test --

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = false;
          format = "{name}";
        };

        "custom/lane" = {
          exec = "${scripts.waybarLane}/bin/sway-waybar-lane";
          return-type = "json";
          format = "{}";
        };

        "sway/mode" = {
          format = "{}";
        };

        tray = {
          spacing = 8;
        };

        clock = {
          format = "{:%a %d %b  %H:%M}";
          tooltip-format = "{:%Y-%m-%d}";
        };

        network = {
          format-wifi = "  {essid} {signalStrength}%";
          format-ethernet = "󰈀  wired";
          format-disconnected = "󰖪  offline";
          tooltip-format = "{ifname}: {ipaddr}";
        };

        # pulseaudio = {
        #   format = "  {volume}%";
        #   format-muted = "󰝟 muted";
        #   scroll-step = 5;
        # };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 Muted";

          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "󰋎";
            phone = "";
            portable = "";
            car = "";
            default = ["" "" ""];
          };

          on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
          on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-middle-click = "playerctl play-pause";

          on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+";
          on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-";

          tooltip = true;
          tooltip-format = "{desc}\n{volume}%";

          reverse-scrolling = true;
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}  {capacity}%";
          format-charging = "󱐋 {capacity}%+";
          format-plugged = " {capacity}%";
          format-icons = ["" "" "" "" ""];
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "Maple Mono", "FiraCode Nerd Font", monospace;
        font-size: 12px;
        min-height: 0;
      }

      window#waybar {
        background: #1d2021;
        color: #ebdbb2;
      }

      #workspaces button {
        padding: 0 8px;
        color: #a89984;
      }

      #workspaces button.focused,
      #workspaces button.active {
        color: #1d2021;
        background: #fabd2f;
      }

      #mode {
        color: #1d2021;
        background: #fb4934;
        padding: 0 8px;
      }waybar

      #custom-lane {
        color: #1d2021;
        background: #8ec07c;
        font-weight: bold;
        padding: 0 10px;
      }

      #custom-lane.other {
        color: #ebdbb2;
        background: #3c3836;
      }

      #clock,
      #tray,
      #network,
      #custom-netusage {
        padding: 0 10px;
      }
      #pulseaudio,
      #battery {
        padding: 0 10px;
      }

      #battery.warning {
        color: #fabd2f;
      }

      #battery.critical {
        color: #fb4934;
      }
    '';
  };
}
