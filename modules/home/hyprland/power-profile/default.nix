{
  config,
  lib,
  pkgs,
  ...
}: let
  colors = config.lib.stylix.colors;

  stylixCss = pkgs.writeText "power-profile-stylix.css" ''
    @define-color base00 #${colors.base00};
    @define-color base01 #${colors.base01};
    @define-color base02 #${colors.base02};
    @define-color base03 #${colors.base03};
    @define-color base04 #${colors.base04};
    @define-color base05 #${colors.base05};
    @define-color base08 #${colors.base08};
    @define-color base0B #${colors.base0B};
    @define-color base0D #${colors.base0D};

    * {
      font-family: "Maple Mono NF", "Noto Sans", sans-serif;
      font-size: 13px;
    }

    window {
      background-color: alpha(@base00, 0.94);
      color: @base05;
    }

    .card {
      background-color: alpha(@base01, 0.85);
      border: 1px solid alpha(@base03, 0.5);
      border-radius: 14px;
      padding: 16px;
      margin: 6px 0;
    }

    .status-card {
      background-color: alpha(@base01, 0.95);
      border: 1px solid alpha(@base0D, 0.45);
      border-radius: 14px;
      padding: 14px;
      margin-bottom: 8px;
    }

    .status-title {
      font-size: 18px;
      font-weight: bold;
      color: @base0D;
    }

    .status-subtitle {
      font-size: 12px;
      color: @base04;
    }

    .profile-btn {
      background-color: alpha(@base02, 0.7);
      border: 1px solid alpha(@base03, 0.5);
      border-radius: 10px;
      padding: 10px 14px;
      font-size: 14px;
      font-weight: 600;
      color: @base05;
      transition: all 150ms ease;
    }

    .profile-btn:hover {
      background-color: alpha(@base02, 0.95);
      border-color: @base0D;
    }

    .profile-btn.active {
      background-color: @base0D;
      border-color: @base0D;
      color: @base00;
    }

    .pill-btn {
      background-color: alpha(@base02, 0.6);
      border: 1px solid alpha(@base03, 0.4);
      border-radius: 8px;
      padding: 6px 10px;
      font-size: 12px;
      color: @base05;
    }

    .pill-btn:hover {
      background-color: alpha(@base02, 0.85);
    }

    .pill-btn.active {
      background-color: @base0D;
      color: @base00;
      border-color: @base0D;
      font-weight: bold;
    }

    .step-btn {
      background-color: alpha(@base02, 0.7);
      border: 1px solid alpha(@base03, 0.5);
      border-radius: 8px;
      padding: 4px 12px;
      font-size: 14px;
      font-weight: bold;
      color: @base05;
    }

    .step-btn:hover {
      background-color: alpha(@base03, 0.9);
      border-color: @base0D;
    }

    .tier-btn {
      background-color: alpha(@base02, 0.5);
      border: 1px solid alpha(@base03, 0.35);
      border-radius: 6px;
      padding: 4px 6px;
      font-size: 11px;
      color: @base04;
    }

    .tier-btn:hover {
      background-color: alpha(@base02, 0.85);
      color: @base05;
    }

    .tier-btn.active {
      background-color: @base0D;
      color: @base00;
      border-color: @base0D;
      font-weight: bold;
    }

    .reset-btn {
      background-color: alpha(@base02, 0.7);
      border: 1px solid alpha(@base08, 0.4);
      border-radius: 10px;
      padding: 8px 16px;
      color: @base08;
    }

    .reset-btn:hover {
      background-color: alpha(@base08, 0.2);
      border-color: @base08;
    }

    .close-btn {
      background-color: alpha(@base02, 0.7);
      border: 1px solid alpha(@base03, 0.5);
      border-radius: 10px;
      padding: 8px 16px;
      color: @base05;
    }

    .close-btn:hover {
      background-color: alpha(@base03, 0.9);
    }

    scale trough {
      background-color: alpha(@base02, 0.8);
      border-radius: 6px;
      min-height: 8px;
    }

    scale highlight {
      background-color: @base0D;
      border-radius: 6px;
    }

    switch {
      border-radius: 14px;
      background-color: alpha(@base02, 0.8);
    }

    switch:checked {
      background-color: @base0D;
    }
  '';

  powerProfileCtl = pkgs.writeShellScriptBin "power-profile-ctl" ''
    export PATH="${pkgs.lib.makeBinPath [
      pkgs.coreutils
      pkgs.procps
      pkgs.python3
      pkgs.hyprland
    ]}:$PATH"
    exec ${pkgs.python3}/bin/python3 ${./ctl.py} "$@"
  '';

  pythonEnv = pkgs.python3.withPackages (ps: [ps.pygobject3]);

  powerProfileGuiRaw = pkgs.stdenv.mkDerivation {
    pname = "power-profile-gui-raw";
    version = "1.0.0";
    dontUnpack = true;

    nativeBuildInputs = [
      pkgs.wrapGAppsHook3
      pkgs.gobject-introspection
    ];

    buildInputs = [
      pkgs.gtk3
      pythonEnv
    ];

    installPhase = ''
      mkdir -p $out/bin
      install -m755 ${./gui.py} $out/bin/power-profile-gui-raw
    '';
  };

  powerProfileGui = pkgs.writeShellScriptBin "power-profile-gui" ''
    existing="$(${pkgs.hyprland}/bin/hyprctl clients -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[] | select(.class == "power-profile-gui" or .initialClass == "power-profile-gui") | .address' | head -n 1)"
    if [ -n "$existing" ]; then
      ${pkgs.hyprland}/bin/hyprctl dispatch closewindow "address:$existing"
      exit 0
    fi

    export POWER_PROFILE_CTL_BIN="${powerProfileCtl}/bin/power-profile-ctl"
    export POWER_PROFILE_CSS="${stylixCss}"
    exec ${powerProfileGuiRaw}/bin/power-profile-gui-raw "$@"
  '';
in {
  home.packages = [
    powerProfileCtl
    powerProfileGui
  ];

  wayland.windowManager.hyprland.settings.exec-once = [
    (pkgs.writeShellScript "power-profile-init" ''
      if [ "$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/ADP1/online 2>/dev/null || echo 1)" = "0" ]; then
        ${powerProfileCtl}/bin/power-profile-ctl set-profile powersaver
      else
        ${powerProfileCtl}/bin/power-profile-ctl set-profile balanced
      fi
    '').outPath
  ];
}
