{pkgs}: rec {
  laneWorkspace = pkgs.writeShellScriptBin "sway-lane-workspace" ''
    set -eu

    action="''${1:-workspace}"
    direction="''${2:-1}"
    current="$(${pkgs.sway}/bin/swaymsg -t get_workspaces | ${pkgs.jq}/bin/jq -r '.[] | select(.focused).name')"

    lane="a"
    offset=0
    if printf '%s\n' "$current" | ${pkgs.gnugrep}/bin/grep -Eq '^[^:]+:-?[0-9]+$'; then
      lane="''${current%%:*}"
      offset="''${current##*:}"
    fi

    target="$lane:$((offset + direction))"
    case "$action" in
      workspace)
        exec ${pkgs.sway}/bin/swaymsg "workspace $target"
        ;;
      move)
        ${pkgs.sway}/bin/swaymsg "move container to workspace $target" >/dev/null
        exec ${pkgs.sway}/bin/swaymsg "workspace $target"
        ;;
      *)
        echo "usage: sway-lane-workspace [workspace|move] [-1|1]" >&2
        exit 2
        ;;
    esac
  '';

  waybarLane = pkgs.writeShellScriptBin "sway-waybar-lane" ''
    set -eu

    print_lane() {
      current="$(${pkgs.sway}/bin/swaymsg -t get_workspaces | ${pkgs.jq}/bin/jq -r 'map(select(.focused).name)[0] // ""')"

      if printf '%s\n' "$current" | ${pkgs.gnugrep}/bin/grep -Eq '^(a|z|e|i|o|p):-?[0-9]+$'; then
        lane="''${current%%:*}"
        ${pkgs.jq}/bin/jq -cn \
          --arg text "$current" \
          --arg class "$lane" \
          --arg tooltip "Focused lane: $current" \
          '{text: $text, class: $class, tooltip: $tooltip}'
      else
        ${pkgs.jq}/bin/jq -cn \
          --arg tooltip "Focused workspace: ''${current:-none}" \
          '{text: "-", class: "other", tooltip: $tooltip}'
      fi
    }

    print_lane
    ${pkgs.sway}/bin/swaymsg -m -t subscribe '["workspace"]' | while read -r _; do
      print_lane
    done
  '';

  screenshotFull = pkgs.writeShellScriptBin "sway-screenshot-full" ''
    set -eu
    ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy --type image/png
  '';

  screenshotRegion = pkgs.writeShellScriptBin "sway-screenshot-region" ''
    set -eu
    geometry="$(${pkgs.slurp}/bin/slurp)"
    ${pkgs.grim}/bin/grim -g "$geometry" - | ${pkgs.wl-clipboard}/bin/wl-copy --type image/png
  '';

  lock = pkgs.writeShellScriptBin "sway-lock" ''
    set -eu
    exec ${pkgs.swaylock}/bin/swaylock -f -c 1d2021
  '';
  waybarNetUsage = pkgs.writeShellScriptBin "waybar-net-usage" ''
    #!${pkgs.bash}/bin/bash

    iface="wlo1"
    state="/tmp/waybar-net-usage"

    current_rx=$(< /sys/class/net/$iface/statistics/rx_bytes)
    current_tx=$(< /sys/class/net/$iface/statistics/tx_bytes)

    if [[ ! -f "$state" ]]; then
        printf "%s %s\n" "$current_rx" "$current_tx" > "$state"
    fi

    read base_rx base_tx < "$state"

    rx=$((current_rx - base_rx))
    tx=$((current_tx - base_tx))

    mib_rx=$(awk "BEGIN{printf \"%.2f\", $rx/1024/1024}")
    mib_tx=$(awk "BEGIN{printf \"%.2f\", $tx/1024/1024}")

    printf '{"text":"󰁝 %s MiB 󰁅 %s MiB"}\n' "$mib_rx" "$mib_tx"
    #             󰁝  󰁅  ↑  ↓  󰕒  󰇚        

  '';

  waybarNetReset = pkgs.writeShellScriptBin "waybar-net-reset" ''
    #!${pkgs.bash}/bin/bash

    iface="wlo1"
    state="/tmp/waybar-net-usage"

    rx=$(< /sys/class/net/$iface/statistics/rx_bytes)
    tx=$(< /sys/class/net/$iface/statistics/tx_bytes)

    printf "%s %s\n" "$rx" "$tx" > "$state"
  '';

  waybarMic = pkgs.writeShellScriptBin "waybar-mic" ''
    #!${pkgs.bash}/bin/bash

    if ${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q '\[MUTED\]'; then
        printf '{"text":"󰍭","class":"muted","tooltip":"Microphone muted"}\n'
    else
        printf '{"text":"󰍬","class":"active","tooltip":"Microphone active"}\n'
    fi
  '';

  batteryNotify = pkgs.writeShellScriptBin "battery-notify" ''
    #!${pkgs.bash}/bin/bash

    notified_levels=""

    levels=(50 35 25 20 15 10 7 5 4 3 2 1)

    while true; do
      capacity=$(cat /sys/class/power_supply/BAT1/capacity)
      status=$(cat /sys/class/power_supply/BAT1/status)

      if [[ "$status" = "Discharging" ]]; then
        for level in "''${levels[@]}"; do
          if [[ $capacity -le $level && ! " $notified_levels " =~ " $level " ]]; then
            ${pkgs.libnotify}/bin/notify-send \
              -u critical \
              "Low Battery" \
              "Battery is at $capacity% (below $level%)."

            notified_levels="$notified_levels $level"
          fi
        done
      fi

      # Reset notifications after charging above 55%
      if [[ "$status" = "Charging" && $capacity -ge 55 ]]; then
        notified_levels=""
      fi

      sleep 60
    done
  '';
}
