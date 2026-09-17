{
  lib,
  stdenv,
  fetchurl,
  p7zip,
  buildFHSEnv,
  makeDesktopItem,
  copyDesktopItems,
  writeShellScript,
  glibc,
  gcc,
  zlib,
  glib,
  expat,
  libGL,
  libGLU,
  libglvnd,
  vulkan-loader,
  libX11,
  libXau,
  libXdmcp,
  libxshmfence,
  libXcursor,
  libXrandr,
  libXinerama,
  libXi,
  libXext,
  libXrender,
  libXfixes,
  libXtst,
  libXdamage,
  libXcomposite,
  libXxf86vm,
  libxcb,
  libxcb-util,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  libxcb-wm,
  alsa-lib,
  libpulseaudio,
  openal,
  SDL2,
  openssl,
  krb5,
  curl,
  nss,
  nspr,
  libsecret,
  dbus,
  udev,
  gtk3,
  gdk-pixbuf,
  pango,
  cairo,
  atk,
  freetype,
  fontconfig,
  libxkbcommon,
  ...
}: let
  pname = "albion-online";
  version = "1.0.0";

  unwrapped = stdenv.mkDerivation {
    pname = "${pname}-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://live.albiononline.com/clients/albion-online-setup";
      sha256 = "16qa0ck2mycp9p8a8jf77hc8q6n4dhbv8bfldh1z38ai1533swna";
    };

    nativeBuildInputs = [p7zip copyDesktopItems];

    unpackPhase = ''
      runHook preUnpack
      7z x "$src" -oextracted
      cd extracted
      sourceRoot=.
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/albion-online
      cp -r data/* $out/share/albion-online/

      # Install desktop icons
      mkdir -p $out/share/pixmaps
      if [ -f data/AlbionOnline.xpm ]; then
        cp data/AlbionOnline.xpm $out/share/pixmaps/albion-online.xpm
      fi

      runHook postInstall
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "albion-online";
        exec = "albion-online";
        icon = "albion-online";
        comment = "Albion Online Launcher";
        desktopName = "Albion Online";
        genericName = "MMORPG";
        categories = ["Game"];
      })
    ];
  };

  # FHS Environment to resolve dynamic linking for launcher + downloaded game binaries & Unity engine
  fhs = buildFHSEnv {
    name = "albion-online-fhs";

    targetPkgs = pkgs: [
      # Core C / C++ runtime
      glibc
      gcc.cc.lib
      zlib
      glib
      expat

      # Graphics & OpenGL / Vulkan
      libGL
      libGLU
      libglvnd
      vulkan-loader
      libX11
      libXau
      libXdmcp
      libxshmfence
      libXcursor
      libXrandr
      libXinerama
      libXi
      libXext
      libXrender
      libXfixes
      libXtst
      libXdamage
      libXcomposite
      libXxf86vm
      libxcb
      libxcb-util
      libxcb-image
      libxcb-keysyms
      libxcb-render-util
      libxcb-wm

      # Audio
      alsa-lib
      libpulseaudio
      openal
      SDL2

      # Crypto, Auth & System
      openssl
      krb5
      curl
      nss
      nspr
      libsecret
      dbus
      udev

      # UI & Fonts
      gtk3
      gdk-pixbuf
      pango
      cairo
      atk
      freetype
      fontconfig
      libxkbcommon
    ];

    multiPkgs = pkgs: [
      udev
      alsa-lib
    ];

    runScript = writeShellScript "albion-online-wrapper" ''
      set -e

      DATA_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/albion-online"
      mkdir -p "$DATA_DIR"

      # Populate initial launcher files if missing
      if [ ! -d "$DATA_DIR/launcher" ] || [ ! -f "$DATA_DIR/launcher/Albion-Online" ]; then
        echo "Initializing Albion Online in $DATA_DIR..."
        cp -r --no-preserve=mode ${unwrapped}/share/albion-online/* "$DATA_DIR/"
      fi

      # Ensure writable and executable permissions for all copied files & binaries
      chmod -R u+rwX "$DATA_DIR"
      chmod -R +x "$DATA_DIR/launcher" 2>/dev/null || true
      [ -f "$DATA_DIR/Albion-Online" ] && chmod +x "$DATA_DIR/Albion-Online"

      cd "$DATA_DIR"

      export LD_LIBRARY_PATH="$DATA_DIR/launcher''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      export QT_QPA_PLATFORM_PLUGIN_PATH="$DATA_DIR/launcher/plugins/platforms"
      export QT_PLUGIN_PATH="$DATA_DIR/launcher/plugins"

      if [ -x "$DATA_DIR/launcher/Albion-Online" ]; then
        exec "$DATA_DIR/launcher/Albion-Online" "--no-sandbox" "$@"
      elif [ -x "$DATA_DIR/Albion-Online" ]; then
        exec "$DATA_DIR/Albion-Online" "$@"
      else
        echo "Error: Albion Online executable not found in $DATA_DIR"
        exit 1
      fi
    '';
  };
in
  stdenv.mkDerivation {
    inherit pname version;

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin $out/share

      cp -r ${unwrapped}/share/applications $out/share/ || true
      cp -r ${unwrapped}/share/pixmaps $out/share/ || true

      ln -s ${fhs}/bin/albion-online-fhs $out/bin/albion-online
    '';

    meta = with lib; {
      description = "A cross-platform sandbox MMORPG";
      homepage = "https://albiononline.com";
      license = licenses.unfree;
      platforms = ["x86_64-linux"];
    };
  }
