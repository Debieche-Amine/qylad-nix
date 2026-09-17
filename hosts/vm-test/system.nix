{pkgs, ...}: {
  imports = [
    ../../modules/system/nix.nix
  ];

  networking.hostName = "vm-test";

  users.users.test = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    initialPassword = "test";
  };

  services.getty.autologinUser = "test";

  system.stateVersion = "25.11";
}
