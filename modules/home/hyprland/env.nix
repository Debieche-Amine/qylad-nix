{config, ...}: {
  xdg.configFile."uwsm/env-hyprland".text = ''
    # UWSM does not source a login shell. Load Home Manager's session
    # variables so Qt/Kvantum and Stylix's KDE color scheme reach Dolphin.
    if [ -r /etc/profiles/per-user/${config.home.username}/etc/profile.d/hm-session-vars.sh ]; then
      . /etc/profiles/per-user/${config.home.username}/etc/profile.d/hm-session-vars.sh
    fi

    export XCURSOR_SIZE=24
    export HYPRCURSOR_SIZE=24
    export NIXOS_OZONE_WL=1
    export MOZ_ENABLE_WAYLAND=1
    export QT_QPA_PLATFORM="wayland;xcb"
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export GDK_BACKEND="wayland,x11,*"
    export CHROMIUM_USER_FLAGS="--password-store=gnome-libsecret"
  '';
}
