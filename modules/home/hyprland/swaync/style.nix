{colors}: ''
  @define-color base00 #${colors.base00};
  @define-color base01 #${colors.base01};
  @define-color base02 #${colors.base02};
  @define-color base03 #${colors.base03};
  @define-color base04 #${colors.base04};
  @define-color base05 #${colors.base05};
  @define-color base06 #${colors.base06};
  @define-color base07 #${colors.base07};
  @define-color base08 #${colors.base08};
  @define-color base09 #${colors.base09};
  @define-color base0A #${colors.base0A};
  @define-color base0B #${colors.base0B};
  @define-color base0C #${colors.base0C};
  @define-color base0D #${colors.base0D};
  @define-color base0E #${colors.base0E};
  @define-color base0F #${colors.base0F};

  * {
    font-family: "Maple Mono NF", "FiraCode Nerd Font", sans-serif;
    font-size: 14px;
    transition: 200ms all ease-in-out;
  }

  /* Control Center Panel Window */
  .control-center {
    background-color: alpha(@base00, 0.82);
    border: 1px solid alpha(@base0D, 0.4);
    border-radius: 16px;
    box-shadow: 0 8px 32px 0 alpha(@base00, 0.65);
    padding: 16px;
    margin: 12px;
  }

  /* Clean Notification Cards & Row Selection */
  .control-center-list {
    background: transparent;
  }

  .control-center-list > row,
  .notification-row {
    background: transparent;
    border: none;
    box-shadow: none;
    outline: none;
    padding: 0;
    margin: 4px 0px;
  }

  .control-center-list > row:focus,
  .control-center-list > row:hover,
  .control-center-list > row:selected,
  .notification-row:focus,
  .notification-row:hover,
  .notification-row:selected {
    background: transparent;
    border: none;
    box-shadow: none;
    outline: none;
  }

  .notification {
    background-color: alpha(@base01, 0.85);
    border: 1px solid alpha(@base03, 0.45);
    border-radius: 12px;
    padding: 10px 12px;
    box-shadow: none;
    margin: 0;
    transition: background-color 160ms ease, border-color 160ms ease;
  }

  .notification-row:hover .notification,
  .notification-row:focus .notification,
  .notification-row:selected .notification,
  .control-center-list > row:hover .notification,
  .control-center-list > row:focus .notification,
  .control-center-list > row:selected .notification {
    background-color: alpha(@base02, 0.92);
    border-color: alpha(@base0D, 0.55);
  }

  .notification-content {
    background: transparent;
    border: none;
    padding: 0;
  }

  .notification-default-action {
    background: transparent;
    border: none;
    box-shadow: none;
    padding: 0;
    margin: 0;
  }

  .notification-default-action:hover,
  .notification-default-action:focus {
    background: transparent;
    border: none;
    box-shadow: none;
  }

  .notification-action {
    padding: 6px 12px;
    margin: 4px 2px 0 2px;
    border-radius: 8px;
    background: alpha(@base02, 0.75);
    border: 1px solid alpha(@base0D, 0.25);
    color: @base05;
  }

  .notification-action:hover {
    background: alpha(@base0D, 0.35);
    color: @base07;
  }

  .close-button {
    background: alpha(@base02, 0.7);
    color: @base05;
    border-radius: 50%;
    padding: 4px;
    margin: 4px;
    border: none;
  }

  .close-button:hover {
    background: @base08;
    color: @base00;
  }

  /* Header / Title Widget (placed directly above notifications) */
  .widget-title {
    color: @base0D;
    font-weight: bold;
    font-size: 15px;
    margin: 12px 4px 6px 4px;
  }

  .widget-title > button {
    font-size: 13px;
    color: @base05;
    background: alpha(@base02, 0.85);
    border: 1px solid alpha(@base0D, 0.3);
    border-radius: 8px;
    padding: 4px 12px;
  }

  .widget-title > button:hover {
    background: @base08;
    color: @base00;
  }

  /* DND Switch Widget */
  .widget-dnd {
    background: alpha(@base01, 0.65);
    border: 1px solid alpha(@base03, 0.45);
    border-radius: 12px;
    padding: 8px 14px;
    margin: 6px 0;
    color: @base05;
  }

  .widget-dnd label {
    font-size: 14px;
    color: @base05;
    margin-right: 10px;
  }

  .widget-dnd > switch {
    border-radius: 12px;
    background-color: alpha(@base00, 0.95);
    border: 1px solid alpha(@base03, 0.5);
  }

  .widget-dnd > switch:checked {
    background-color: @base0D;
    border-color: @base0D;
  }

  .widget-dnd > switch slider {
    background: @base05;
    border-radius: 50%;
  }

  /* Quick toggles. */
  .widget-buttons-grid {
    background: transparent;
    border: none;
    padding: 0;
    margin: 0;
  }

  .widget-buttons-grid flowboxchild {
    padding: 0;
    margin: 3px 4px;
  }

  .widget-buttons-grid flowboxchild > button {
    background-color: alpha(@base01, 0.65);
    border: 1px solid alpha(@base03, 0.45);
    border-radius: 12px;
    padding: 8px 10px;
    color: @base05;
    font-size: 14px;
    font-weight: normal;
    text-align: center;
    box-shadow: none;
  }

  .widget-buttons-grid flowboxchild > button:hover {
    background-color: alpha(@base02, 0.85);
    border-color: alpha(@base0D, 0.5);
  }

  .widget-buttons-grid flowboxchild > button.toggle:checked,
  .widget-buttons-grid flowboxchild > button.toggle.active {
    background-color: alpha(@base0D, 0.85);
    border-color: @base0D;
    color: @base00;
  }

  /* Volume & Backlight Sliders */
  .widget-volume,
  .widget-backlight {
    background: alpha(@base01, 0.65);
    border: 1px solid alpha(@base03, 0.45);
    border-radius: 12px;
    padding: 8px 14px;
    margin: 6px 0;
    color: @base05;
  }

  .widget-volume label,
  .widget-backlight label {
    font-size: 15px;
    color: @base05;
    margin-right: 10px;
  }

  .widget-volume scale trough,
  .widget-backlight scale trough {
    border-radius: 8px;
    background-color: alpha(@base02, 0.85);
    min-height: 8px;
  }

  .widget-volume scale trough highlight,
  .widget-backlight scale trough highlight {
    border-radius: 8px;
    background-color: @base0D;
  }

  .widget-volume scale slider,
  .widget-backlight scale slider {
    background: @base05;
    border-radius: 50%;
    min-width: 14px;
    min-height: 14px;
  }

  /* MPRIS Media Player Card */
  .widget-mpris {
    background: alpha(@base01, 0.65);
    border: 1px solid alpha(@base03, 0.45);
    border-radius: 14px;
    padding: 12px;
    margin: 6px 0;
  }

  .widget-mpris-player {
    background: transparent;
  }

  .widget-mpris-title {
    font-weight: bold;
    font-size: 14px;
    color: @base05;
  }

  .widget-mpris-subtitle {
    font-size: 12px;
    color: @base04;
  }

  .widget-mpris > box > button {
    background: transparent;
    color: @base05;
    border: none;
    box-shadow: none;
    border-radius: 8px;
    padding: 6px 12px;
    margin: 0 2px;
  }

  .widget-mpris > box > button:hover {
    background: alpha(@base0D, 0.25);
    color: @base0D;
  }
''
