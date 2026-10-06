{
  config,
  lib,
  pkgs,
  ...
}: let
  modifier = "SUPER";
  terminal = "${pkgs.kitty}/bin/kitty";
  uwsm = lib.getExe pkgs.uwsm;
  menu = "${uwsm} app -- ${pkgs.rofi}/bin/rofi -show combi -run-command '${uwsm} app -- {cmd}'";
  logoutMenu = "${config.programs.wlogout.package}/bin/wlogout --buttons-per-row 4 --column-spacing 16 --row-spacing 16 --margin 96";

  scripts = import ./scripts.nix {inherit pkgs;};
  anchorBindings = import ./anchors.nix {inherit lib modifier;};
in {
  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    tesseract
    brightnessctl
    playerctl
    wireplumber
    jq
    libnotify
    wev
    hyprpicker
    pavucontrol
    networkmanagerapplet
    wl-screenrec
    swayosd
    scripts.restrictedMode
    scripts.terminalCwd
    scripts.laneWorkspace
    scripts.toggleWorkspaceLayout
    scripts.screenshotFull
    scripts.screenshotRegion
    scripts.screenshotOcr
    scripts.screenrecordToggle
    scripts.cgroupMenu
  ];

  wayland.windowManager.hyprland = {
    settings = {
      bind =
        [
          "${modifier}, RETURN, exec, ${uwsm} app -- ${terminal}"
          "${modifier} SHIFT, RETURN, exec, ${scripts.terminalCwd}/bin/hypr-terminal-cwd"
          "${modifier} SHIFT, G, exec, ${scripts.restrictedMode}/bin/hypr-restricted-mode enter"
          "${modifier}, D, exec, ${menu}"
          "${modifier}, C, exec, hypr-control-panel"
          "${modifier}, E, exec, power-profile-gui"
          "${modifier}, Q, killactive"

          "${modifier}, H, movefocus, l"
          "${modifier}, J, movefocus, d"
          "${modifier}, K, movefocus, u"
          "${modifier}, L, movefocus, r"
          "${modifier}, left, movefocus, l"
          "${modifier}, down, movefocus, d"
          "${modifier}, up, movefocus, u"
          "${modifier}, right, movefocus, r"

          "${modifier} ALT, H, movewindoworgroup, l"
          "${modifier} ALT, J, movewindoworgroup, d"
          "${modifier} ALT, K, movewindoworgroup, u"
          "${modifier} ALT, L, movewindoworgroup, r"
          "${modifier} ALT, left, movewindoworgroup, l"
          "${modifier} ALT, down, movewindoworgroup, d"
          "${modifier} ALT, up, movewindoworgroup, u"
          "${modifier} ALT, right, movewindoworgroup, r"

          "${modifier} ALT SHIFT, H, swapwindow, l"
          "${modifier} ALT SHIFT, J, swapwindow, d"
          "${modifier} ALT SHIFT, K, swapwindow, u"
          "${modifier} ALT SHIFT, L, swapwindow, r"
          "${modifier} ALT SHIFT, left, swapwindow, l"
          "${modifier} ALT SHIFT, down, swapwindow, d"
          "${modifier} ALT SHIFT, up, swapwindow, u"
          "${modifier} ALT SHIFT, right, swapwindow, r"

          "${modifier} CTRL, H, exec, ${scripts.laneWorkspace}/bin/hypr-lane-workspace workspace -1"
          "${modifier} CTRL, L, exec, ${scripts.laneWorkspace}/bin/hypr-lane-workspace workspace 1"
          "${modifier} CTRL, left, exec, ${scripts.laneWorkspace}/bin/hypr-lane-workspace workspace -1"
          "${modifier} CTRL, right, exec, ${scripts.laneWorkspace}/bin/hypr-lane-workspace workspace 1"
          "${modifier} CTRL SHIFT, H, exec, ${scripts.laneWorkspace}/bin/hypr-lane-workspace move -1"
          "${modifier} CTRL SHIFT, L, exec, ${scripts.laneWorkspace}/bin/hypr-lane-workspace move 1"
          "${modifier} CTRL SHIFT, left, exec, ${scripts.laneWorkspace}/bin/hypr-lane-workspace move -1"
          "${modifier} CTRL SHIFT, right, exec, ${scripts.laneWorkspace}/bin/hypr-lane-workspace move 1"

          "${modifier}, B, layoutmsg, preselect r"
          "${modifier} SHIFT, V, layoutmsg, preselect d"
          "${modifier}, S, togglegroup"
          "${modifier}, W, changegroupactive, f"
          "${modifier}, T, layoutmsg, togglesplit"
          "${modifier}, M, exec, ${scripts.toggleWorkspaceLayout}/bin/hypr-toggle-workspace-layout"
          "${modifier}, F, fullscreen, 0"
          "${modifier} SHIFT, SPACE, togglefloating"
          "${modifier}, SPACE, cyclenext, floating"
          "${modifier}, R, submap, resize"

          "${modifier} SHIFT, twosuperior, movetoworkspacesilent, special:scratchpad"
          "${modifier}, twosuperior, togglespecialworkspace, scratchpad"

          "${modifier} SHIFT, ampersand, movetoworkspacesilent, special:s1"
          "${modifier}, ampersand, togglespecialworkspace, s1"
          "${modifier} SHIFT, 1, movetoworkspacesilent, special:s1"
          "${modifier}, 1, togglespecialworkspace, s1"

          "${modifier} SHIFT, eacute, movetoworkspacesilent, special:s2"
          "${modifier}, eacute, togglespecialworkspace, s2"
          "${modifier} SHIFT, 2, movetoworkspacesilent, special:s2"
          "${modifier}, 2, togglespecialworkspace, s2"

          "${modifier} SHIFT, quotedbl, movetoworkspacesilent, special:s3"
          "${modifier}, quotedbl, togglespecialworkspace, s3"
          "${modifier} SHIFT, 3, movetoworkspacesilent, special:s3"
          "${modifier}, 3, togglespecialworkspace, s3"

          "${modifier} SHIFT, C, exec, ${pkgs.hyprland}/bin/hyprctl reload"
          "${modifier} SHIFT, R, exec, ${pkgs.hyprland}/bin/hyprctl reload"
          "${modifier} SHIFT, X, exec, ${uwsm} app -- ${logoutMenu}"

          "${modifier}, ESCAPE, exec, ${pkgs.hyprlock}/bin/hyprlock"
          ", PRINT, exec, ${scripts.screenshotFull}/bin/hypr-screenshot-full"
          "${modifier}, PRINT, exec, ${scripts.screenshotRegion}/bin/hypr-screenshot-region"
          "${modifier} ALT, PRINT, exec, ${scripts.screenshotOcr}/bin/hypr-screenshot-ocr"
          "${modifier} SHIFT, PRINT, exec, ${pkgs.hyprpicker}/bin/hyprpicker -a -s 1.5"
          "${modifier} CTRL, P, exec, ${pkgs.hyprpicker}/bin/hyprpicker -a -s 1.5"
          "${modifier}, N, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw"
          "${modifier} ALT, N, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client --hide-latest -sw"

          "${modifier} CTRL, PRINT, exec, ${scripts.screenrecordToggle}/bin/hypr-screenrecord-toggle full"
          "${modifier} CTRL SHIFT, PRINT, exec, ${scripts.screenrecordToggle}/bin/hypr-screenrecord-toggle region"

          ", XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
          ", XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next"
          ", XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous"
        ]
        ++ anchorBindings;

      binde = [
        "${modifier} SHIFT, H, resizeactive, -20 0"
        "${modifier} SHIFT, J, resizeactive, 0 20"
        "${modifier} SHIFT, K, resizeactive, 0 -20"
        "${modifier} SHIFT, L, resizeactive, 20 0"
        "${modifier} SHIFT, left, resizeactive, -20 0"
        "${modifier} SHIFT, down, resizeactive, 0 20"
        "${modifier} SHIFT, up, resizeactive, 0 -20"
        "${modifier} SHIFT, right, resizeactive, 20 0"

        ", XF86AudioRaiseVolume, exec, ${pkgs.swayosd}/bin/swayosd-client --output-volume raise"
        ", XF86AudioLowerVolume, exec, ${pkgs.swayosd}/bin/swayosd-client --output-volume lower"
        ", XF86MonBrightnessUp, exec, ${pkgs.swayosd}/bin/swayosd-client --brightness raise --min-brightness 0"
        ", XF86MonBrightnessDown, exec, ${pkgs.swayosd}/bin/swayosd-client --brightness lower --min-brightness 0"
      ];

      bindl = [
        ", XF86AudioMute, exec, ${pkgs.swayosd}/bin/swayosd-client --output-volume mute-toggle"
        ", XF86AudioMicMute, exec, ${pkgs.swayosd}/bin/swayosd-client --input-volume mute-toggle && ${pkgs.procps}/bin/pkill -RTMIN+9 waybar"
        ", switch:on:Lid Switch, exec, ${pkgs.procps}/bin/pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock"
      ];

      bindm = [
        "${modifier}, mouse:272, movewindow"
        "${modifier}, mouse:273, resizewindow"
      ];
    };

    submaps.resize.settings = {
      binde = [
        ", H, resizeactive, -20 0"
        ", J, resizeactive, 0 20"
        ", K, resizeactive, 0 -20"
        ", L, resizeactive, 20 0"
        ", left, resizeactive, -20 0"
        ", down, resizeactive, 0 20"
        ", up, resizeactive, 0 -20"
        ", right, resizeactive, 20 0"
      ];
      bind = [
        ", RETURN, submap, reset"
        ", ESCAPE, submap, reset"
        "${modifier}, R, submap, reset"
      ];
    };

    submaps.restricted.settings = {
      bind = [
        "${modifier} SHIFT, G, exec, ${scripts.restrictedMode}/bin/hypr-restricted-mode exit"
        "${modifier}, H, movefocus, l"
        "${modifier}, J, movefocus, d"
        "${modifier}, K, movefocus, u"
        "${modifier}, L, movefocus, r"
        "${modifier}, left, movefocus, l"
        "${modifier}, down, movefocus, d"
        "${modifier}, up, movefocus, u"
        "${modifier}, right, movefocus, r"
        "${modifier}, N, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw"
        "${modifier} ALT, N, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client --hide-latest -sw"
      ];
    };
  };
}
