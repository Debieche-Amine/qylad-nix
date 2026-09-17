{pkgs, ...}: {
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    maple-mono.NF
    noto-fonts
    amiri
  ];

  fonts.fontconfig.defaultFonts = {
    monospace = ["Maple Mono NF" "Noto Sans Arabic" "Amiri"];
    sansSerif = ["Maple Mono NF" "Noto Sans Arabic UI" "Noto Sans Arabic"];
    serif = ["Maple Mono NF" "Amiri" "Noto Naskh Arabic"];
  };
}
