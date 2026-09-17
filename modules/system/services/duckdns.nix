{
  config,
  lib,
  pkgs,
  username,
  ...
}: {
  services.ddclient = {
    enable = true;
    protocol = "duckdns";
    username = "";

    passwordFile = "${config.secrets.dir}/duckdns";
    domains = [
      "qylad.duckdns.org"
      "qylad-home.duckdns.org"
      # "qylad-server.duckdns.org"
      "debiecheamine.duckdns.org"
    ];

    usev4 = "webv4, webv4=ipify-ipv4";
    usev6 = "disabled";
    ssl = true;
    interval = "5min";
  };
}
