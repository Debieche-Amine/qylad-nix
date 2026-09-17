{
  pkgs,
  config,
  ...
}: {
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
  environment.systemPackages = [
    pkgs.appimage-run
  ];
}
