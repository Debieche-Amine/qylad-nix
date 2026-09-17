{
  pkgs,
  username,
  ...
}: {
  services.tor = {
    enable = true;

    relay = {
      enable = true;
      role = "relay";
      port = 9001;
    };
    controlSocket.enable = true;

    settings = {
      Nickname = "hmm";
      ContactInfo = "savings_suggest795@simplelogin.com";

      # Optional: Resource and Bandwidth Limits
      BandwidthRate = "10 MBytes"; # Average sustained bandwidth usage
      BandwidthBurst = "20 MBytes"; # Maximum peak bandwidth usage
      MaxMemInQueues = "512 MB"; # Memory limit for Tor queues

      ORPort = 9001;
    };
  };
  users.users.${username} = {
    extraGroups = ["tor"];
  };

  environment.systemPackages = with pkgs; [
    nyx
  ];
  networking.firewall = {
    allowedTCPPorts = [9001];
  };
}
