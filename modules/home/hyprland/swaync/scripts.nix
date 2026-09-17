{pkgs}: rec {
  hyprsunsetToggle = pkgs.writeShellScriptBin "hypr-sunset-toggle" ''
    set -eu
    val="''${1:-''${SWAYNC_TOGGLE_STATE:-}}"
    if [ "$val" = "1" ] || [ "$val" = "true" ]; then
      ${pkgs.procps}/bin/pkill -x hyprsunset 2>/dev/null || true
      ${pkgs.hyprsunset}/bin/hyprsunset -t 4500 >/dev/null 2>&1 &
    elif [ "$val" = "0" ] || [ "$val" = "false" ]; then
      ${pkgs.procps}/bin/pkill -x hyprsunset 2>/dev/null || true
    else
      if ${pkgs.procps}/bin/pgrep -x hyprsunset >/dev/null; then
        ${pkgs.procps}/bin/pkill -x hyprsunset 2>/dev/null || true
      else
        ${pkgs.hyprsunset}/bin/hyprsunset -t 4500 >/dev/null 2>&1 &
      fi
    fi
  '';

  idleInhibitToggle = pkgs.writeShellScriptBin "hypr-idle-inhibit-toggle" ''
    set -eu
    val="''${1:-''${SWAYNC_TOGGLE_STATE:-}}"
    service="swaync-idle-inhibit.service"

    enable() {
      ${pkgs.systemd}/bin/systemctl --user start "$service"
    }

    disable() {
      ${pkgs.systemd}/bin/systemctl --user stop "$service"
    }

    if [ "$val" = "1" ] || [ "$val" = "true" ]; then
      enable
    elif [ "$val" = "0" ] || [ "$val" = "false" ]; then
      disable
    else
      if ${pkgs.systemd}/bin/systemctl --user is-active --quiet "$service"; then
        disable
      else
        enable
      fi
    fi
  '';

  dndSoundSync = pkgs.writeShellScriptBin "hypr-dnd-sound-sync" ''
    set -eu
    dnd_state="$(${pkgs.swaynotificationcenter}/bin/swaync-client -D 2>/dev/null || echo "false")"
    if [ "$dnd_state" = "true" ]; then
      ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ 1
    else
      ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
    fi
  '';
}
