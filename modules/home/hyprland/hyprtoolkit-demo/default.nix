{pkgs, ...}: let
  hyprtoolkitDemo = pkgs.stdenv.mkDerivation {
    pname = "hyprtoolkit-demo";
    version = "0.1.0";

    src = ./.;

    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
    ];

    buildInputs = with pkgs; [
      hyprtoolkit
      hyprutils
      hyprgraphics
      hyprlang
      aquamarine
      wayland
      wayland-protocols
      cairo
      pango
      fontconfig
      expat
      libdrm
      libinput
      libxkbcommon
      pixman
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp hyprtoolkit-demo $out/bin/
    '';
  };
in {
  imports = [
    ./stylix-theme.nix
  ];

  home.packages = [
    hyprtoolkitDemo
  ];
}
