{...}: {
  imports = [
    ./binds
    ./clipboard.nix
    ./control-panel
    ./env.nix
    ./hypridle.nix
    ./hyprlock.nix
    ./hyprpaper.nix
    ./hyprtoolkit-demo
    ./hyprtoolkit-overlay
    ./packages.nix
    ./rofi.nix
    ./rofi-demo
    ./rules.nix
    ./services.nix
    ./settings.nix
    ./swaync
    ./waybar
    ./wlogout.nix
  ];

  # UWSM owns graphical-session.target and the compositor lifecycle.
  wayland.systemd.target = "graphical-session.target";
}
