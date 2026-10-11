{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    gcc
    gnumake
    pkg-config
    openssl
    cargo
    rustc
    clippy
    rustfmt
    rust-analyzer
  ];
}
