let
  mkFabrikContainer = {
    inputs,
    username ? "fabrik",
    secretsDir ? "/home/qylad/shadow/stable",
  }: {
    autoStart = true;

    bindMounts = {
      codex = {
        hostPath = "/home/qylad/.codex";
        mountPoint = "/home/${username}/.codex";
        isReadOnly = false;
      };
      shadow-fabrik = {
        hostPath = "${secretsDir}/fabrik";
        mountPoint = "/home/${username}/shadow/fabrik";
        isReadOnly = true;
      };
    };

    specialArgs = {
      containerUsername = username;
      inherit inputs;
    };

    config = {
      containerUsername,
      lib,
      pkgs,
      inputs,
      ...
    }: let
      system = pkgs.stdenv.hostPlatform.system;
      upstreamPackage = inputs.nix-openclaw.packages.${system}.openclaw;
      upstreamGateway = inputs.nix-openclaw.packages.${system}.openclaw-gateway;

      patchedGateway = upstreamGateway.overrideAttrs (old: {
        installPhase = ''
          ${old.installPhase}
          patched=0
          for registry in "$out"/lib/openclaw/dist/manifest-registry-*.js; do
            if grep -q 'function isTrustedOfficialPluginInstall(params) {' "$registry"; then
              sed -i '/function isTrustedOfficialPluginInstall(params) {/a\
          const nixPluginRoot = safeRealpathSync(params.candidate.rootDir) ?? path.resolve(params.candidate.rootDir);\
          if ((params.env ?? process.env).OPENCLAW_NIX_MODE === "1" && (nixPluginRoot === "/nix/store" || nixPluginRoot.startsWith("/nix/store/"))) return true;' "$registry"
              grep -q 'const nixPluginRoot = ' "$registry"
              patched=1
            fi
          done
          test "$patched" = 1

          patched_commands=0
          for registry in "$out"/lib/openclaw/dist/registry-*.js; do
            if grep -q 'return record.origin === "bundled" || isOfficialCodexPluginRecord(record);' "$registry"; then
              substituteInPlace "$registry" \
                --replace-fail \
                'return record.origin === "bundled" || isOfficialCodexPluginRecord(record);' \
                'return record.origin === "bundled" || record.trustedOfficialInstall === true || isOfficialCodexPluginRecord(record);'
              patched_commands=1
            fi
          done
          test "$patched_commands" = 1
        '';
      });

      patchedPackage = pkgs.runCommand "openclaw-nix-trusted-plugins-${upstreamPackage.version}" {} ''
        cp -a ${upstreamPackage}/. "$out"
        chmod u+w "$out/bin/openclaw"
        substituteInPlace "$out/bin/openclaw" \
          --replace-fail '${upstreamGateway}/bin/openclaw' '${patchedGateway}/bin/openclaw'
      '';

      secretDir = "/home/${containerUsername}/shadow/fabrik";
      gatewayPort = 18790;
      gatewayLauncher = pkgs.writeShellScript "fabrik-openclaw-gateway" ''
        export OPENCLAW_GATEWAY_TOKEN="$(<${secretDir}/gateway-token)"
        export FABRIK_TELEGRAM_OWNER_ID="$(<${secretDir}/telegram-owner-id)"
        exec ${patchedPackage}/bin/openclaw gateway --port ${toString gatewayPort}
      '';
    in {
      imports = [
        ../modules/core.nix
        ../../modules/system/locale.nix
        inputs.home-manager.nixosModules.home-manager
      ];

      nixpkgs.overlays = [inputs.nix-openclaw.overlays.default];
      nixpkgs.config.allowUnfree = true;

      programs.fish.enable = true;

      users.users.${containerUsername} = {
        isNormalUser = true;
        home = "/home/${containerUsername}";
        uid = 1000;
        shell = pkgs.fish;
        extraGroups = ["wheel"];
        # Keep the user manager—and therefore the gateway—running after
        # container boot without requiring an interactive login.
        linger = true;
      };

      environment.systemPackages = with pkgs; [
        git
        curl
        jq
        localtunnel
      ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {inherit inputs;};
        users.${containerUsername} = {
          imports = [
            inputs.nix-openclaw.homeManagerModules.openclaw
          ];

          home.stateVersion = "25.11";
          home.packages = with pkgs; [
            nodejs_22
            localtunnel
          ];

          programs.openclaw = {
            enable = true;
            package = patchedPackage;
            runtimePlugins = ["codex"];

            workspace.bootstrapFiles = {
              agents = ./openclaw/AGENTS.md;
              soul = ./openclaw/SOUL.md;
              identity = ./openclaw/IDENTITY.md;
              user = ./openclaw/USER.md;
              tools = ./openclaw/TOOLS.md;
            };

            environment = {
              OPENCLAW_GATEWAY_TOKEN = "${secretDir}/gateway-token";
              FABRIK_TELEGRAM_OWNER_ID = "${secretDir}/telegram-owner-id";
            };

            config = {
              gateway = {
                mode = "local";
                bind = "loopback";
                port = gatewayPort;
                auth = {
                  mode = "token";
                  token = {
                    source = "env";
                    provider = "default";
                    id = "OPENCLAW_GATEWAY_TOKEN";
                  };
                };
              };

              agents.defaults = {
                model.primary = "openai/gpt-5.6-luna";
                models."openai/gpt-5.6-luna".agentRuntime.id = "codex";
                embeddedAgent = {
                  executionContract = "strict-agentic";
                  projectSettingsPolicy = "trusted";
                };
                elevatedDefault = "full";
                sandbox.mode = "off";
                memorySearch = {
                  enabled = true;
                  provider = "none";
                  fallback = "none";
                };
              };

              plugins.entries.codex.config.appServer = {
                homeScope = "user";
                mode = "yolo";
              };

              channels.telegram = {
                enabled = true;
                tokenFile = "${secretDir}/telegram-bot-token";
                dmPolicy = "pairing";
                allowFrom = ["\${FABRIK_TELEGRAM_OWNER_ID}"];
                groupPolicy = "disabled";
              };

              browser = {
                enabled = false;
              };

              tools = {
                profile = "full";
                exec = {
                  host = "gateway";
                  mode = "full";
                };
              };
            };

            systemd.enable = true;
          };

          # Do not start the gateway with path strings substituted for absent
          # credentials. The OpenClaw wrapper reads these files at launch.
          systemd.user.services.openclaw-gateway = {
            Unit.ConditionPathExists = [
              "${secretDir}/gateway-token"
              "${secretDir}/telegram-bot-token"
              "${secretDir}/telegram-owner-id"
            ];
            Service.UMask = "0077";
            # NixOS containers share the host network namespace by default;
            # Astra already owns the standard OpenClaw port (18789).
            Service.ExecStart = lib.mkForce gatewayLauncher;
            Install.WantedBy = ["default.target"];
          };
        };
      };

      system.stateVersion = "25.11";
    };
  };
in {
  inherit mkFabrikContainer;
}
