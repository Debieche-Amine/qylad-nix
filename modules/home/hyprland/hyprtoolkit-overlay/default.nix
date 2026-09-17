{pkgs, ...}: let
  hyprtoolkitOverlay = pkgs.stdenv.mkDerivation {
    pname = "hyprtoolkit-overlay";
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
      cp hyprtoolkit-overlay $out/bin/
    '';
  };
in {
  home.packages = [
    hyprtoolkitOverlay
  ];
}
