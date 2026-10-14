{
  config,
  lib,
  pkgs,
  scripts,
}: let
  uwsm = lib.getExe pkgs.uwsm;
  menu = "${uwsm} app -- ${pkgs.rofi}/bin/rofi -show combi -run-command '${uwsm} app -- {cmd}'";
  logoutMenu = "${config.programs.wlogout.package}/bin/wlogout --buttons-per-row 4 --column-spacing 16 --row-spacing 16 --margin 96";
in {
  layer = "top";
  position = "top";
  height = 30;
  margin-top = 4;
  margin-left = 12;
  margin-right = 12;
  spacing = 5;

  modules-left = [
    "hyprland/submap"
    # "custom/scratchpad"
    "custom/recorder"
    "cpu"
    "memory"
    "temperature"
    "disk"
    "mpris"
  ];
  modules-center = [
    "clock"
    "custom/sleep-timer"
  ];
  modules-right = [
    "custom/netusage"
    "network"
    "bluetooth"
    "pulseaudio"
    "backlight"
    "battery"
    "custom/power-profile"
    "hyprland/language"
    "custom/notification"
  ];

  "custom/logo" = {
    format = "";
    tooltip = false;
    on-click = menu;
    on-click-right = "${uwsm} app -- ${logoutMenu}";
  };

  "custom/lane" = {
    exec = "${scripts.waybarLane}/bin/hypr-waybar-lane";
    return-type = "json";
    format = "{}";
    restart-interval = 2;
  };

  "hyprland/workspaces" = {
    active-only = false;
    all-outputs = false;
    disable-scroll = true;
    format = "{name}";
    on-click = "activate";
    sort-by-name = true;
  };

  "hyprland/submap" = {
    format = "󰌌  {}";
    tooltip = false;
    always-on = false;
  };

  "custom/scratchpad" = {
    exec = "${scripts.waybarScratchpad}/bin/hypr-waybar-scratchpad";
    return-type = "json";
    format = "{}";
    restart-interval = 2;
    on-click = "${pkgs.hyprland}/bin/hyprctl dispatch togglespecialworkspace scratchpad";
  };

  "custom/recorder" = {
    exec = "${scripts.waybarRecorder}/bin/hypr-waybar-recorder";
    return-type = "json";
    format = "{}";
    restart-interval = 2;
    signal = 8;
    on-click = "hypr-screenrecord-toggle";
  };

  "hyprland/window" = {
    format = "  {title}";
    max-length = 42;
    separate-outputs = true;
    rewrite = {
      "(.*) — Mozilla Firefox" = "  $1";
      "(.*) - Visual Studio Code" = "󰨞  $1";
      "(.*) — Vivaldi" = "󰖟  $1";
      "^$" = "Desktop";
    };
  };

  clock = {
    interval = 1;
    format = "󰃭  {:%A, %d %B  %H:%M:%S}";
    format-alt = "󰥔  {:%H:%M}";
    tooltip-format = "<tt><small>{calendar}</small></tt>";
    calendar = {
      mode = "month";
      weeks-pos = "right";
      on-scroll = 1;
      format = {
        months = "<span color='#fabd2f'><b>{}</b></span>";
        days = "<span color='#ebdbb2'>{}</span>";
        weeks = "<span color='#8ec07c'>W{}</span>";
        weekdays = "<span color='#fe8019'><b>{}</b></span>";
        today = "<span color='#1d2021' background='#fabd2f'><b>{}</b></span>";
      };
    };
  };

  mpris = {
    format = "{player_icon}  {artist} — {title}";
    format-paused = "  {artist} — {title}";
    format-stopped = "";
    max-length = 28;
    player-icons = {
      default = "";
      spotify = "";
      firefox = "";
      vlc = "󰕼";
    };
    status-icons = {
      playing = "";
      paused = "";
      stopped = "";
    };
    tooltip-format = "{player}\n{artist} — {title}\n{album}";
    on-click = "${pkgs.playerctl}/bin/playerctl play-pause";
    on-click-right = "${pkgs.playerctl}/bin/playerctl next";
  };

  cpu = {
    format = "  {usage}%";
    interval = 2;
    tooltip = true;
  };

  memory = {
    format = "  {percentage}%";
    interval = 5;
    tooltip-format = "{used:0.1f} GiB used";
  };

  disk = {
    format = "󰋊  {percentage_used}%";
    path = "/";
    interval = 30;
    tooltip-format = "{used} used of {total}";
  };

  temperature = {
    thermal-zone = 3;
    critical-threshold = 80;
    interval = 5;
    format = "  {temperatureC}°";
    format-critical = "  {temperatureC}°";
  };

  "custom/netusage" = {
    exec = "${scripts.waybarNetUsage}/bin/waybar-net-usage";
    interval = 1;
    return-type = "json";
    on-click = "${scripts.waybarNetReset}/bin/waybar-net-reset";
  };

  network = {
    interval = 3;
    format-wifi = "  {signalStrength}%";
    format-ethernet = "󰈀  wired";
    format-disconnected = "󰖪";
    tooltip-format = "{ifname}\n{essid}\n{ipaddr}";
    on-click = "${uwsm} app -- ${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
  };

  bluetooth = {
    interval = 3;
    format = " {status}";
    format-connected = " {device_alias}";
    format-connected-battery = " {device_alias} {device_battery_percentage}%";
    format-disabled = "󰂲 off";
    format-off = "󰂲 off";
    tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
    tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
    tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
    tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t({device_battery_percentage}%)";
    on-click = "${uwsm} app -- ${pkgs.blueman}/bin/blueman-manager";
    on-click-right = "${pkgs.util-linux}/bin/rfkill toggle bluetooth";
  };

  backlight = {
    format = "{icon}  {percent}%";
    format-icons = ["󰃞" "󰃟" "󰃠"];
    reverse-scrolling = true;
    on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl set 2%+";
    on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl set 2%-";
  };

  pulseaudio = {
    format = "{icon}  {volume}%";
    format-muted = "󰝟  muted";
    format-icons = {
      headphone = "";
      hands-free = "";
      headset = "󰋎";
      phone = "";
      portable = "";
      car = "";
      default = ["" "" ""];
    };
    on-click = "${uwsm} app -- ${pkgs.pavucontrol}/bin/pavucontrol";
    on-click-right = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
    on-middle-click = "${pkgs.playerctl}/bin/playerctl play-pause";
    on-scroll-up = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+";
    on-scroll-down = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-";
    tooltip-format = "{desc}\n{volume}%";
    reverse-scrolling = true;
  };

  "custom/mic" = {
    exec = "${scripts.waybarMic}/bin/waybar-mic";
    return-type = "json";
    interval = 10;
    signal = 9;
    on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && ${pkgs.procps}/bin/pkill -RTMIN+9 waybar";
  };

  battery = {
    states = {
      warning = 30;
      critical = 15;
    };
    format = "{icon}  {capacity}%";
    format-charging = "󱐋  {capacity}%";
    format-plugged = "  {capacity}%";
    format-icons = ["" "" "" "" ""];
    tooltip-format = "{timeTo}\nPower: {power} W";
  };

  "custom/power-profile" = {
    format = "{}";
    return-type = "json";
    exec = "power-profile-ctl waybar";
    interval = 3;
    signal = 8;
    on-click = "${uwsm} app -- power-profile-gui";
    tooltip = true;
  };

  "custom/sleep-timer" = {
    exec = "hypr-sleep-timer waybar";
    return-type = "json";
    interval = 1;
    signal = 10;
    on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
    on-click-right = "hypr-sleep-timer cancel";
    tooltip = true;
  };

  "hyprland/language" = {
    format = "󰌌  {short}";
    tooltip = true;
    tooltip-format = "Keyboard layout: {long}";
  };

  tray = {
    icon-size = 16;
    spacing = 8;
  };

  "custom/notification" = {
    tooltip = false;
    format = "{icon}";
    format-icons = {
      notification = "󱅫";
      none = "󰂜";
      dnd-notification = "󰂛";
      dnd-none = "󰂛";
      inhibited-notification = "󰂛";
      inhibited-none = "󰂛";
      dnd-inhibited-notification = "󰂛";
      dnd-inhibited-none = "󰂛";
    };
    return-type = "json";
    exec = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
    on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
    on-click-right = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
    escape = true;
  };
}
