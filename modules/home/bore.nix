{
  config,
  pkgs,
  ...
}: let
  secretFile = "${config.secrets.dir}/bore/secret";

  bore-wrapped = pkgs.writeShellScriptBin "bore" ''
    export BORE_SERVER="107.175.89.174"
    if [ -f "${secretFile}" ]; then
      export BORE_SECRET="$(cat "${secretFile}")"
    fi
    exec ${pkgs.bore-cli}/bin/bore "$@"
  '';
in {
  home.packages = [bore-wrapped];

  home.sessionVariables = {
    BORE_SERVER = "107.175.89.174";
  };
}
