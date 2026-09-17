{
  inputs,
  username,
  pkgs,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs username;};
    backupCommand = "${pkgs.coreutils}/bin/rm -f";

    users.${username} = {
      home.stateVersion = "25.11";

      home.sessionVariables = {
        XDG_CACHE_HOME = "/tmp/cache";
      };

      home.packages = [
        pkgs.chromium
      ];

      programs.antigravity-cli = {
        enable = true;
        package = pkgs.unstable.antigravity-cli;

        permissions = {
          allow = ["*"];
          ask = [];
          deny = [];
        };

        settings = {
          toolPermission = "always-proceed";
        };

        mcpServers = {
          playwright = {
            command = "${inputs.mcp-servers-nix.packages.${pkgs.system}.playwright-mcp}/bin/playwright-mcp";
            args = [
              "--headless"
              "--browser"
              "chromium"
              "--executable-path"
              "${pkgs.chromium}/bin/chromium"
            ];
          };
        };
      };
    };
  };
}
