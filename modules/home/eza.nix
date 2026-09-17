{
  pkgs,
  config,
  ...
}: {
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    # enableBashIntegration = true;
    # enableNushellIntegration = true;
    # enableZshIntegration = true;
    git = true;
    icons = "auto";
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };
}
