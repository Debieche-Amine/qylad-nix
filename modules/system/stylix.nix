{pkgs, ...}: let
  wallpaperRevision = "53e29b35fc242370e13f7dc1413ac8f5054e391e";
  wallpaperFile = "gruvbox/a_bicycle_leaning_against_a_wall.jpg";
  # Game-GTA.png
  # hamid: cabin-2.jpg
  # moh: Northern%20Lights2.jpg
  # wallpaper_1.jpg // the red simple one, works nicely
  # Northern%20Lights1.jpg // the green one, not bad, not perfect

  wallpaper = pkgs.fetchurl {
    # url = "https://raw.githubusercontent.com/harilvfs/wallpapers/${wallpaperRevision}/${wallpaperFile}";
    url = "https://raw.githubusercontent.com/vyrx-dev/Wallpapers/${wallpaperRevision}/${wallpaperFile}";
    hash = "sha256-k8gVQqo926dSSdTz+qoBaPctF4WaztSvTyhxT6KUM2I=";
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
