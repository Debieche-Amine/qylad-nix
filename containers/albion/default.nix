let
  wayland = import ../modules/wayland {};
in {
  mkAlbionContainer = {
    username,
    sshPort,
  }: {
    autoStart = true;

    bindMounts =
      wayland.bindMounts
      // {
        project-dir = {
          hostPath = "/home/qylad/project/albion";
          mountPoint = "/app/project";
          isReadOnly = true;
        };
        user-home = {
          hostPath = "/home/qylad/project/albion/home/${username}";
          mountPoint = "/home/${username}";
          isReadOnly = false;
        };
        dev-dri = {
          hostPath = "/dev/dri";
          mountPoint = "/dev/dri";
          isReadOnly = false;
        };
      };

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
        ../modules/core.nix
        ../modules/wayland/guest.nix

        ../../modules/system/nix-ld
        ../../modules/system/locale.nix
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

      environment.systemPackages = with pkgs; [
        btop
        steam-run
        vulkan-tools
        mesa-demos
      ];

      system.stateVersion = "25.11";
    };
  };
}
