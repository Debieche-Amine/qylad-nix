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

  users.users.${username}.extraGroups = [
    "networkmanager"
  ];

  networking.networkmanager.ensureProfiles = {
    environmentFiles = ["${config.secrets.dir}/zte-usun2f/secret"];

    profiles.home = {
      connection = {
        id = "home";
        type = "wifi";
        autoconnect = true;
      };
      wifi.ssid = "ZTE_5G_uSUN2F";
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "$WIFI_PSK";
      };
      ipv4.method = "manual";
      ipv4.addresses = "192.168.1.2/24";
      ipv4.gateway = "192.168.1.1";
      ipv4.dns = "1.1.1.1";
      ipv6.method = "ignore";
    };
  };
}
