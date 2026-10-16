{
  lib,
  stdenv,
  fetchurl,
  buildFHSEnv,
  writeShellScript,
  coreutils,
}: let
  pname = "filee";
  version = "1.10.4";

  unwrapped = stdenv.mkDerivation {
    pname = "${pname}-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://github.com/KnifeLemon/Filee/releases/download/v${version}/Filee-${version}-linux-x64.tar.gz";
      hash = "sha256-Y/4fn/SiHFcNeJvG2+aGrHtCEXQ09K1h8/c0dnl40Dw=";
    };

    sourceRoot = "Filee-${version}-linux-x64";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/opt/filee
      cp -r * $out/opt/filee/
      chmod +x $out/opt/filee/Filee $out/opt/filee/filee-cli
      runHook postInstall
    '';
  };
in
  buildFHSEnv {
    name = "filee";

    targetPkgs = pkgs:
      with pkgs; [
        glibc
        gcc.cc.lib
        zlib
        openssl
        icu
        krb5
        fontconfig
        freetype
        libxkbcommon
        libX11
        libXext
        libXcursor
        libXrandr
        libXi
        libXtst
        libICE
        libSM
        glib
        libGL
        ffmpeg
        ghostscript
      ];

    runScript = writeShellScript "filee-dispatcher" ''
      bin_name="$(${coreutils}/bin/basename "$0")"
      if [ "$bin_name" = "filee" ] || [ "$bin_name" = "filee-cli" ]; then
        exec "${unwrapped}/opt/filee/filee-cli" "$@"
      else
        exec "${unwrapped}/opt/filee/Filee" "$@"
      fi
    '';

    extraInstallCommands = ''
      mkdir -p $out/bin
      ln -s $out/bin/filee $out/bin/Filee
      ln -s $out/bin/filee $out/bin/filee-cli
    '';

    meta = with lib; {
      description = "Offline file format converter supporting 180+ formats";
      homepage = "https://github.com/KnifeLemon/Filee";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
    };
  }
