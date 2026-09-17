{
  pkgs,
  username,
  workspaceSource,
  sshPort ? 2222,
  agentArgs ? "",
  enableAgent ? true,
  ...
}: {
  imports = [
    ../../modules/system/locale.nix
    ../../modules/system/nix.nix
  ];

  networking.hostName = username;

  # Terminal-only (headless) mode & VM resources
  virtualisation.graphics = false;
  virtualisation.memorySize = 4096;
  virtualisation.cores = 4;
  virtualisation.diskSize = 10240;

  # SSH port forwarding
  virtualisation.forwardPorts = [
    {
      from = "host";
      host.port = sshPort;
      guest.port = 22;
    }
  ];

  # Mount workspace directory into VM
  virtualisation.sharedDirectories = {
    "${username}-workspace" = {
      source = workspaceSource;
      target = "/home/${username}/${username}";
    };
  };

  # SSH Service with X11 Forwarding enabled
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
      X11Forwarding = true;
    };
  };

  # Passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  environment.enableAllTerminfo = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    python3
    chromium
    xauth
    kitty.terminfo
    curl
    wget
    htop
    btop
    jq
    ripgrep
    fd
    tree
    unzip
    zip
    tmux
    rsync
  ];

  programs.ssh.setXAuthLocation = true;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    hashedPassword = "$y$j9T$ao7CMz4TAK4ilLk8OTumT0$iC4ay.JVmZnu9reuVRZMHt6sFE3iVzSmcUsKUdvGDdB";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE7cM18ycWHX4UkDI2rIAZMlhBp4WJ0tTMJVgNSUbrbD qylad-msi"
    ];
  };

  environment.sessionVariables = {
    XDG_CACHE_HOME = "/tmp/cache";
  };

  # Systemd service for agent
  systemd.services."${username}-agent" = {
    enable = enableAgent;
    description = "${username} Agent Service";
    wantedBy =
      if enableAgent
      then ["multi-user.target"]
      else [];
    after = ["network.target"];
    path = with pkgs; [
      bash
      coreutils
      git
      jq
      nix
      python3
      chromium
      pkgs.unstable.antigravity-cli
    ];
    environment = {
      HOME = "/home/${username}";
      XDG_CACHE_HOME = "/tmp/cache";
    };
    serviceConfig = {
      Type = "simple";
      User = username;
      WorkingDirectory = "/home/${username}/${username}";
      ExecStart = "${pkgs.bash}/bin/bash run.sh ${agentArgs}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  services.getty.autologinUser = username;

  system.stateVersion = "25.11";
}
