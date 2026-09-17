{pkgs, ...}: {
  systemd.services.ip-logger = {
    description = "Fetch and log public IP address";
    path = [pkgs.curl];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.curl}/bin/curl -s https://ifconfig.me";
    };
  };

  systemd.timers.ip-logger = {
    description = "Trigger IP logging every 8 hours";
    wantedBy = ["timers.target"];

    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "8h";
      Unit = "ip-logger.service";
    };
  };
}
