{pkgs, ...}: {
  home.packages = with pkgs; [
    python3
    alejandra
    nil
    nixd
  ];
}
