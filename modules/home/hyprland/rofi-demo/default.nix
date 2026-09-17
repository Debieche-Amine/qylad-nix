{
  config,
  lib,
  pkgs,
  ...
}: let
  colors = config.lib.stylix.colors;
  uwsm = lib.getExe pkgs.uwsm;

  # Right side panel theme with semi-transparent background for Hyprland blur
  themeFile = pkgs.writeText "rofi-demo-theme.rasi" ''
    * {
        font: "Maple Mono NF 13";
        bg: #${colors.base00}80;
        bg-card: #${colors.base01}66;
        bg-selected: #${colors.base02}cc;
        fg: #${colors.base05};
        fg-muted: #${colors.base04};
        accent: #${colors.base0D};
        border-col: #${colors.base0D}aa;

        background-color: transparent;
        text-color: @fg;
        margin: 0px;
        padding: 0px;
    }

    window {
        width: 360px;
        height: 560px;
        x-offset: -16px;
        y-offset: 0px;
        border: 2px;
        border-radius: 18px;
        border-color: @border-col;
        background-color: @bg;
        location: east;
        anchor: east;
    }

    mainbox {
        padding: 20px 16px;
        spacing: 14px;
        children: [ inputbar, listview ];
    }

    inputbar {
        padding: 12px 16px;
        border-radius: 12px;
        background-color: @bg-card;
        children: [ prompt ];
    }

    prompt {
        text-color: @accent;
        font: "Maple Mono NF Bold 15";
        background-color: transparent;
    }

    listview {
        lines: 9;
        columns: 1;
        fixed-height: false;
        scrollbar: false;
        spacing: 8px;
        padding: 4px 0px 0px 0px;
    }

    element {
        padding: 12px 16px;
        border-radius: 12px;
        background-color: @bg-card;
        text-color: @fg;
    }

    element selected.normal {
        background-color: @bg-selected;
        border: 1px;
        border-color: @accent;
        text-color: #${colors.base05};
    }

    element-text {
        text-color: inherit;
        vertical-align: 0.5;
    }
  '';

  # Keyboard-driven persistent right panel
  rofiDemoScript = pkgs.writeShellScriptBin "rofi-demo" ''
    set -euo pipefail

    export PATH="${lib.makeBinPath (with pkgs; [
      rofi
      wireplumber
      swaynotificationcenter
      bluez
      networkmanager
      util-linux
      hyprpicker
      hyprlock
      grim
      slurp
      wl-clipboard
      libnotify
      coreutils
      gawk
      gnugrep
      procps
      hyprland
    ])}:$PATH"

    THEME="${themeFile}"

    get_vol_mute() {
      if wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "MUTED"; then
        echo "MUTED"
      else
        echo "UNMUTED"
      fi
    }

    get_mic_mute() {
      if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q "MUTED"; then
        echo "MUTED"
      else
        echo "LIVE"
      fi
    }

    get_bt_state() {
      if command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        echo "ON"
      else
        echo "OFF"
      fi
    }

    get_wifi_state() {
      if command -v nmcli >/dev/null 2>&1 && [ "$(nmcli radio wifi 2>/dev/null || echo 'disabled')" = "enabled" ]; then
        echo "ON"
      else
        echo "OFF"
      fi
    }

    get_dnd_state() {
      if command -v swaync-client >/dev/null 2>&1 && swaync-client -D 2>/dev/null | grep -q "true"; then
        echo "ON"
      else
        echo "OFF"
      fi
    }

    selected_row=0

    while true; do
      vol_st=$(get_vol_mute)
      mic_st=$(get_mic_mute)
      bt_st=$(get_bt_state)
      wifi_st=$(get_wifi_state)
      dnd_st=$(get_dnd_state)

      MENU_ITEMS=(
        "󰕾 Audio Mute         [ ''${vol_st} ]"
        "󰍬 Mic Mute           [ ''${mic_st} ]"
        "󰂯 Bluetooth          [ ''${bt_st} ]"
        "󰤨 Wi-Fi              [ ''${wifi_st} ]"
        "󰈈 Do Not Disturb     [ ''${dnd_st} ]"
        "🎨 Color Picker"
        "📷 Screenshot Region"
        "🔒 Lock Screen"
        "❌ Close Panel"
      )

      input=$(printf "%s\n" "''${MENU_ITEMS[@]}")

      raw_output=$(printf "%s" "''${input}" | rofi \
        -dmenu \
        -i \
        -p "Quick Panel" \
        -selected-row "''${selected_row}" \
        -format "i" \
        -theme "''${THEME}"; echo "EXIT_STATUS:$?")

      exit_code=$(echo "''${raw_output}" | grep 'EXIT_STATUS:' | cut -d: -f2)
      row_idx=$(echo "''${raw_output}" | grep -v 'EXIT_STATUS:' || true)

      if [ "''${exit_code}" -ne 0 ] || [ "''${row_idx}" = "8" ]; then
        break
      fi

      if [ -n "''${row_idx}" ]; then
        selected_row="''${row_idx}"
      fi

      case "''${selected_row}" in
        0) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null || true ;;
        1) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle 2>/dev/null || true ;;
        2) bluetoothctl power toggle 2>/dev/null || rfkill toggle bluetooth 2>/dev/null || true ;;
        3) nmcli radio wifi toggle 2>/dev/null || rfkill toggle wlan 2>/dev/null || true ;;
        4) swaync-client -d -sw 2>/dev/null || true ;;
        5) hyprpicker -a -s 1.5 2>/dev/null || true ;;
        6)
          geom=$(slurp 2>/dev/null || true)
          if [ -n "''${geom}" ]; then
            grim -g "''${geom}" - | wl-copy --type image/png 2>/dev/null || true
            notify-send -a Screenshot "Screenshot Copied" "Region saved to clipboard"
          fi
          ;;
        7)
          hyprlock 2>/dev/null &
          break
          ;;
      esac
    done
  '';
in {
  home.packages = [rofiDemoScript];

  wayland.windowManager.hyprland.settings = {
    bind = [
      "SUPER ALT, D, exec, ${uwsm} app -- ${rofiDemoScript}/bin/rofi-demo"
    ];
  };
}
