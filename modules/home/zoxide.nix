{
  pkgs,
  config,
  ...
}: {
  programs.zoxide = {
    enable = true;
    # enableBashIntegration = true;
    enableFishIntegration = true;
    # enableNushellIntegration = true;
    # enableZshIntegration = true;
  };
  home.sessionVariables = {
    _ZO_ECHO = "1";
    _ZO_RESOLVE_SYMLINKS = "1";
    _ZO_EXCLUDE_DIRS = "/tmp/*:${config.home.homeDirectory}/.cache/*:*/node_modules/*:*/.git/*";
    _ZO_FZF_OPTS = "--height 45% --layout=reverse --border=rounded --preview 'ls -C --color=always {2}'";
  };
}
