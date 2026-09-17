{pkgs, ...}: let
  cgroupScripts = pkgs.stdenv.mkDerivation {
    name = "hypr-cgroup-control-scripts";
    src = ./.;

    nativeBuildInputs = [pkgs.makeWrapper];

    installPhase = ''
      mkdir -p $out/bin/lib
      cp hypr-cgroup-ctl $out/bin/
      cp cgroup-writer.sh $out/bin/
      cp lib/cgroup-hypr-resolver.sh $out/bin/lib/

      chmod +x $out/bin/hypr-cgroup-ctl
      chmod +x $out/bin/cgroup-writer.sh
      chmod +x $out/bin/lib/cgroup-hypr-resolver.sh

      wrapProgram $out/bin/hypr-cgroup-ctl \
        --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.hyprland pkgs.jq pkgs.coreutils pkgs.gnugrep]}
    '';
  };
in {
  home.packages = [
    cgroupScripts
  ];
}
