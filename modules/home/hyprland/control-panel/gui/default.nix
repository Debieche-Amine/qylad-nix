{
  pkgs,
  lib,
  ...
}: let
  controlPanelApp = pkgs.writeShellScriptBin "hypr-control-panel-app" ''
    export PATH="${pkgs.lib.makeBinPath [
      pkgs.hyprland
      pkgs.jq
      pkgs.coreutils
      pkgs.procps
      pkgs.libnotify
    ]}:$PATH"
    exec ${pkgs.python3}/bin/python3 ${./app.py} "$@"
  '';

  controlPanel = pkgs.writeShellScriptBin "hypr-control-panel" ''
    set -eu
    if [ -t 0 ] && [ -t 1 ]; then
      exec ${controlPanelApp}/bin/hypr-control-panel-app "$@"
    else
      active_class="$(${pkgs.hyprland}/bin/hyprctl activewindow -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.class // empty')"
      if [ "$active_class" = "hypr-control-panel" ]; then
        ${pkgs.hyprland}/bin/hyprctl dispatch closewindow "class:hypr-control-panel"
        exit 0
      fi

      existing="$(${pkgs.hyprland}/bin/hyprctl clients -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[] | select(.class == "hypr-control-panel") | .address' | head -n 1)"
      if [ -n "$existing" ]; then
        ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow "address:$existing"
        exit 0
      fi

      exec ${pkgs.uwsm}/bin/uwsm app -- ${pkgs.kitty}/bin/kitty --class=hypr-control-panel -o font_size=13 -o window_padding_width=6 -T "Hyprland Control Panel" ${controlPanelApp}/bin/hypr-control-panel-app "$@"
    fi
  '';
in {
  home.packages = [
    controlPanel
    controlPanelApp
  ];
}
