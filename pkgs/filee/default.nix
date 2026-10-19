{
  lib,
  stdenv,
  fetchurl,
  buildFHSEnv,
  writeShellScript,
  makeDesktopItem,
}: let
  pname = "filee";
  version = "1.10.4";

  desktopItem = makeDesktopItem {
    name = "filee";
    desktopName = "Filee";
    exec = "Filee";
    icon = "filee";
    comment = "Offline file format converter";
    categories = ["Utility"];
  };

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
        dejavu_fonts
        noto-fonts
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
      if [ "$FILEE_BIN" = "filee-cli" ]; then
        exec "${unwrapped}/opt/filee/filee-cli" "$@"
      else
        exec "${unwrapped}/opt/filee/Filee" "$@"
      fi
    '';

    extraInstallCommands = ''
            mv $out/bin/filee $out/bin/.filee-fhs-wrapper

            cat << 'EOF' > $out/bin/Filee
      #!/bin/sh
      export FILEE_BIN=Filee
      exec "$(dirname "$0")/.filee-fhs-wrapper" "$@"
      EOF
            chmod +x $out/bin/Filee

            cat << 'EOF' > $out/bin/filee-cli
      #!/bin/sh
      export FILEE_BIN=filee-cli
      exec "$(dirname "$0")/.filee-fhs-wrapper" "$@"
      EOF
            chmod +x $out/bin/filee-cli

            ln -s $out/bin/filee-cli $out/bin/filee

      mkdir -p $out/share/applications $out/share/pixmaps
      cp ${unwrapped}/opt/filee/filee.png $out/share/pixmaps/filee.png
      cp -r ${desktopItem}/share/applications/* $out/share/applications/
    '';

    meta = with lib; {
      description = "Offline file format converter supporting 180+ formats";
      homepage = "https://github.com/KnifeLemon/Filee";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
    };
  }
