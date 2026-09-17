{
  config,
  pkgs,
  ...
}: {
  # Enable documentation and man pages
  documentation.enable = true;
  documentation.man.enable = true;
  documentation.doc.enable = true;
  documentation.nixos.enable = true;
  # documentation.nixos.includeAllModules = true;

  # Optional: Enable man pages for development libraries/tools
  documentation.dev.enable = true;

  environment.systemPackages = with pkgs; [
    man-pages # POSIX and Linux extra man pages
    man-pages-posix # POSIX specific man pages
    less
  ];
}
