{inputs, ...}: {
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

      # Profile preferences (user.js)
      settings = {
        # General & Privacy hygiene
        "media.autoplay.default" = 5; # Block annoying video/audio autoplay by default
        "privacy.donottrackheader.enabled" = true;
        "privacy.globalprivacycontrol.enabled" = true;
        "zen.workspaces.continue-where-left-off" = true;

        # Language, Locale & Translation
        "intl.accept_languages" = "en-US, en, ar, fr"; # English first, Arabic second, French fallback
        "intl.locale.requested" = "en-US";
        "browser.translations.enable" = true;
        "browser.translations.automaticallyPopup" = true; # Prompt translation on foreign pages
        "layout.spellcheckDefault" = 2; # Multi-line and single-line spellcheck

        # -------------------------------------------------------------
        # Compact / Floating UI Mode (Uncomment below to try)
        # -------------------------------------------------------------
        # "zen.view.compact.hide-tabbar" = true;       # Auto-hide sidebar tabs
        # "zen.tabs.vertical.expand-on-hover" = true; # Expand sidebar when hovered
        # "zen.urlbar.behavior" = "float";            # Floating Spotlight-style Command Bar
        # "zen.widget.linux.transparency" = true;      # Linux transparency/blur support
      };

      # Declarative Containers for clean cookie/session isolation
      containersForce = true;
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

      # Declarative Workspaces (Spaces) linked to containers
      spaces = {
        Personal = {
          id = "f280bafe-7813-433e-8a1b-116ed23825e9";
          position = 1000;
          icon = "🏠";
          container = 1; # Link to Personal container
        };
        Work = {
          id = "a3d4f478-9d76-46d6-8084-a7fde481b495";
          position = 2000;
          icon = "💼";
          container = 2; # Link to Work container
        };
      };
    };
  };
}
