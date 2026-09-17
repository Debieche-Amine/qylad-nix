{
  inputs,
  pkgs,
  username,
  ...
}: {
  systemd.services.baratis-vm = {
    description = "Baratis NixOS Headless VM";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    environment = {
      NIX_DISK_IMAGE = "/home/${username}/project/hirara/baratis.qcow2";
    };

    serviceConfig = {
      Type = "simple";
      User = username;
      WorkingDirectory = "/home/${username}/project/hirara";
      ExecStart = "${inputs.self.packages.${pkgs.system}.baratis}/bin/run-baratis-vm";
      Restart = "always";
      RestartSec = "10s";
      KillMode = "mixed";
      TimeoutStopSec = "30s";
    };
  };
}
