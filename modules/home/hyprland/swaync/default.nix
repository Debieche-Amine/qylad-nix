{
  config,
  pkgs,
  ...
}: let
  colors = config.lib.stylix.colors;
  scripts = import ./scripts.nix {inherit pkgs;};
  style = import ./style.nix {inherit colors;};
in {
  home.packages = [
    scripts.hyprsunsetToggle
    scripts.idleInhibitToggle
    scripts.dndSoundSync
    pkgs.hyprsunset
  ];

  stylix.targets.swaync.enable = false;

  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;
      cssPriority = "application";
      control-center-width = 430;
      control-center-margin-top = 12;
      control-center-margin-bottom = 12;
      control-center-margin-right = 12;
      control-center-margin-left = 12;
      notification-window-width = 420;
      notification-icon-size = 54;
      notification-body-image-height = 120;
      notification-body-image-width = 220;
      timeout = 4;
      timeout-low = 2;
      timeout-critical = 0;
      override-meta-timeout = true;
      script-action = "${scripts.dndSoundSync}/bin/hypr-dnd-sound-sync";
      fit-to-screen = true;
      hide-on-clear = true;
      widgets = [
        "dnd"
        "volume"
        "backlight"
        "buttons-grid#quick-toggles"
        "title"
        "notifications"
        "mpris"
      ];
      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear All";
        };
        dnd.text = "Do Not Disturb";
        "buttons-grid#quick-toggles" = {
          buttons-per-row = 2;
          actions = [
            {
              label = "󰖨  Blue Light Filter";
              type = "toggle";
              active = false;
              command = "${scripts.hyprsunsetToggle}/bin/hypr-sunset-toggle";
              update-command = "${pkgs.procps}/bin/pgrep -x hyprsunset >/dev/null && echo true || echo false";
            }
            {
              label = "󰅶  Keep Awake";
              type = "toggle";
              active = false;
              command = "${scripts.idleInhibitToggle}/bin/hypr-idle-inhibit-toggle";
              update-command = "${pkgs.systemd}/bin/systemctl --user is-active --quiet swaync-idle-inhibit.service && echo true || echo false";
            }
          ];
        };
        volume = {
          label = "󰕾 ";
          show-per-app = true;
        };
        backlight = {
          label = "󰃠 ";
        };
        mpris = {
          image-size = 96;
          image-radius = 12;
        };
      };
    };
    style = style;
  };

  systemd.user.services.swaync-idle-inhibit = {
    Unit = {
      Description = "SwayNC Keep Awake idle inhibitor";
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=idle --who=SwayNC --why=SwayNC-Keep-Awake ${pkgs.coreutils}/bin/sleep infinity";
    };
  };
}
