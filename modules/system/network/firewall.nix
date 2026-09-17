{
  config,
  lib,
  pkgs,
  ...
}: {
  # networking.nftables.enable = false;
  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [
      9001
      # 22
      # 5000
      # 8001
    ];
    allowedTCPPortRanges = [
      {
        from = 12000;
        to = 13000;
      }
    ];
    # networking.firewall.allowedUDPPorts = [ ... ];
  };
}
