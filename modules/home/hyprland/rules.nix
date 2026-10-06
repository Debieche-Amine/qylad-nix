{
  config,
  lib,
  ...
}: {
  wayland.windowManager.hyprland.settings = {
    workspace = [
      "name:A:0, default:true"
      "name:Z:0, layout:master"
      "name:Z:-1, layout:master"
      "special:scratchpad, gapsin:12, gapsout:28"
      "special:s1, gapsin:12, gapsout:28"
      "special:s2, gapsin:12, gapsout:28"
      "special:s3, gapsin:12, gapsout:28"
      "w[tv1], gapsout:0, gapsin:0"
      "f[1], gapsout:0, gapsin:0"
    ];

    windowrule = [
      "match:initial_title ^Steam - Update News$, float on"
      "match:class ^(Pavucontrol|pavucontrol)$, float on, size 850 560, center on"
      "match:float true, border_color rgb(${config.lib.stylix.colors.base0B})"
      "match:title ^Picture-in-Picture$, float on, pin on"
      "match:class ^(nm-connection-editor|blueman-manager)$, float on, center on"
      "match:title ^(Open File|Save File|Select a File|File Upload)$, float on, center on"
      "match:class ^(excalidraw)$, workspace special:s1, fullscreen on"
      "match:class ^(hypr-control-panel)$, float on, size 1360 780, center on"
      "match:class ^(power-profile-gui)$, float on, size 540 620, center on"
    ];

    layerrule = [
      "match:namespace rofi, blur on"
      "match:namespace rofi, ignore_alpha 0.2"
      "match:namespace swaync-control-center, blur on"
      "match:namespace swaync-notification-window, blur on"
      "match:namespace waybar, blur on"
      "match:namespace waybar, ignore_alpha 0.2"
      "match:namespace logout_dialog, blur on"
      "match:namespace logout_dialog, ignore_alpha 0.2"
      "match:namespace swayosd, blur on"
      "match:namespace swayosd, ignore_alpha 0.2"
    ];
  };
}
