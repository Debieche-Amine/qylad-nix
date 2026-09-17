{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    # enableBashIntegration = true;
    # enableZshIntegration = true;
  };
}
