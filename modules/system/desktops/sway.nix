{
  config,
  pkgs,
  ...
}: {
  programs.sway = {
    enable = true;
    xwayland.enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = [];
  };

  services.gnome.gnome-keyring.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${config.programs.sway.package}/bin/sway";
      };
    };
  };

  security.pam.services = {
    # Unlock the existing login keyring after signing in through greetd
    greetd.enableGnomeKeyring = true;
    # Synchronize it if `passwd` changes the account password.
    passwd.enableGnomeKeyring = true;
  };

  xdg.portal = {
    enable = true;
    config.sway."org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
  };
}
