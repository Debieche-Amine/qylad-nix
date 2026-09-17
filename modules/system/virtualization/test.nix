{
  config,
  pkgs,
  ...
}: {
  containers.my-container = {
    autoStart = true;

    config = {
      config,
      pkgs,
      ...
    }: {
      environment.systemPackages = [
        pkgs.curl
        pkgs.vim
      ];

      system.stateVersion = "25.05";
    };
  };
}
