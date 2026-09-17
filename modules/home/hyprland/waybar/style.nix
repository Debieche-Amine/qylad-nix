''
  /* Base colors are provided by Stylix from the active wallpaper. */
  @define-color bg alpha(@base00, 0.88);
  @define-color surface alpha(@base01, 0.94);
  @define-color raised @base02;
  @define-color text @base05;
  @define-color muted @base04;
  @define-color amber @base0A;
  @define-color orange @base09;
  @define-color red @base08;
  @define-color green @base0B;
  @define-color aqua @base0C;

  * {
    border: none;
    border-radius: 0;
    font-family: "Maple Mono NF", "FiraCode Nerd Font", monospace;
    font-size: 12px;
    min-height: 0;
  }

  window#waybar {
    background: transparent;
    color: @text;
  }

  tooltip {
    background: @surface;
    border: 1px solid alpha(@amber, 0.55);
    border-radius: 12px;
  }

  tooltip label {
    color: @text;
    padding: 6px;
  }

  #custom-logo,
  #custom-lane,
  #workspaces,
  #submap,
  #custom-scratchpad,
  #window,
  #clock,
  #mpris,
  #cpu,
  #memory,
  #disk,
  #temperature,
  #custom-netusage,
  #network,
  #backlight,
  #pulseaudio,
  #custom-mic,
  #battery,
  #language,
  #tray,
  #custom-notification {
    background: @bg;
    border: 1px solid alpha(@muted, 0.18);
    border-radius: 12px;
    padding: 0 11px;
  }

  #custom-logo {
    color: @amber;
    font-size: 18px;
    padding: 2 7px;
    border-color: alpha(@amber, 0.42);
  }

  #custom-logo:hover,
  #custom-notification:hover {
    background: @amber;
    color: @base00;
  }

  #custom-recorder.recording {
    background: alpha(@red, 0.22);
    border: 1px solid alpha(@red, 0.65);
    border-radius: 12px;
    padding: 0 11px;
    color: @red;
    font-weight: 700;
  }

  #custom-lane {
    color: @green;
    font-weight: 700;
  }

  #custom-lane.other {
    color: @muted;
  }

  #workspaces {
    padding: 0 5px;
  }

  #workspaces button {
    color: @muted;
    padding: 0 8px;
    margin: 4px 2px;
    border-radius: 8px;
    transition: all 160ms ease;
  }

  #workspaces button:hover {
    background: @raised;
    color: @text;
  }

  #workspaces button.active {
    color: @base00;
    background: linear-gradient(90deg, @amber, @orange);
    box-shadow: 0 0 8px alpha(@amber, 0.45);
  }

  #workspaces button.urgent {
    color: @base00;
    background: @red;
  }

  #submap {
    color: @orange;
  }

  #custom-scratchpad.empty {
    color: @muted;
  }

  #custom-scratchpad.occupied {
    color: @aqua;
  }

  #custom-scratchpad.active {
    color: @base00;
    background: @aqua;
  }

  #window {
    color: @text;
    min-width: 180px;
  }

  #clock {
    color: @amber;
    font-weight: 700;
    border-color: alpha(@amber, 0.35);
  }

  #mpris {
    color: @green;
  }

  #temperature.critical,
  #battery.critical,
  #custom-mic.muted {
    color: @red;
  }

  #battery.warning {
    color: @amber;
  }

  #battery.charging,
  #custom-mic.active {
    color: @green;
  }

  #network.disconnected,
  #pulseaudio.muted {
    color: @muted;
  }
''
