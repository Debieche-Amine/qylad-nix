{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  # Enable resource controller delegation (CPU, I/O, Memory, Tasks) to user app cgroups
  systemd.user.extraConfig = ''
    DefaultCPUAccounting=yes
    DefaultIOAccounting=yes
    DefaultMemoryAccounting=yes
    DefaultTasksAccounting=yes
  '';

  systemd.user.slices = {
    "app.slice".sliceConfig = {
      CPUWeight = 100;
      IOWeight = 100;
    };
    "app-graphical.slice".sliceConfig = {
      CPUWeight = 100;
      IOWeight = 100;
    };
  };

  services.gnome.gnome-keyring.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd '${lib.getExe config.programs.uwsm.package} start -e -D Hyprland hyprland.desktop'";
  };

  security.pam.services = {
    # Unlock the existing login keyring after signing in through greetd
    greetd.enableGnomeKeyring = true;
    # Synchronize it if `passwd` changes the account password.
    passwd.enableGnomeKeyring = true;
    hyprlock.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
  };

  # Hyprland provides its own screencast portal. The wlr portal is otherwise
  # pulled in by the shared desktop and virtualization modules.
  xdg.portal = {
    enable = true;
    wlr.enable = lib.mkForce false;
    config.hyprland = {
      default = [
        "hyprland"
        "gtk"
      ];
      "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
    };
    extraPortals = lib.mkForce [
      config.programs.hyprland.portalPackage
      pkgs.xdg-desktop-portal-gtk
      pkgs.gnome-keyring
    ];
  };
}
