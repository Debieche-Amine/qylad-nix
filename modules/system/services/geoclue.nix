{pkgs, ...}: {
  location.provider = "geoclue2";

  services.geoclue2 = {
    enable = true;
    enableWifi = true;
  };

  # Automatically update timezone based on GeoClue location
  services.automatic-timezoned.enable = true;

  # Expose where-am-i demo binary in PATH
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "where-am-i" ''
      exec ${pkgs.geoclue2}/libexec/geoclue-2.0/demos/where-am-i "$@"
    '')
  ];
}
