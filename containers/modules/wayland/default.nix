{
  hostSocket ? "/run/user/1000/wayland-1",
  runtimeDir ? "/tmp/xdg-runtime",
  display ? "wayland-1",
}: {
  bindMounts = {
    xdg-runtime-wayland = {
      hostPath = hostSocket;
      mountPoint = "${runtimeDir}/${display}";
      isReadOnly = true;
    };
  };

  specialArgs = {
    waylandRuntimeDir = runtimeDir;
    waylandDisplay = display;
  };
}
