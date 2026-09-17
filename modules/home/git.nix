{
  config,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;

    settings = {
      user.name = "Qylad";
      user.email = "qylad@porton.me";
      signing = {
        format = "ssh";
        key = "${config.home.homeDirectory}/.ssh/qyladx.pub";
        signByDefault = true;
      };

      color.ui = true;
      push.default = "simple";
      init.defaultBranch = "main";
    };
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "${config.home.homeDirectory}/.ssh/qyladx";
        identitiesOnly = true;
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = false;
      syntax-theme = "base16";
      plus-style = "syntax #1a3d24";
      minus-style = "syntax #421a1d";
      plus-emph-style = "syntax #2e6c3e";
      minus-emph-style = "syntax #6e272d";
    };
  };
}
