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

        # MetaMask Crypto Wallet
        "webextension@metamask.io" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ether-metamask/latest.xpi";
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

      # Pin extensions to the toolbar navigation bar for quick access
      extensionButtons = {
        "nav-bar" = [
          "webextension@metamask.io"
        ];
      };

      # Declarative Search Engines: Google default + quick keyword aliases
      search = {
        force = true;
        default = "Google";
        engines = {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["@np"];
          };
          "NixOS Options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["@no"];
          };
          "Home Manager Options" = {
            urls = [
              {
                template = "https://home-manager-options.extranix.com/";
                params = [
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["@hm"];
          };
          "GitHub" = {
            urls = [
              {
                template = "https://github.com/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["@gh"];
          };
          "YouTube" = {
            urls = [
              {
                template = "https://www.youtube.com/results";
                params = [
                  {
                    name = "search_query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["@yt"];
          };
          "DuckDuckGo" = {
            urls = [
              {
                template = "https://duckduckgo.com/";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            definedAliases = ["@ddg"];
          };
        };
      };

      # Declarative Containers for clean cookie/session isolation
      containersForce = true;
      containers = {
        Nexus = {
          id = 1;
          color = "purple";
          icon = "fingerprint";
        };
        Lab = {
          id = 2;
          color = "green";
          icon = "circle";
        };
      };

      # Route external links (clicked outside browser) into Nexus
      spaceRouting = {
        defaultExternalRoute = "f280bafe-7813-433e-8a1b-116ed23825e9";
      };

      # Declarative Workspaces (Spaces) linked to containers
      # (pinsForce is false by default, so extra pins added manually in Zen are preserved)
      spaces = {
        Nexus = {
          id = "f280bafe-7813-433e-8a1b-116ed23825e9";
          position = 1000;
          icon = "🪐";
          container = 1; # Link to Nexus container
          pins."Instagram" = {
            id = "733fa051-ef75-48ba-b583-6654905dffb7";
            url = "https://www.instagram.com";
            position = 100;
          };
          pins."Telegram" = {
            id = "d7fa769e-5cf6-40b1-a7c2-20c82bdbd1e5";
            url = "https://web.telegram.org";
            position = 200;
          };
        };
        Lab = {
          id = "a3d4f478-9d76-46d6-8084-a7fde481b495";
          position = 2000;
          icon = "🧪";
          container = 2; # Link to Lab container
          pins."GitHub" = {
            id = "65a535a6-4d7b-43d0-bf7d-4ba28cc066c7";
            url = "https://github.com";
            position = 100;
          };
        };
      };

      # Custom keyboard shortcuts: Alt+Z for Nexus (Space 1), Alt+E for Lab (Space 2)
      keyboardShortcuts = [
        {
          id = "zen-workspace-switch-1";
          key = "z";
          modifiers = {
            alt = true;
          };
        }
        {
          id = "zen-workspace-switch-2";
          key = "e";
          modifiers = {
            alt = true;
          };
        }
      ];
    };
  };
}
