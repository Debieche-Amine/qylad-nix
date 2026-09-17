{pkgs, ...}: {
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-volman # Volume manager for device management in sidebar
      thunar-archive-plugin
    ];
  };

  environment.systemPackages = with pkgs; [
    file-roller # Backend archive manager used by thunar-archive-plugin
    p7zip
    zip
    unzip
  ];

  # Thumbnail support for Thunar
  services.tumbler.enable = true;
}
