{
  config,
  pkgs,
  inputs,
  lib,
  username,
  ...
}: {
  imports = [
    # Core system
    ../../modules/system/boot.nix
    ../../modules/system/nix.nix
    ../../modules/system/locale.nix
    ../../modules/system/security.nix
    ../../modules/system/fonts.nix
    ../../modules/system/stylix.nix
    ../../modules/system/man.nix

    # Desktop & Display
    ../../modules/system/desktops/hyprland.nix

    # Networking & Services
    ../../modules/system/network/network-manager.nix
    ../../modules/system/network/firewall.nix
    ../../modules/system/services/ssh.nix
    ../../modules/system/services/bluetooth.nix

    # System tools
    ../../modules/system/programs/pkgs
    ../../modules/system/programs/nh.nix
    ../../modules/system/programs/rebuild.nix
    ../../modules/system/programs/thunar.nix

    # User
    ../../modules/users/${username}/system.nix
  ];

  networking.hostName = "yone-desktop";

  # System shell
  programs.fish.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Root access via SSH key and initial password
  users.users.root = {
    initialPassword = "yone";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE7cM18ycWHX4UkDI2rIAZMlhBp4WJ0tTMJVgNSUbrbD qylad-msi"
    ];
  };

  # SSH configuration: allow root login with SSH keys
  services.openssh.settings.PermitRootLogin = "prohibit-password";

  # Sudo configuration: wheel users need password
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # Reverse tunnel to expose SSH through NAT
  systemd.services.bore-ssh = {
    description = "Bore reverse tunnel for SSH";
    after = ["network-online.target" "sshd.service"];
    wants = ["network-online.target" "sshd.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.bore-cli}/bin/bore local 22 --to 107.175.89.174 --port 22022 --secret 50fa5365acfd162a5ddccbaf32074558";
      Restart = "always";
      RestartSec = "5s";
      DynamicUser = true;
    };
  };

  environment.systemPackages = [
    pkgs.bore-cli
  ];

  system.stateVersion = "25.11";
}
