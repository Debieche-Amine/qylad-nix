{
  config,
  pkgs,
  ...
}: {
  containers.ssh-gui-container = {
    autoStart = true;

    config = {
      config,
      pkgs,
      ...
    }: {
      services.openssh = {
        enable = true;
        ports = [20022];

        settings = {
          X11Forwarding = true;
          AllowTcpForwarding = true;
          PermitRootLogin = "yes";
        };
      };

      # 2. Set a dummy password for local testing
      users.users.root.initialPassword = "root";

      programs.firefox.enable = true;

      environment.systemPackages = [
        pkgs.curl
        pkgs.vim
        pkgs.xeyes
      ];

      system.stateVersion = "25.05";
    };
  };
}
