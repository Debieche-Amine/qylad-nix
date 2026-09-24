{pkgs, ...}: {
  home.packages = [
    pkgs.mission-center
    pkgs.burpsuite
    pkgs.obs-studio
    pkgs.vlc
    pkgs.motrix
    pkgs.zed-editor
    pkgs.rio
    pkgs.wezterm
    (pkgs.vivaldi.override {
      commandLineArgs = "--password-store=gnome-libsecret";
    })
    pkgs.discord
    pkgs.spotify
    pkgs.musescore
    pkgs.gnome-weather
    pkgs.libreoffice

    pkgs.kdePackages.kate
    pkgs.kdePackages.dolphin

    pkgs.bolt-launcher
    pkgs.proton-vpn
    (pkgs.chromium.override {
      commandLineArgs = "--password-store=gnome-libsecret";
    })
    pkgs.nyxt
    pkgs.floorp-bin
    pkgs.unstable.antigravity-ide
    pkgs.tigervnc
    pkgs.remmina
    pkgs.kdePackages.krdc
    pkgs.gnome-connections
    pkgs.virt-viewer
  ];
}
