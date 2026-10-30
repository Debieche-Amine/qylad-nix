{pkgs, ...}: {
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    shellWrapperName = "y";

    extraPackages = with pkgs; [
      bat
      chafa
      ffmpegthumbnailer
      pkgs."poppler-utils"
      unar
      p7zip
      jq
      fd
      ripgrep
      zoxide
      fzf
      imagemagick
      file
    ];
  };
}
