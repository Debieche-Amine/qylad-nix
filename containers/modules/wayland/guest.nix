{
  pkgs,
  waylandDisplay ? "wayland-1",
  waylandRuntimeDir ? "/tmp/xdg-runtime",
  waylandUser ? "root",
  ...
}: {
  systemd.tmpfiles.rules = [
    "d ${waylandRuntimeDir} 0755 ${waylandUser} users -"
  ];

  environment.sessionVariables = {
    XDG_RUNTIME_DIR = waylandRuntimeDir;
    WAYLAND_DISPLAY = waylandDisplay;
  };

  environment.systemPackages = with pkgs; [
    wayland
    wayland-utils
  ];
}
