{pkgs, ...}: {
  virtualisation.oci-containers = {
    containers.agent-zero = {
      autoStart = true;

      image = "agent0ai/agent-zero";

      ports = [
        "12200:80"
        # "7878:7878"
        # "7979:7979"
      ];

      volumes = [
        "a0_usr:/a0/usr"
      ];
    };
  };
}
