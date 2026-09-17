{pkgs, ...}: let
  wallpaperRevision = "02076c7346120871ce4631d203802e6d4dc90ad9";
  wallpaperFile = "wallpaper_1.jpg";
  # Game-GTA.png
  # hamid: cabin-2.jpg
  # moh: Northern%20Lights2.jpg
  # wallpaper_1.jpg // the red simple one, works nicely
  # Northern%20Lights1.jpg // the green one, not bad, not perfect

  wallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/harilvfs/wallpapers/${wallpaperRevision}/${wallpaperFile}";
    hash = "sha256-erVfSu/0bzaAoyzbZmhFjN/SmjuBsAU8VnT2icFQRW8=";
  };
in {
  stylix = {
    enable = true;

    image = wallpaper;
    polarity = "dark";
    opacity = {
      terminal = 0.9;
      applications = 0.8;
      popups = 0.8;
    };

    # Targets config
    targets = {
      grub = {
        enable = true;
        useWallpaper = true;
      };
    };

    fonts = {
      monospace = {
        package = pkgs.maple-mono.NF;
        name = "Maple Mono NF";
      };
      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };
      serif = {
        package = pkgs.amiri;
        name = "Amiri";
      };
      sizes.terminal = 16;
    };
  };

  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
          };
        };
      }
    ];
  };
}
