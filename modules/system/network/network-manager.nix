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
  networking.networkmanager.wifi.powersave = false;

  boot.extraModprobeConfig = ''
    options iwlwifi power_save=0
    options iwlmvm power_scheme=1
    options iwlwifi uapsd_disable=1
    options iwlwifi d0i3_disable=1
  '';
}
