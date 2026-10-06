{pkgs, ...}: let
  hyprSleepTimer = pkgs.writeShellScriptBin "hypr-sleep-timer" ''
    set -euo pipefail

    TARGET_FILE="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/hypr-sleep-timer.target"

    parse_duration() {
      local str="$1"
      if [[ "$str" =~ ^([0-9]+)([smhd]?)$ ]]; then
        local num="''${BASH_REMATCH[1]}"
        local unit="''${BASH_REMATCH[2]}"
        case "$unit" in
          s|"") echo "$num" ;;
          m) echo $((num * 60)) ;;
          h) echo $((num * 3600)) ;;
          d) echo $((num * 86400)) ;;
        esac
      else
        echo 0
      fi
    }

    format_remaining() {
      local rem="$1"
      if [ "$rem" -le 0 ]; then
        echo "0s"
        return
      fi
      local d=$((rem / 86400))
      local h=$(((rem % 86400) / 3600))
      local m=$(((rem % 3600) / 60))
      local s=$((rem % 60))

      if [ "$d" -gt 0 ]; then
        if [ "$h" -gt 0 ]; then
          echo "''${d}d ''${h}h"
        else
          echo "''${d}d"
        fi
      elif [ "$h" -gt 0 ]; then
        if [ "$m" -gt 0 ]; then
          echo "''${h}h ''${m}m"
        else
          echo "''${h}h"
        fi
      elif [ "$m" -gt 0 ]; then
        if [ "$s" -gt 0 ]; then
          echo "''${m}m ''${s}s"
        else
          echo "''${m}m"
        fi
      else
        echo "''${s}s"
      fi
    }

    notify_waybar() {
      ${pkgs.procps}/bin/pkill -RTMIN+10 waybar 2>/dev/null || true
    }

    cmd="''${1:-waybar}"

    case "$cmd" in
      add)
        dur_str="''${2:-}"
        if [ -z "$dur_str" ]; then
          echo "Usage: hypr-sleep-timer add <duration>" >&2
          exit 1
        fi

        delta="$(parse_duration "$dur_str")"
        if [ "$delta" -le 0 ]; then
          echo "Invalid duration: $dur_str" >&2
          exit 1
        fi

        now="$(${pkgs.coreutils}/bin/date +%s)"
        target=0
        if [ -f "$TARGET_FILE" ]; then
          target="$(${pkgs.coreutils}/bin/cat "$TARGET_FILE" 2>/dev/null || echo 0)"
        fi

        if [ "$target" -lt "$now" ]; then
          target="$now"
        fi

        new_target=$((target + delta))
        printf '%s\n' "$new_target" > "$TARGET_FILE"

        if ! ${pkgs.systemd}/bin/systemctl --user is-active --quiet hypr-sleep-timer.service; then
          ${pkgs.systemd}/bin/systemctl --user start hypr-sleep-timer.service
        fi

        notify_waybar

        remaining=$((new_target - now))
        formatted="$(format_remaining "$remaining")"
        ${pkgs.libnotify}/bin/notify-send -a "Sleep Timer" "󰔛 Sleep Timer Extended" "+$dur_str ($formatted left)" -t 1500
        ;;

      cancel)
        ${pkgs.coreutils}/bin/rm -f "$TARGET_FILE"
        ${pkgs.systemd}/bin/systemctl --user stop hypr-sleep-timer.service 2>/dev/null || true
        notify_waybar
        ${pkgs.libnotify}/bin/notify-send -a "Sleep Timer" "󰔛 Sleep Timer Reset" "Timer cancelled. Normal idle resumed." -t 1500
        ;;

      daemon)
        while true; do
          if [ ! -f "$TARGET_FILE" ]; then
            exit 0
          fi

          now="$(${pkgs.coreutils}/bin/date +%s)"
          target="$(${pkgs.coreutils}/bin/cat "$TARGET_FILE" 2>/dev/null || echo 0)"

          if [ "$target" -le 0 ]; then
            exit 0
          fi

          if [ "$now" -ge "$target" ]; then
            ${pkgs.coreutils}/bin/rm -f "$TARGET_FILE"
            notify_waybar
            ${pkgs.libnotify}/bin/notify-send -a "Sleep Timer" -u critical "󰔛 Sleep Timer Expired" "Timer finished. Locking session..." -t 2000
            ${pkgs.procps}/bin/pidof hyprlock >/dev/null 2>&1 || ${pkgs.hyprlock}/bin/hyprlock
            exit 0
          fi

          ${pkgs.coreutils}/bin/sleep 1
        done
        ;;

      waybar)
        if [ -f "$TARGET_FILE" ]; then
          target="$(${pkgs.coreutils}/bin/cat "$TARGET_FILE" 2>/dev/null || echo 0)"
          now="$(${pkgs.coreutils}/bin/date +%s)"
          rem=$((target - now))

          if [ "$rem" -gt 0 ]; then
            formatted="$(format_remaining "$rem")"
            target_clock="$(${pkgs.coreutils}/bin/date -d "@$target" "+%H:%M:%S" 2>/dev/null || echo "")"
            tooltip="Sleep Timer: $formatted remaining"
            if [ -n "$target_clock" ]; then
              tooltip="$tooltip\nLocks at: $target_clock"
            fi
            tooltip="$tooltip\n\nLeft-click: Notifications & Controls\nRight-click: Cancel Timer"

            ${pkgs.jq}/bin/jq -cn \
              --arg text "󰔛 $formatted" \
              --arg class "active" \
              --arg tooltip "$tooltip" \
              '{text: $text, class: $class, tooltip: $tooltip}'
            exit 0
          fi
        fi

        ${pkgs.jq}/bin/jq -cn \
          --arg text "" \
          --arg class "inactive" \
          --arg tooltip "Sleep timer inactive" \
          '{text: $text, class: $class, tooltip: $tooltip}'
        ;;

      *)
        echo "Usage: hypr-sleep-timer {add <duration>|cancel|daemon|waybar}" >&2
        exit 1
        ;;
    esac
  '';
in {
  home.packages = [
    hyprSleepTimer
  ];

  systemd.user.services.hypr-sleep-timer = {
    Unit = {
      Description = "Hyprland Sleep Timer & Idle Inhibitor";
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=idle --who=SleepTimer --why='Sleep Timer Active' ${hyprSleepTimer}/bin/hypr-sleep-timer daemon";
      Restart = "no";
    };
  };
}
