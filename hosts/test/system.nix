{
  config,
  pkgs,
  inputs,
  lib,
  username,
  ...
}: {
  imports = [
    ../../modules/system/boot.nix
    ../../modules/system/nix.nix
    ../../modules/system/locale.nix
    ../../modules/system/security.nix
    ../../modules/system/services.nix
    ../../modules/system/fonts.nix
    ../../modules/system/programs.nix
    ../../modules/system/ssh.nix
    ../../modules/system/pkgs
    ../../modules/system/desktops/gnome.nix

    ../../modules/users/${username}/system.nix
  ];

  networking.hostName = "test";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "25.11";
}
