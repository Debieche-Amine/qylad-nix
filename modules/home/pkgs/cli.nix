{
  config,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;

  codex2 = pkgs.writeShellScriptBin "codex2" ''
    export CODEX_HOME=${homeDir}/tmp/codex-home-camellia
    mkdir -p "$CODEX_HOME"
    exec ${pkgs.unstable.codex}/bin/codex "$@"
  '';
  codex3 = pkgs.writeShellScriptBin "codex3" ''
    export HOME=${homeDir}/.homes/home3
    exec ${pkgs.unstable.codex}/bin/codex "$@"
  '';
  codex4 = pkgs.writeShellScriptBin "codex4" ''
    export HOME=${homeDir}/.homes/home4
    exec ${pkgs.unstable.codex}/bin/codex "$@"
  '';
  codex5 = pkgs.writeShellScriptBin "codex5" ''
    export HOME=${homeDir}/.homes/home5
    exec ${pkgs.unstable.codex}/bin/codex "$@"
  '';

  pi2 = pkgs.writeShellScriptBin "pi2" ''
    export HOME=${homeDir}/.homes/home2
    exec ${pkgs.unstable.pi-coding-agent}/bin/pi "$@"
  '';
  pi3 = pkgs.writeShellScriptBin "pi3" ''
    export HOME=${homeDir}/.homes/home3
    exec ${pkgs.unstable.pi-coding-agent}/bin/pi "$@"
  '';
in {
  home.file.".homes/home1/.keep".text = "";
  home.file.".homes/home2/.keep".text = "";
  home.file.".homes/home3/.keep".text = "";
  home.file.".homes/home4/.keep".text = "";
  home.file.".homes/home5/.keep".text = "";
  home.file.".homes/home6/.keep".text = "";
  home.file.".homes/home7/.keep".text = "";
  home.file.".homes/home8/.keep".text = "";
  home.file.".homes/home9/.keep".text = "";
  home.file.".homes/home10/.keep".text = "";

  home.packages = [
    pkgs.jq
    pkgs.dust
    pkgs.xclip
    pkgs.wl-clipboard
    pkgs.gemini-cli
    pkgs.ripgrep
    pkgs.fd
    pkgs.httpie
    pkgs.zellij
    pkgs.nmap
    pkgs.ncdu
    pkgs.age
    pkgs.localtunnel
    pkgs.comma
    pkgs.github-cli

    pkgs.unstable.codex
    codex2
    codex3
    codex4
    codex5
    pkgs.unstable.claude-code
    pkgs.unstable.opencode
    pkgs.unstable.pi-coding-agent
    pi2
    pi3
  ];
}
