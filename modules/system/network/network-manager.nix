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
    "9.9.9.9"
    "149.112.112.112"
    "1.1.1.1"
  ];

  users.users.${username}.extraGroups = [
    "networkmanager"
  ];
  networking.networkmanager.wifi.powersave = true;
}
