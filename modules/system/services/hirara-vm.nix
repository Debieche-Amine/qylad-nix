{
  inputs,
  pkgs,
  username,
  ...
}: {
  systemd.services.hirara-vm = {
    description = "Hirara NixOS Headless VM";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    environment = {
      NIX_DISK_IMAGE = "/home/${username}/project/hirara/hirara.qcow2";
    };

    serviceConfig = {
      Type = "simple";
      User = username;
      WorkingDirectory = "/home/${username}/project/hirara";
      ExecStart = "${inputs.self.packages.${pkgs.system}.hirara}/bin/run-hirara-vm";
      Restart = "always";
      RestartSec = "10s";
      KillMode = "mixed";
      TimeoutStopSec = "30s";
    };
  };
}
