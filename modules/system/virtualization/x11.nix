{
  config,
  pkgs,
  ...
}: {
  # 1. Install xpra on your host so it can act as the viewer
  environment.systemPackages = [pkgs.xpra];

  containers.x11 = {
    autoStart = true;

    config = {
      config,
      pkgs,
      ...
    }: {
      programs.firefox.enable = true;
      # 2. Install xpra and your GUI apps inside the container
      environment.systemPackages = [
        pkgs.curl
        pkgs.vim
        pkgs.xeyes
        pkgs.xpra # Runs the isolated virtual X11 server
      ];

      system.stateVersion = "25.05";
    };
  };
}
