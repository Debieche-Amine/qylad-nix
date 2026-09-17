{
  config,
  pkgs,
  lib,
  ...
}: let
  modifier = "SUPER";
  maxItems = "1000";

  clipboardMenu = pkgs.writeShellScriptBin "hypr-clipboard-menu" ''
    set -euo pipefail

    THUMB_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbs"
    mkdir -p "$THUMB_DIR"

    while true; do
      raw_list="$(${pkgs.cliphist}/bin/cliphist list)"

      if [ -z "$raw_list" ]; then
        ${pkgs.libnotify}/bin/notify-send -a Clipboard -i edit-paste "Clipboard Empty" "No items in clipboard history."
        exit 0
      fi

      formatted_list="$(
        while IFS=$'\t' read -r id preview; do
          [ -n "$id" ] || continue
          if [[ "$preview" =~ ^\[\[\ binary\ data ]]; then
            thumb="$THUMB_DIR/$id.png"
            if [ ! -f "$thumb" ]; then
              printf '%s\t%s' "$id" "$preview" | ${pkgs.cliphist}/bin/cliphist decode > "$thumb" 2>/dev/null || true
            fi
            printf '%s\t%s\0icon\x1f%s\n' "$id" "$preview" "$thumb"
          else
            printf '%s\t%s\0icon\x1fedit-paste\n' "$id" "$preview"
          fi
        done <<< "$raw_list"
      )"

      set +e
      selection="$(printf '%s' "$formatted_list" | ${pkgs.rofi}/bin/rofi -dmenu -i \
        -p "Clipboard" \
        -mesg "<b>Enter</b>: copy | <b>Alt+Del</b>: delete item | <b>Alt+W</b>: wipe history" \
        -show-icons \
        -kb-delete-entry "" \
        -kb-custom-1 "Alt+Delete,Shift+Delete,Alt+d" \
        -kb-custom-2 "Alt+w,Control+Delete")"
      exit_code=$?
      set -e

      case $exit_code in
        0) # Enter -> Copy to clipboard
          [ -n "$selection" ] || exit 0
          printf '%s' "$selection" | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
          exit 0
          ;;
        10) # Alt+Delete / Shift+Delete -> Delete selected item
          [ -n "$selection" ] || exit 0
          id="$(printf '%s' "$selection" | ${pkgs.gawk}/bin/awk -F'\t' '{print $1}')"
          printf '%s' "$selection" | ${pkgs.cliphist}/bin/cliphist delete
          rm -f "$THUMB_DIR/$id.png"
          ${pkgs.libnotify}/bin/notify-send -a Clipboard -i edit-delete "Item Deleted" "Deleted entry #$id from history."
          # Continue loop to re-display remaining items
          ;;
        11) # Alt+W / Ctrl+Delete -> Wipe all history
          ${pkgs.cliphist}/bin/cliphist wipe
          rm -rf "$THUMB_DIR"/*
          ${pkgs.libnotify}/bin/notify-send -a Clipboard -i edit-clear "Clipboard Wiped" "All clipboard history has been cleared."
          exit 0
          ;;
        *) # Esc or cancelled
          exit 0
          ;;
      esac
    done
  '';
in {
  home.packages = with pkgs; [
    cliphist
    wl-clipboard
    clipboardMenu
  ];

  systemd.user.services = {
    cliphist-wipe-on-startup = {
      Unit = {
        Description = "Clear clipboard history on session startup";
        PartOf = ["graphical-session.target"];
        Before = ["cliphist.service" "cliphist-images.service"];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "cliphist-wipe-startup" ''
          set -eu
          ${pkgs.cliphist}/bin/cliphist wipe || true
          rm -rf "''${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbs"/* 2>/dev/null || true
        '';
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    cliphist = {
      Unit = {
        Description = "Wayland clipboard history (text)";
        PartOf = ["graphical-session.target"];
        After = [
          "graphical-session.target"
          "cliphist-wipe-on-startup.service"
        ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist -max-items ${maxItems} store";
        Restart = "on-failure";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    cliphist-images = {
      Unit = {
        Description = "Wayland clipboard history (images)";
        PartOf = ["graphical-session.target"];
        After = [
          "graphical-session.target"
          "cliphist-wipe-on-startup.service"
        ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist -max-items ${maxItems} store";
        Restart = "on-failure";
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };

  wayland.windowManager.hyprland.settings.bind = [
    "${modifier}, V, exec, ${clipboardMenu}/bin/hypr-clipboard-menu"
  ];
}
