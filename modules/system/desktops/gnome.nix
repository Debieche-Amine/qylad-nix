{
  config,
  lib,
  pkgs,
  username,
  ...
}: {
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.displayManager.autoLogin = {
    enable = true;
    user = username;
  };
}
