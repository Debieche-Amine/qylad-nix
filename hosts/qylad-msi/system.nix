# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  lib,
  username,
  ...
}: let
  inherit (import ../../containers/albion) mkAlbionContainer;
  inherit (import ../../containers/wayland-test) mkWaylandTestContainer;
  inherit (import ../../containers/fabrik) mkFabrikContainer;
  inherit (import ../../containers/gnome) mkGnomeContainer;
in {
  imports = [
    ../../modules/system/desktops/hyprland.nix
    ../../modules/system/locale.nix
    ../../modules/system/boot.nix
    ../../modules/system/man.nix
    ../../modules/system/fonts.nix
    ../../modules/system/stylix.nix
    # ../../modules/system/nix-ld
    ../../modules/system/nix.nix
    ../../modules/system/security.nix
    ../../modules/system/secrets.nix
    ../../modules/system/virtualization
    ../../modules/system/ram-tmpfs.nix

    ../../modules/system/services/duckdns.nix
    # ../../modules/system/services/sql.nix
    # ../../modules/system/services/postgresql.nix
    ../../modules/system/services/ssh.nix
    # ../../modules/system/services/litellm
    # ../../modules/system/services/ollama.nix
    ../../modules/system/services/extra.nix
    # ../../modules/system/services/agent-zero.nix
    # ../../modules/system/services/tor.nix
    ../../modules/system/services/ip-monitor.nix
    ../../modules/system/services/ydotool.nix
    # ../../modules/system/services/tlp.nix
    # ../../modules/system/services/good-morning-chatgpt.nix
    ../../modules/system/services/upower.nix
    ../../modules/system/services/geoclue.nix
    # ../../modules/system/services/hirara-vm.nix
    # ../../modules/system/services/yss-vm.nix
    # ../../modules/system/services/baratis-vm.nix
    ../../modules/system/services/mtp.nix
    ../../modules/system/services/bluetooth.nix

    ../../modules/system/programs/android
    ../../modules/system/programs/esp.nix
    ../../modules/system/programs/pkgs
    ../../modules/system/programs/nh.nix
    ../../modules/system/programs/rebuild.nix
    ../../modules/system/programs/thunar.nix
    ../../modules/system/programs/extra.nix
    ../../modules/system/programs/steam.nix
    ../../modules/system/programs/wine.nix
    ../../modules/system/programs/appimage.nix

    ../../modules/system/network/firewall.nix
    ../../modules/system/network/network-manager.nix
    ../../modules/system/network/zte-usun2f.nix

    ../../modules/users/${username}/system.nix
  ];
  users.mutableUsers = false;

  networking.hostName = "qylad-msi";

  containers = {
    #   container-albion-1 = mkAlbionContainer {
    #     username = "albion-1";
    #     sshPort = 20101;
    #   };
    #   container-albion-2 = mkAlbionContainer {
    #     username = "albion-2";
    #     sshPort = 20102;
    #   };
    #   container-albion-3 = mkAlbionContainer {
    #     username = "albion-3";
    #     sshPort = 20103;
    #   };
    #   container-albion-4 = mkAlbionContainer {
    #     username = "albion-4";
    #     sshPort = 20104;
    #   };
    container-wayland-test = mkWaylandTestContainer {
      username = "wayland-test";
      sshPort = 20000;
    };
    container-gnome = mkGnomeContainer {
      autoStart = false;
      username = "gnome";
      sshPort = 20001;
      noVncPort = 6080;
      vncPort = 5900;
      resolution = "1920x1080";
    };
    # fabrik = mkFabrikContainer {
    #   inherit inputs;
    #   username = "fabrik";
    # };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
