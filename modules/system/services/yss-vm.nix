{
  inputs,
  pkgs,
  username,
  ...
}: {
  systemd.services.yss-vm = {
    description = "YSS NixOS Headless VM";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    environment = {
      NIX_DISK_IMAGE = "/home/${username}/project/hirara/yss.qcow2";
    };

    serviceConfig = {
      Type = "simple";
      User = username;
      WorkingDirectory = "/home/${username}/project/hirara";
      ExecStart = "${inputs.self.packages.${pkgs.system}.yss}/bin/run-yss-vm";
      Restart = "always";
      RestartSec = "10s";
      KillMode = "mixed";
      TimeoutStopSec = "30s";
    };
  };
}
