{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  upstreamPackage = inputs.nix-openclaw.packages.${system}.openclaw;
  upstreamGateway = inputs.nix-openclaw.packages.${system}.openclaw-gateway;

  # OpenClaw 2026.7.1 does not classify declaratively loaded Nix-store
  # official plugins as trusted. Trust immutable Nix-store plugin roots only
  # while Nix mode is active, so packaged plugins receive their intended state
  # and command capabilities without a mutable npm install record.
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

  secretDir = "${config.secrets.dir}/openclaw";
  gatewayTokenFile = "${secretDir}/gateway-token";
  telegramTokenFile = "${secretDir}/telegram-bot-token";
  telegramOwnerIdFile = "${secretDir}/telegram-owner-id";
  astraRoot = "${config.home.homeDirectory}/Astra";
  astraJournalDir = "${astraRoot}/journal";
  astraMemoryDir = "${astraRoot}/memory";
in {
  programs.openclaw = {
    enable = true;
    # Keep the gateway package on nix-openclaw's isolated nixpkgs pin. The
    # module itself still integrates with this system's Home Manager release.
    package = patchedPackage;
    runtimePlugins = ["codex"];

    workspace.bootstrapFiles = {
      agents = ./openclaw/AGENTS.md;
      soul = ./openclaw/SOUL.md;
      identity = ./openclaw/IDENTITY.md;
      user = ./openclaw/USER.md;
      tools = ./openclaw/TOOLS.md;
      heartbeat = ./openclaw/HEARTBEAT.md;
    };

    # nix-openclaw reads these files only when the gateway starts. Their
    # contents are never copied into the Nix store or generated config.
    environment = {
      OPENCLAW_GATEWAY_TOKEN = gatewayTokenFile;
      ASTRA_TELEGRAM_OWNER_ID = telegramOwnerIdFile;
    };

    config = {
      gateway = {
        mode = "local";
        bind = "loopback";
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
          # Codex OAuth does not authorize the OpenAI embeddings API. Use the
          # builtin lexical index so Astra's local continuity stays reliable
          # without another credential or hosted billing dependency.
          provider = "none";
          fallback = "none";
          extraPaths = [
            astraJournalDir
            astraMemoryDir
          ];
        };
        heartbeat = {
          every = "6h";
          target = "telegram";
          to = "\${ASTRA_TELEGRAM_OWNER_ID}";
          directPolicy = "allow";
          isolatedSession = true;
          lightContext = false;
          skipWhenBusy = true;
          includeReasoning = false;
          timeoutSeconds = 600;
        };
      };
      plugins.entries.codex.config.appServer = {
        homeScope = "user";
        mode = "yolo";
      };
      channels.telegram = {
        enabled = true;
        tokenFile = telegramTokenFile;
        dmPolicy = "allowlist";
        allowFrom = ["\${ASTRA_TELEGRAM_OWNER_ID}"];
        groupPolicy = "disabled";
        heartbeat = {
          showOk = false;
          showAlerts = true;
          useIndicator = true;
        };
      };
      session.dmScope = "per-channel-peer";
      browser = {
        enabled = true;
        executablePath = "${pkgs.chromium}/bin/chromium";
        headless = false;
      };
      cron.enabled = true;

      # Astra runs directly as qylad with the complete OpenClaw tool surface.
      # Destructive-action confirmation is an operating-protocol rule rather
      # than a per-command execution gate.
      tools = {
        profile = "full";
        elevated = {
          enabled = true;
          allowFrom.telegram = ["\${ASTRA_TELEGRAM_OWNER_ID}"];
        };
        fs.workspaceOnly = false;
        exec = {
          host = "gateway";
          mode = "full";
          strictInlineEval = false;
          applyPatch.workspaceOnly = false;
        };
      };
      approvals = {
        exec.enabled = false;
        plugin.enabled = false;
      };

      commands = {
        bash = true;
        config = true;
        debug = true;
        mcp = true;
        plugins = true;
        restart = true;
        ownerAllowFrom = ["telegram:\${ASTRA_TELEGRAM_OWNER_ID}"];
      };
    };

    systemd.enable = true;
  };

  # Keep Astra's evolving state outside the Nix store while making its curated
  # memory visible through OpenClaw's canonical workspace paths.
  home.file.".openclaw/workspace/MEMORY.md".source =
    config.lib.file.mkOutOfStoreSymlink "${astraMemoryDir}/MEMORY.md";
  home.file.".openclaw/workspace/memory".source =
    config.lib.file.mkOutOfStoreSymlink astraMemoryDir;

  home.activation.astraStateDirectories = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -d -m 700 \
      ${astraRoot} ${astraJournalDir} ${astraMemoryDir}
    if [[ ! -e ${astraMemoryDir}/MEMORY.md ]]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 600 /dev/null \
        ${astraMemoryDir}/MEMORY.md
    fi
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod -R go-rwx ${astraRoot}
  '';

  home.activation.openclawStatePermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ -d ${config.home.homeDirectory}/.openclaw ]]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 700 ${config.home.homeDirectory}/.openclaw
    fi
  '';

  # The upstream Home Manager module defines the service; these additions make
  # it start with the user session and fail closed until required tokens exist.
  systemd.user.services.openclaw-gateway = {
    Unit.ConditionPathExists = [
      gatewayTokenFile
      telegramTokenFile
      telegramOwnerIdFile
    ];
    Service.UMask = "0077";
    Install.WantedBy = ["default.target"];
  };

  # Wayland screenshots use grim. ydotool supplies keyboard/pointer control
  # through the existing NixOS-managed uinput permissions and ydotool group.
  systemd.user.services.ydotool = {
    Unit.Description = "Virtual input daemon for Astra desktop control";
    Service = {
      ExecStart = "${pkgs.ydotool}/bin/ydotoold";
      Restart = "always";
      RestartSec = 1;
    };
    Install.WantedBy = ["default.target"];
  };
}
