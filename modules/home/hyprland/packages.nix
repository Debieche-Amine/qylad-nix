{pkgs, ...}: {
  home.packages = with pkgs; [
    swayimg
  ];

  programs.swayimg.enable = true;
}
