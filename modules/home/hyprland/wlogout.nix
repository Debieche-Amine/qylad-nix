{
  config,
  pkgs,
  ...
}: let
  colors = config.lib.stylix.colors;
  wlogout = pkgs.wlogout.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./wlogout-hjkl.patch];
  });
in {
  programs.wlogout = {
    enable = true;
    package = wlogout;
    layout = [
      {
        label = "lock";
        action = "${pkgs.hyprlock}/bin/hyprlock";
        text = "󰌾  Lock";
        keybind = "o";
        height = 0.5;
        width = 0.5;
      }
      {
        label = "logout";
        action = "${pkgs.hyprland}/bin/hyprctl dispatch exit";
        text = "󰍃  Logout";
        keybind = "e";
        height = 0.5;
        width = 0.5;
      }
      {
        label = "suspend";
        action = "${pkgs.systemd}/bin/systemctl suspend";
        text = "󰤄  Suspend";
        keybind = "u";
        height = 0.5;
        width = 0.5;
      }
      {
        label = "hibernate";
        action = "${pkgs.systemd}/bin/systemctl hibernate";
        text = "󰒲  Hibernate";
        keybind = "i";
        height = 0.5;
        width = 0.5;
      }
      {
        label = "hibernate-then-sleep";
        action = "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
        text = "󰤂  Sleep then hibernate";
        keybind = "y";
        height = 0.5;
        width = 0.5;
      }
      {
        label = "firmware";
        action = "${pkgs.systemd}/bin/systemctl reboot --firmware-setup";
        text = "󰻀  UEFI setup";
        keybind = "f";
        height = 0.5;
        width = 0.5;
      }
      {
        label = "reboot";
        action = "${pkgs.systemd}/bin/systemctl reboot";
        text = "󰜉  Reboot";
        keybind = "r";
        height = 0.5;
        width = 0.5;
      }
      {
        label = "shutdown";
        action = "${pkgs.systemd}/bin/systemctl poweroff";
        text = "  Shut down";
        keybind = "s";
        height = 0.5;
        width = 0.5;
      }
    ];
    style = ''
      /* Use the same Stylix-generated palette as the rest of the desktop. */
      @define-color base00 #${colors.base00};
      @define-color base01 #${colors.base01};
      @define-color base05 #${colors.base05};
      @define-color base08 #${colors.base08};
      @define-color base09 #${colors.base09};
      @define-color base0A #${colors.base0A};
      @define-color base0B #${colors.base0B};
      @define-color base0C #${colors.base0C};

      * {
        font-family: "Maple Mono NF", "FiraCode Nerd Font", sans-serif;
        font-size: 15px;
        color: @base05;
      }

      window {
        background-color: alpha(@base00, 0.42);
      }

      /* Wlogout expands its grid cells to fill the monitor. Keep those cells
         invisible and draw compact, centered cards with the label instead. */
      button {
        background: transparent;
        border: none;
        box-shadow: none;
        background-image: none;
      }

      button:focus {
        outline: none;
      }

      button label {
        /* Labels expand with their buttons; margins carve compact cards out
           of the otherwise full-screen grid cells. */
        background-color: alpha(@base01, 0.92);
        border: 1px solid alpha(@base05, 0.16);
        border-radius: 14px;
        margin: 110px 90px;
        min-width: 142px;
        min-height: 48px;
        padding: 16px 20px;
        box-shadow: 0 10px 24px alpha(@base00, 0.38);
        transition: background-color 160ms ease, border-color 160ms ease;
      }

      /* Session · sleep · system/power categories. */
      #lock label,
      #logout label {
        border-color: alpha(@base0C, 0.55);
      }

      #suspend label,
      #hibernate label,
      #hibernate-then-sleep label {
        border-color: alpha(@base0B, 0.55);
      }

      #firmware label,
      #reboot label {
        border-color: alpha(@base09, 0.55);
      }

      #shutdown label {
        border-color: alpha(@base08, 0.65);
      }

      /* Do not preselect an action just because the pointer happened to be
         resting over it when the menu opened. Keyboard focus stays visible. */
      button:focus label {
        background-color: @base0A;
        color: @base00;
        border-color: @base09;
      }

      #shutdown:focus label {
        background-color: @base08;
        border-color: @base08;
      }
    '';
  };
}
