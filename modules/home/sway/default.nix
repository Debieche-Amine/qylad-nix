{
  config,
  lib,
  pkgs,
  ...
}: let
  modifier = "Mod4";
  terminal = "kitty";
  menu = "rofi -show drun";
  scripts = import ./scripts.nix {inherit pkgs;};

  anchors = [
    {
      key = "a";
      workspace = "a:0";
    }
    {
      key = "z";
      workspace = "z:0";
    }
    {
      key = "e";
      workspace = "e:0";
    }
    {
      key = "i";
      workspace = "i:0";
    }
    {
      key = "o";
      workspace = "o:0";
    }
    {
      key = "p";
      workspace = "p:0";
    }
  ];

  anchorBindings =
    lib.foldl'
    (bindings: anchor:
      bindings
      // {
        "${modifier}+${anchor.key}" = "workspace ${anchor.workspace}";
        "${modifier}+Shift+${anchor.key}" = "move container to workspace ${anchor.workspace}";
      })
    {}
    anchors;
in {
  imports = [
    ./idle.nix
    ./waybar.nix
  ];

  wayland.systemd.target = "sway-session.target";

  home.packages = with pkgs; [
    rofi
    kitty
    swaylock
    grim
    slurp
    wl-clipboard
    brightnessctl
    playerctl
    wireplumber
    jq
    libnotify
    wev
    scripts.laneWorkspace
    scripts.waybarLane
    scripts.screenshotFull
    scripts.screenshotRegion
    scripts.lock
    scripts.waybarNetUsage
    scripts.waybarNetReset
    scripts.waybarMic
    scripts.batteryNotify
  ];
  programs.swayimg.enable = true;
  services.swaync.enable = true;

  wayland.windowManager.sway = {
    enable = true;
    checkConfig = true;
    package = pkgs.sway;
    systemd.enable = true;
    xwayland = true;
    wrapperFeatures.gtk = true;

    config = {
      modifier = modifier;
      terminal = terminal;
      menu = menu;
      bars = [];
      defaultWorkspace = "workspace a:0";
      startup = [
        {command = "${terminal} fish --init-command='cd nixos'";}
        {command = "${terminal} fish --init-command='cd nixos'";}
        {command = "battery-notify";}
      ];

      fonts = {
        names = ["Maple Mono" "FiraCode Nerd Font"];
        size = 10.0;
      };

      gaps = {
        inner = 0;
        outer = 0;
      };

      window = {
        border = 1;
        titlebar = false;
      };

      floating = {
        border = 2;
        titlebar = true; # test
        criteria = [
          {
            title = "Steam - Update News";
          }
          {
            class = "Pavucontrol";
          }
        ];
      };

      colors.focused = {
        background = "#C96A1B";
        border = "#E58A2B";
        childBorder = "#C96A1B";
        indicator = "#FFB347";
        text = "#FFFFFF";
      };

      input = {
        # "*" = {
        # };
        "type:keyboard" = {
          # repeat_delay =
          # repeat_rate =
          xkb_layout = "fr,ara";
          xkb_variant = "nodeadkeys,azerty";
          xkb_options = "caps:escape,grp:rctrl_rshift_toggle";
          xkb_numlock = "enabled";
          xkb_capslock = "disabled";
        };

        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
          drag = "enabled";
          drag_lock = "enabled";
          dwt = "enabled";
        };
        "type:pointer" = {
          accel_profile = "flat";
          pointer_accel = "0";
        };
      };

      output = {
        "*" = {
          bg = "#1d2021 solid_color";
        };
      };

      modes = {
        resize = {
          "h" = "resize shrink width 20 px";
          "j" = "resize grow height 20 px";
          "k" = "resize shrink height 20 px";
          "l" = "resize grow width 20 px";
          "Left" = "resize shrink width 20 px";
          "Down" = "resize grow height 20 px";
          "Up" = "resize shrink height 20 px";
          "Right" = "resize grow width 20 px";
          "Return" = "mode default";
          "Escape" = "mode default";
        };
      };

      keybindings =
        {
          "${modifier}+Return" = "exec ${terminal}";
          "${modifier}+d" = "exec ${menu}";
          "${modifier}+q" = "kill";

          "${modifier}+h" = "focus left";
          "${modifier}+j" = "focus down";
          "${modifier}+k" = "focus up";
          "${modifier}+l" = "focus right";
          "${modifier}+Left" = "focus left";
          "${modifier}+Down" = "focus down";
          "${modifier}+Up" = "focus up";
          "${modifier}+Right" = "focus right";

          "${modifier}+Alt+h" = "move left";
          "${modifier}+Alt+j" = "move down";
          "${modifier}+Alt+k" = "move up";
          "${modifier}+Alt+l" = "move right";
          "${modifier}+Alt+Left" = "move left";
          "${modifier}+Alt+Down" = "move down";
          "${modifier}+Alt+Up" = "move up";
          "${modifier}+Alt+Right" = "move right";

          "${modifier}+Ctrl+h" = "exec ${scripts.laneWorkspace}/bin/sway-lane-workspace workspace -1";
          "${modifier}+Ctrl+l" = "exec ${scripts.laneWorkspace}/bin/sway-lane-workspace workspace 1";
          "${modifier}+Ctrl+Left" = "exec ${scripts.laneWorkspace}/bin/sway-lane-workspace workspace -1";
          "${modifier}+Ctrl+Right" = "exec ${scripts.laneWorkspace}/bin/sway-lane-workspace workspace 1";
          "${modifier}+Ctrl+Shift+h" = "exec ${scripts.laneWorkspace}/bin/sway-lane-workspace move -1";
          "${modifier}+Ctrl+Shift+l" = "exec ${scripts.laneWorkspace}/bin/sway-lane-workspace move 1";
          "${modifier}+Ctrl+Shift+Left" = "exec ${scripts.laneWorkspace}/bin/sway-lane-workspace move -1";
          "${modifier}+Ctrl+Shift+Right" = "exec ${scripts.laneWorkspace}/bin/sway-lane-workspace move 1";

          "${modifier}+b" = "splith";
          "${modifier}+v" = "splitv";
          "${modifier}+s" = "layout stacking";
          "${modifier}+w" = "layout tabbed";
          "${modifier}+t" = "layout toggle split";
          "${modifier}+f" = "fullscreen toggle";
          "${modifier}+Shift+space" = "floating toggle";
          "${modifier}+space" = "focus mode_toggle";
          "${modifier}+r" = "mode resize";

          "${modifier}+Shift+twosuperior" = "move scratchpad";
          "${modifier}+twosuperior" = "scratchpad show";

          "${modifier}+Shift+c" = "reload";
          "${modifier}+Shift+r" = "restart";
          "${modifier}+Shift+x" = "exec swaynag -t warning -m 'Exit Sway?' -B 'Yes' 'swaymsg exit'";

          "${modifier}+Escape" = "exec ${scripts.lock}/bin/sway-lock";
          "Print" = "exec ${scripts.screenshotFull}/bin/sway-screenshot-full";
          "${modifier}+Print" = "exec ${scripts.screenshotRegion}/bin/sway-screenshot-region";

          "XF86AudioRaiseVolume" = "exec ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          "XF86AudioLowerVolume" = "exec ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          "XF86AudioMute" = "exec ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86AudioMicMute" = "exec ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && pkill -RTMIN+9 waybar";
          "XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
          "XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl next";
          "XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl previous";

          "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%+";
          "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
        }
        // anchorBindings;
    };
  };

  gtk = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra; # if using Adwaita
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };
}
