{
  config,
  pkgs,
  username,
  ...
}: {
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";

  imports = [
    ../../home/kitty.nix
    ../../home/fish.nix
    ../../home/git.nix
    ../../home/hyprland
    ../../home/xdg.nix
    ../../home/zen.nix
    ../../home/zoxide.nix
    ../../home/eza.nix
    ../../home/yazi.nix
    ../../home/direnv.nix
    ../../home/gnome-text-editor.nix
  ];

  home.packages = with pkgs; [
    # Core utilities
    jq
    dust
    glow
    ripgrep
    fd
    tree
    wl-clipboard
    unzip
    wget
    curl

    # Apps / GUI
    discord

    # Media / Viewers
    imv
    mpv
    zathura
  ];
}
