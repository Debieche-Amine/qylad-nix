{
  mkGnomeContainer = {
    username ? "gnome",
    sshPort ? 20001,
    noVncPort ? 6080,
    vncPort ? 5900,
    resolution ? "1920x1080",
    vncPassword ? null,
    autoStart ? true,
  }: {
    inherit autoStart;

    specialArgs = {
      containerUsername = username;
      inherit sshPort noVncPort vncPort resolution vncPassword;
    };

    config = {
      containerUsername,
      pkgs,
      lib,
      sshPort,
      noVncPort,
      vncPort,
      resolution,
      vncPassword,
      ...
    }: let
      startScript = pkgs.writeShellScriptBin "start-gnome-novnc" ''
        set -euo pipefail

        export HOME="/home/${containerUsername}"
        export USER="${containerUsername}"
        export DISPLAY=:1
        export RESOLUTION="${resolution}"
        export LIBGL_ALWAYS_SOFTWARE=1
        export GALLIUM_DRIVER=llvmpipe
        export XDG_CURRENT_DESKTOP="GNOME"
        export XDG_SESSION_DESKTOP="gnome"
        export XDG_SESSION_TYPE="x11"

        mkdir -p "$HOME/.config" "$HOME/Desktop"
        rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

        echo "==> Starting Xvfb on display :1 (resolution ''${RESOLUTION})..."
        ${pkgs.xorg.xorgserver}/bin/Xvfb :1 -screen 0 "''${RESOLUTION}x24" -ac +extension GLX +render -noreset &
        XVFB_PID=$!

        echo "==> Waiting for Xvfb on display :1..."
        for i in $(seq 1 50); do
          if ${pkgs.xdotool}/bin/xdotool getdisplaygeometry >/dev/null 2>&1; then
            echo "==> Xvfb display :1 is ready!"
            break
          fi
          sleep 0.1
        done

        # Clipboard synchronization
        ${pkgs.autocutsel}/bin/autocutsel -selection CLIPBOARD &
        ${pkgs.autocutsel}/bin/autocutsel -selection PRIMARY &

        # Start x11vnc server
        echo "==> Starting x11vnc on port ${toString vncPort}..."
        ${
          if vncPassword != null
          then ''
            mkdir -p "$HOME/.vnc"
            ${pkgs.x11vnc}/bin/x11vnc -storepasswd "${vncPassword}" "$HOME/.vnc/passwd"
            ${pkgs.x11vnc}/bin/x11vnc -display :1 -forever -shared -repeat -wait 50 -rfbport ${toString vncPort} -rfbauth "$HOME/.vnc/passwd" &
          ''
          else ''
            ${pkgs.x11vnc}/bin/x11vnc -display :1 -forever -shared -repeat -wait 50 -rfbport ${toString vncPort} -nopw &
          ''
        }

        # Start noVNC web server
        echo "==> Starting noVNC on port ${toString noVncPort}..."
        ${pkgs.novnc}/bin/novnc --listen ${toString noVncPort} --vnc localhost:${toString vncPort} &

        # Start GNOME desktop session
        echo "==> Starting GNOME desktop session..."
        if ! ${pkgs.dbus}/bin/dbus-run-session ${pkgs.gnome-session}/bin/gnome-session; then
          echo "==> Falling back to GNOME Flashback..."
          ${pkgs.dbus}/bin/dbus-run-session ${pkgs.gnome-session}/bin/gnome-session --session=gnome-flashback-metacity
        fi

        wait $XVFB_PID
      '';
    in {
      imports = [
        ../modules/core.nix
        ../../modules/system/locale.nix
      ];

      nixpkgs.config.allowUnfree = true;

      # Enable GNOME desktop manager without starting local hardware display manager
      services.xserver = {
        enable = true;
        displayManager.startx.enable = true;
      };

      services.desktopManager.gnome = {
        enable = true;
        flashback.enableMetacity = true;
      };

      services.displayManager.gdm.enable = false;

      hardware.graphics.enable = true;

      # System packages inside the container
      environment.systemPackages = with pkgs; [
        xorg.xorgserver
        x11vnc
        novnc
        xdotool
        autocutsel
        firefox
        gnome-terminal
        nautilus
      ];

      # Ensure /tmp/.X11-unix exists with correct sticky permissions
      systemd.tmpfiles.rules = [
        "d /tmp/.X11-unix 1777 root root -"
      ];

      # Systemd service running the virtual display, desktop environment and noVNC
      systemd.services.gnome-novnc = {
        description = "GNOME Desktop with noVNC";
        after = ["network.target"];
        wantedBy = ["multi-user.target"];

        path = with pkgs; [
          xorg.xorgserver
          x11vnc
          novnc
          bash
          coreutils
          procps
          dbus
          xdotool
          autocutsel
          gnome-session
          gnome-shell
          gnome-flashback
          metacity
          gnome-terminal
          nautilus
        ];

        environment = {
          HOME = "/home/${containerUsername}";
          USER = containerUsername;
          DISPLAY = ":1";
          LIBGL_ALWAYS_SOFTWARE = "1";
          GALLIUM_DRIVER = "llvmpipe";
          XDG_CURRENT_DESKTOP = "GNOME";
          XDG_SESSION_DESKTOP = "gnome";
          XDG_SESSION_TYPE = "x11";
        };

        serviceConfig = {
          User = containerUsername;
          Group = "users";
          WorkingDirectory = "/home/${containerUsername}";
          ExecStart = "${startScript}/bin/start-gnome-novnc";
          Restart = "always";
          RestartSec = 5;
        };
      };

      networking.firewall.allowedTCPPorts =
        [
          noVncPort
          vncPort
        ]
        ++ lib.optional (sshPort != null) sshPort;

      services.openssh = lib.mkIf (sshPort != null) {
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
        shell = pkgs.bashInteractive;
        password = "gnome";
        extraGroups = ["wheel" "video" "audio"];
      };

      system.stateVersion = "25.11";
    };
  };
}
