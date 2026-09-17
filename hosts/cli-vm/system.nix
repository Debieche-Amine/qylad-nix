{
  pkgs,
  username,
  ...
}: {
  imports = [
    ../../modules/system/nix.nix
    ../../modules/system/locale.nix
  ];

  networking.hostName = "cli-vm";

  # VM resources & terminal-only (headless) mode
  virtualisation.graphics = false;
  virtualisation.memorySize = 2048;
  virtualisation.cores = 4;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    initialPassword = "test";
  };

  services.getty.autologinUser = username;

  system.stateVersion = "25.11";
}
