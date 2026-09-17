let
  wayland = import ../modules/wayland {};
in {
  mkWaylandTestContainer = {
    username,
    sshPort,
  }: {
    autoStart = true;

    bindMounts = wayland.bindMounts;

    specialArgs =
      wayland.specialArgs
      // {
        containerUsername = username;
        waylandUser = username;
        inherit sshPort;
      };

    config = {
      containerUsername,
      pkgs,
      sshPort,
      ...
    }: {
      imports = [
        ../modules/wayland/guest.nix
        ../modules/core.nix

        ../../modules/system/locale.nix
      ];
      environment.systemPackages = with pkgs; [
        vscode
      ];
      nixpkgs.config.allowUnfree = true;

      programs.firefox.enable = true;
      programs.fish.enable = true;

      hardware.graphics.enable = true;

      networking.firewall.allowedTCPPorts = [sshPort];

      services.openssh = {
        enable = true;
        ports = [sshPort];
        settings = {
          AllowTcpForwarding = true;
          PermitRootLogin = "yes";
        };
      };

      users.users.${containerUsername} = {
        isNormalUser = true;
        home = "/home/${containerUsername}";
        uid = 1000;
        shell = pkgs.fish;
        password = "aze";
        extraGroups = ["wheel" "video" "render"];
      };

      system.stateVersion = "25.11";
    };
  };
}
