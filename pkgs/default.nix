{pkgs ? import <nixpkgs> {config.allowUnfree = true;}}: {
  albion-online = pkgs.callPackage ./albion-online {};
  albion-nix = pkgs.callPackage ./albion-online {};
  colab-cli = pkgs.callPackage ./colab-cli {};
}
