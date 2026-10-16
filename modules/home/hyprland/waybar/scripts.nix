{pkgs}: rec {
  waybarLane = pkgs.writeShellScriptBin "hypr-waybar-lane" ''
    set -eu

    print_lane() {
      current="$(${pkgs.hyprland}/bin/hyprctl -j activeworkspace | ${pkgs.jq}/bin/jq -r '.name // ""')"

      if printf '%s\n' "$current" | ${pkgs.gnugrep}/bin/grep -Eiq '^([a-z0-9]+):-?[0-9]+$'; then
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
    socket="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/hypr/''${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
    ${pkgs.socat}/bin/socat -U - "UNIX-CONNECT:$socket" | while IFS= read -r event; do
      case "$event" in
        workspace*|focusedmon*) print_lane ;;
      esac
    done
  '';

  waybarScratchpad = pkgs.writeShellScriptBin "hypr-waybar-scratchpad" ''
    set -eu

    print_scratchpad() {
      clients="$(${pkgs.hyprland}/bin/hyprctl -j clients)"
      monitors="$(${pkgs.hyprland}/bin/hyprctl -j monitors)"
      count="$(printf '%s' "$clients" | ${pkgs.jq}/bin/jq '[.[] | select(.workspace.name | startswith("special:"))] | length')"
      visible="$(printf '%s' "$monitors" | ${pkgs.jq}/bin/jq 'any(.[]; .specialWorkspace.name | startswith("special:"))')"

      if [ "$visible" = true ]; then
        class="active"
      elif [ "$count" -gt 0 ]; then
        class="occupied"
      else
        class="empty"
      fi

      ${pkgs.jq}/bin/jq -cn \
        --arg text "󰖯 $count" \
        --arg class "$class" \
        --arg tooltip "$count window(s) in scratchpad" \
        '{text: $text, class: $class, tooltip: $tooltip}'
    }

    print_scratchpad
    socket="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/hypr/''${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
    ${pkgs.socat}/bin/socat -U - "UNIX-CONNECT:$socket" | while IFS= read -r event; do
      case "$event" in
        openwindow*|closewindow*|movewindow*|activespecial*) print_scratchpad ;;
      esac
    done
  '';

  waybarNetUsage = pkgs.writeShellScriptBin "waybar-net-usage" ''
    set -eu

    find_default_iface() {
      iface="$(${pkgs.gawk}/bin/awk '$2 == "00000000" { print $1; exit }' /proc/net/route)"
      if [ -z "$iface" ]; then
        for path in /sys/class/net/*; do
          [ "''${path##*/}" != lo ] || continue
          [ -r "$path/statistics/rx_bytes" ] || continue
          [ "$(< "$path/operstate")" = up ] || continue
          iface="''${path##*/}"
          break
        done
      fi
      printf '%s\n' "$iface"
    }

    iface="$(find_default_iface)"
    if [ -z "$iface" ]; then
      ${pkgs.jq}/bin/jq -cn '{text: "󰖪", class: "disconnected", tooltip: "No network interface"}'
      exit 0
    fi

    state="''${XDG_RUNTIME_DIR:-/tmp}/waybar-net-usage"
    current_rx="$(< "/sys/class/net/$iface/statistics/rx_bytes")"
    current_tx="$(< "/sys/class/net/$iface/statistics/tx_bytes")"

    base_iface=""
    base_rx=0
    base_tx=0
    if [ -r "$state" ]; then
      read -r base_iface base_rx base_tx <"$state" || true
    fi

    if [ "$base_iface" != "$iface" ] || [ "$current_rx" -lt "$base_rx" ] || [ "$current_tx" -lt "$base_tx" ]; then
      base_iface="$iface"
      base_rx="$current_rx"
      base_tx="$current_tx"
      printf '%s %s %s\n' "$base_iface" "$base_rx" "$base_tx" >"$state"
    fi

    rx=$((current_rx - base_rx))
    tx=$((current_tx - base_tx))
    mib_rx="$(${pkgs.gawk}/bin/awk "BEGIN { printf \"%.2f\", $rx / 1024 / 1024 }")"
    mib_tx="$(${pkgs.gawk}/bin/awk "BEGIN { printf \"%.2f\", $tx / 1024 / 1024 }")"

    ${pkgs.jq}/bin/jq -cn \
      --arg text "󰁅 $mib_rx  󰁝 $mib_tx" \
      --arg tooltip "Interface: $iface
    Received: $mib_rx MiB
    Sent: $mib_tx MiB" \
      '{text: $text, tooltip: $tooltip}'
  '';

  waybarNetReset = pkgs.writeShellScriptBin "waybar-net-reset" ''
    set -eu

    iface="$(${pkgs.gawk}/bin/awk '$2 == "00000000" { print $1; exit }' /proc/net/route)"
    if [ -z "$iface" ]; then
      for path in /sys/class/net/*; do
        [ "''${path##*/}" != lo ] || continue
        [ -r "$path/statistics/rx_bytes" ] || continue
        [ "$(< "$path/operstate")" = up ] || continue
        iface="''${path##*/}"
        break
      done
    fi
    [ -n "$iface" ] || exit 0

    state="''${XDG_RUNTIME_DIR:-/tmp}/waybar-net-usage"
    rx="$(< "/sys/class/net/$iface/statistics/rx_bytes")"
    tx="$(< "/sys/class/net/$iface/statistics/tx_bytes")"
    printf '%s %s %s\n' "$iface" "$rx" "$tx" >"$state"
  '';

  waybarMic = pkgs.writeShellScriptBin "waybar-mic" ''
    set -eu
    if ${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | ${pkgs.gnugrep}/bin/grep -q '\[MUTED\]'; then
      printf '{"text":"󰍭","class":"muted","tooltip":"Microphone muted"}\n'
    else
      printf '{"text":"󰍬","class":"active","tooltip":"Microphone active"}\n'
    fi
  '';

  waybarRecorder = pkgs.writeShellScriptBin "hypr-waybar-recorder" ''
    set -eu
    PID_FILE="''${XDG_RUNTIME_DIR:-/tmp}/hypr-screenrec.pid"

    if [ -f "$PID_FILE" ] && ${pkgs.coreutils}/bin/kill -0 "$(< "$PID_FILE")" 2>/dev/null; then
      ${pkgs.jq}/bin/jq -cn \
        --arg text "󰑋 REC" \
        --arg class "recording" \
        --arg tooltip "Screen recording active. Click to stop and copy to clipboard." \
        '{text: $text, class: $class, tooltip: $tooltip}'
    else
      ${pkgs.jq}/bin/jq -cn \
        --arg text "" \
        --arg class "idle" \
        --arg tooltip "" \
        '{text: $text, class: $class, tooltip: $tooltip}'
    fi
  '';
}
