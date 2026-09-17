{pkgs}: rec {
  restrictedMode = pkgs.writeShellScriptBin "hypr-restricted-mode" ''
    set -eu

    case "''${1:-enter}" in
      enter)
        ${pkgs.hyprland}/bin/hyprctl dispatch submap restricted
        ${pkgs.systemd}/bin/systemctl --user stop waybar.service 2>/dev/null || true
        ;;
      exit)
        ${pkgs.hyprlock}/bin/hyprlock
        ${pkgs.hyprland}/bin/hyprctl dispatch submap reset
        ${pkgs.systemd}/bin/systemctl --user start waybar.service 2>/dev/null || true
        ;;
      *)
        echo "usage: hypr-restricted-mode [enter|exit]" >&2
        exit 2
        ;;
    esac
  '';

  terminalCwd = pkgs.writeShellScriptBin "hypr-terminal-cwd" ''
    set -eu

    find_shell_pid() {
      children="$(${pkgs.coreutils}/bin/cat "/proc/$1/task/$1/children" 2>/dev/null || true)"
      for child in $children; do
        [ -d "/proc/$child" ] || continue
        name="$(${pkgs.coreutils}/bin/cat "/proc/$child/comm" 2>/dev/null || true)"
        case "$name" in
          bash|dash|fish|ksh|nu|nushell|sh|tcsh|zsh)
            printf '%s\n' "$child"
            return 0
            ;;
        esac

        found="$(find_shell_pid "$child" || true)"
        if [ -n "$found" ]; then
          printf '%s\n' "$found"
          return 0
        fi
      done
      return 1
    }

    window="$(${pkgs.hyprland}/bin/hyprctl -j activewindow)"
    pid="$(printf '%s' "$window" | ${pkgs.jq}/bin/jq -r '.pid // 0')"
    class="$(printf '%s' "$window" | ${pkgs.jq}/bin/jq -r '((.class // "") | ascii_downcase)')"
    cwd="$HOME"
    if [ "$pid" -gt 0 ]; then
      shell_pid=""
      if [ "$class" = kitty ]; then
        shell_pid="$(find_shell_pid "$pid" || true)"
      fi
      source_pid="''${shell_pid:-$pid}"
      candidate="$(${pkgs.coreutils}/bin/readlink -f "/proc/$source_pid/cwd" 2>/dev/null || true)"
      [ -d "$candidate" ] && cwd="$candidate"
    fi

    exec ${pkgs.uwsm}/bin/uwsm app -- ${pkgs.kitty}/bin/kitty --directory "$cwd"
  '';

  laneWorkspace = pkgs.writeShellScriptBin "hypr-lane-workspace" ''
    set -eu

    action="''${1:-workspace}"
    direction="''${2:-1}"
    current="$(${pkgs.hyprland}/bin/hyprctl -j activeworkspace | ${pkgs.jq}/bin/jq -r '.name // ""')"

    lane="A"
    offset=0
    if printf '%s\n' "$current" | ${pkgs.gnugrep}/bin/grep -Eq '^[^:]+:-?[0-9]+$'; then
      lane="''${current%%:*}"
      offset="''${current##*:}"
    fi

    target="$lane:$((offset + direction))"
    case "$action" in
      workspace)
        exec ${pkgs.hyprland}/bin/hyprctl dispatch workspace "name:$target"
        ;;
      move)
        exec ${pkgs.hyprland}/bin/hyprctl dispatch movetoworkspace "name:$target"
        ;;
      *)
        echo "usage: hypr-lane-workspace [workspace|move] [-1|1]" >&2
        exit 2
        ;;
    esac
  '';

  toggleWorkspaceLayout = pkgs.writeShellScriptBin "hypr-toggle-workspace-layout" ''
    set -eu

    workspace="$(
      ${pkgs.hyprland}/bin/hyprctl -j activeworkspace |
        ${pkgs.jq}/bin/jq -r '.name // empty'
    )"
    [ -n "$workspace" ] || exit 1

    layout="$(
      ${pkgs.hyprland}/bin/hyprctl -j activeworkspace |
        ${pkgs.jq}/bin/jq -r '.tiledLayout // "dwindle"'
    )"
    case "$layout" in
      master) next="dwindle" ;;
      *) next="master" ;;
    esac

    exec ${pkgs.hyprland}/bin/hyprctl keyword workspace "name:$workspace, layout:$next"
  '';

  screenshotFull = pkgs.writeShellScriptBin "hypr-screenshot-full" ''
    set -eu
    ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy --type image/png
    ${pkgs.libnotify}/bin/notify-send -a Screenshot -i camera-photo "Screenshot copied" "The full display is in the clipboard."
  '';

  screenshotRegion = pkgs.writeShellScriptBin "hypr-screenshot-region" ''
    set -eu
    geometry="$(${pkgs.slurp}/bin/slurp)"
    ${pkgs.grim}/bin/grim -g "$geometry" - | ${pkgs.wl-clipboard}/bin/wl-copy --type image/png
    ${pkgs.libnotify}/bin/notify-send -a Screenshot -i camera-photo "Screenshot copied" "The selected region is in the clipboard."
  '';

  screenshotOcr = pkgs.writeShellScriptBin "hypr-screenshot-ocr" ''
    set -eu
    geometry="$(${pkgs.slurp}/bin/slurp)"
    text="$(${pkgs.grim}/bin/grim -g "$geometry" - | ${pkgs.tesseract}/bin/tesseract stdin stdout 2>/dev/null)"
    if [ -n "$text" ]; then
      printf '%s' "$text" | ${pkgs.wl-clipboard}/bin/wl-copy
      ${pkgs.libnotify}/bin/notify-send -a "OCR" -i edit-paste "OCR Text Copied" "$text"
    else
      ${pkgs.libnotify}/bin/notify-send -a "OCR" -i dialog-warning "OCR Failed" "No text recognized in selected region."
    fi
  '';

  screenrecordToggle = pkgs.writeShellScriptBin "hypr-screenrecord-toggle" ''
    set -eu
    PID_FILE="''${XDG_RUNTIME_DIR:-/tmp}/hypr-screenrec.pid"
    FILE_INFO="''${XDG_RUNTIME_DIR:-/tmp}/hypr-screenrec.path"

    signal_waybar() {
      ${pkgs.procps}/bin/pkill -RTMIN+8 waybar 2>/dev/null || true
    }

    if [ -f "$PID_FILE" ] && kill -0 "$(< "$PID_FILE")" 2>/dev/null; then
      rec_pid="$(< "$PID_FILE")"
      kill -INT "$rec_pid" 2>/dev/null || true
      rm -f "$PID_FILE"
      signal_waybar

      saved_file=""
      if [ -f "$FILE_INFO" ]; then
        saved_file="$(< "$FILE_INFO")"
        rm -f "$FILE_INFO"
      fi

      while kill -0 "$rec_pid" 2>/dev/null; do
        ${pkgs.coreutils}/bin/sleep 0.1
      done

      if [ -n "$saved_file" ] && [ -f "$saved_file" ]; then
        ${pkgs.wl-clipboard}/bin/wl-copy --type video/mp4 < "$saved_file" 2>/dev/null || true
        ${pkgs.libnotify}/bin/notify-send -a "Screen Recorder" -i media-playback-stop "Recording Copied & Saved" "Video copied to clipboard:\n$(basename "$saved_file")"
      else
        ${pkgs.libnotify}/bin/notify-send -a "Screen Recorder" -i media-playback-stop "Recording Saved" "Saved to ~/Videos/Recordings"
      fi
      exit 0
    fi

    mode="''${1:-region}"
    RECORDINGS_DIR="$HOME/Videos/Recordings"
    mkdir -p "$RECORDINGS_DIR"
    filename="$RECORDINGS_DIR/recording_$(date +'%Y-%m-%d_%H-%M-%S').mp4"

    case "$mode" in
      region)
        geom="$(${pkgs.slurp}/bin/slurp)"
        [ -n "$geom" ] || exit 0
        ${pkgs.wl-screenrec}/bin/wl-screenrec --audio --audio-device @DEFAULT_SINK@.monitor -g "$geom" -f "$filename" &
        ;;
      full)
        ${pkgs.wl-screenrec}/bin/wl-screenrec --audio --audio-device @DEFAULT_SINK@.monitor -f "$filename" &
        ;;
      *)
        echo "usage: hypr-screenrecord-toggle [region|full]" >&2
        exit 2
        ;;
    esac

    rec_pid=$!
    printf '%s\n' "$rec_pid" > "$PID_FILE"
    printf '%s\n' "$filename" > "$FILE_INFO"
    signal_waybar
  '';

  cgroupMenu = pkgs.writeShellScriptBin "hypr-cgroup-menu" ''
    set -eu
    opt1="hypr-cgroup-ctl --inactive set cpu.max 10000 100000"
    opt2="hypr-cgroup-ctl --all set cpu.max max 100000"

    choice=$(printf '%s\n%s\n' "$opt1" "$opt2" | ${pkgs.rofi}/bin/rofi -dmenu -i -p "cgroup cpu")
    [ -n "$choice" ] || exit 0

    case "$choice" in
      "$opt1")
        hypr-cgroup-ctl --inactive set cpu.max 10000 100000
        ${pkgs.libnotify}/bin/notify-send -a "cgroup" "CPU Limit Applied" "hypr-cgroup-ctl --inactive set cpu.max 10000 100000"
        ;;
      "$opt2")
        hypr-cgroup-ctl --all set cpu.max max 100000
        ${pkgs.libnotify}/bin/notify-send -a "cgroup" "CPU Limit Reset" "hypr-cgroup-ctl --all set cpu.max max 100000"
        ;;
    esac
  '';
}
