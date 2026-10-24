{
  inputs,
  ...
}: {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  # Stylix integration: automatically theme Zen using your system wallpaper palette
  stylix.targets.zen-browser.profileNames = ["default"];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;

    # Force native Wayland rendering on Hyprland/Wayland compositors
    env = {
      MOZ_ENABLE_WAYLAND = "1";
    };

    # System-level browser policies
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisablePocket = true;
      DisableFirefoxStudies = true;
      DontCheckDefaultBrowser = true;

      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };

      # Declaratively install essential extensions
      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
      };
    };

    profiles.default = {
      # Betterfox: performance, smooth scrolling, and de-bloat preset
      presets.betterfox.enable = true;

      # Arc-inspired & Linux-tailored settings
      settings = {
        # Arc-like navigation & UI
        "zen.view.compact.hide-tabbar" = true; # Auto-collapse vertical tabs to maximize screen space
        "zen.urlbar.behavior" = "float"; # Floating Spotlight/Raycast-style Command Bar
        "zen.widget.linux.transparency" = true; # Linux transparency/blur support
        "zen.workspaces.continue-where-left-off" = true;
        "zen.tabs.vertical.expand-on-hover" = true; # Expand sidebar smoothly when hovering

        # Media & Privacy Hygiene
        "media.autoplay.default" = 5; # Block annoying video/audio autoplay by default
        "privacy.donottrackheader.enabled" = true;
        "privacy.globalprivacycontrol.enabled" = true;
      };

      # Declarative Containers for clean cookie/session isolation
      containers = {
        Personal = {
          id = 1;
          color = "blue";
          icon = "fingerprint";
        };
        Work = {
          id = 2;
          color = "orange";
          icon = "briefcase";
        };
      };
    };
  };
}
