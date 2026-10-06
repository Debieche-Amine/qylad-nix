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
  repoDir = "${config.home.homeDirectory}/nixos";

  excalidrawDesktop = pkgs.writeShellScriptBin "excalidraw-desktop" ''
    set -eu
    exec ${pkgs.chromium}/bin/chromium --app=https://excalidraw.com --class=excalidraw
  '';
in {
  home.packages = with pkgs; [
    kitty
    btop
    excalidrawDesktop
  ];

  programs.btop = {
    enable = true;
    settings = {
      vim_keys = true;
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    configType = "hyprlang";
    systemd = {
      enable = false;
    };
    xwayland.enable = true;

    settings = {
      "$mainMod" = modifier;
      "$terminal" = terminal;
      "$menu" = menu;

      monitor = [", preferred, auto, 1"];

      exec-once = [
        "${pkgs.hyprland}/bin/hyprctl dispatch workspace name:A:0"
        "[workspace name:A:0 silent] ${uwsm} app -- ${terminal} --directory ${repoDir}"
        "[workspace name:A:0 silent] ${uwsm} app -- ${terminal} --directory ${repoDir}"
        "[workspace special:s1 silent] ${uwsm} app -- ${excalidrawDesktop}/bin/excalidraw-desktop"
        "[workspace name:A:1 silent] ${uwsm} app -- ${terminal}"
        "[workspace special:scratchpad silent] ${uwsm} app -- ${terminal} ${pkgs.btop}/bin/btop"

        "[workspace name:Z:0 silent] ${uwsm} app -- ${terminal} --directory ${config.home.homeDirectory}/notes"
        "[workspace name:Z:0 silent] ${uwsm} app -- ${terminal} --directory ${config.home.homeDirectory}/notes"
      ];

      general = {
        layout = "dwindle";
        gaps_in = 1;
        gaps_out = 1;
        border_size = 2;
        resize_on_border = true;
        extend_border_grab_area = 14;
        hover_icon_on_border = true;
        allow_tearing = false;
        "col.active_border" = lib.mkForce "rgb(${config.lib.stylix.colors.base0E}) rgb(${config.lib.stylix.colors.base0D}) 45deg";
        "col.inactive_border" = lib.mkForce "rgb(${config.lib.stylix.colors.base03})";
        snap = {
          enabled = true;
          window_gap = 10;
          monitor_gap = 10;
          border_overlap = false;
        };
      };

      decoration = {
        rounding = 8;
        rounding_power = 2;
        active_opacity = 0.96;
        inactive_opacity = 0.85;
        fullscreen_opacity = 1.0;
        dim_inactive = true;
        dim_strength = 0.15;
        dim_special = 0.35;

        shadow = {
          enabled = true;
          range = 18;
          render_power = 3;
          offset = "0 5";
          scale = 0.98;
        };

        blur = {
          enabled = true;
          size = 8;
          passes = 3;
          new_optimizations = true;
          ignore_opacity = true;
          xray = false;
          noise = 0.018;
          contrast = 1.08;
          brightness = 0.92;
          vibrancy = 0.12;
          vibrancy_darkness = 0.18;
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "ember, 0.16, 1, 0.3, 1"
          "emberOut, 0.4, 0, 1, 1"
          "workspace, 0.2, 0.9, 0.3, 1"
        ];
        animation = [
          "windows, true, 4, ember, popin 88%"
          "windowsOut, true, 3, emberOut, popin 92%"
          "border, true, 5, ember"
          "borderangle, true, 6, ember"
          "fade, true, 3, ember"
          "layers, true, 4, ember, popin 94%"
          "workspaces, true, 3, workspace, fade"
          "specialWorkspace, true, 4, ember, slidevert"
        ];
      };

      input = {
        kb_layout = "fr,ara";
        kb_variant = "nodeadkeys,azerty";
        kb_options = "caps:escape,grp:shifts_toggle";
        numlock_by_default = true;
        follow_mouse = 1;
        sensitivity = 0.0;
        accel_profile = "flat";

        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          "tap-and-drag" = true;
          drag_lock = 1;
          disable_while_typing = true;
        };
      };

      cursor = {
        hide_on_key_press = true;
        inactive_timeout = 3;
        warp_on_change_workspace = true;
      };

      binds = {
        scroll_event_delay = 100;
        workspace_back_and_forth = false;
        allow_workspace_cycles = true;
        movefocus_cycles_fullscreen = true;
      };

      dwindle = {
        preserve_split = true;
        smart_split = false;
        smart_resizing = true;
        force_split = 0;
      };

      master = {
        mfact = 0.62;
        orientation = "left";
        new_status = "slave";
        new_on_active = "after";
        smart_resizing = true;
        drop_at_cursor = true;
      };

      group = {
        insert_after_current = true;
        focus_removed_window = true;
        groupbar = {
          enabled = true;
          font_family = "Maple Mono NF";
          font_size = 11;
          gradients = true;
          height = 24;
          indicator_height = 2;
          rounding = 8;
        };
      };

      misc = {
        vrr = 1;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        focus_on_activate = true;
        middle_click_paste = false;
      };

      xwayland.force_zero_scaling = true;
    };
  };
}
