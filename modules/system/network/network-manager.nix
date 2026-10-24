{
  config,
  lib,
  pkgs,
  username,
  ...
}: {
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "none";

  networking.useDHCP = false;
  networking.dhcpcd.enable = false;

  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
    "8.8.8.8"
  ];

  users.users.${username}.extraGroups = [
    "networkmanager"
  ];
  networking.networkmanager.wifi.powersave = true;
}
