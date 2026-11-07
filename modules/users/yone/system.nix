{
  pkgs,
  lib,
  username,
  ...
}: {
  users.users.${username} = {
    isNormalUser = true;
    description = "Yone";
    initialPassword = "yone";
    shell = pkgs.fish;
    extraGroups = lib.mkAfter [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "input"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE7cM18ycWHX4UkDI2rIAZMlhBp4WJ0tTMJVgNSUbrbD qylad-msi"
    ];
    linger = true;
  };
}
