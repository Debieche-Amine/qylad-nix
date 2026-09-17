{pkgs}: let
  compatLibs = pkgs.runCommand "esp-compat-libs" {} ''
    mkdir -p $out/lib
    ln -s ${pkgs.libxml2.out}/lib/libxml2.so $out/lib/libxml2.so.2
  '';
in
  pkgs.mkShell {
    buildInputs = with pkgs; [
      espflash
      ldproxy
      espup
      rustup
      git
      # ESP-IDF prerequisites
      wget
      flex
      bison
      gperf
      python3
      python3Packages.pip
      python3Packages.virtualenv
      cmake
      ninja
      ccache
      libffi
      openssl
      dfu-util
      libusb1
      pkg-config
      llvmPackages.clang
      llvmPackages.libclang
      zlib
      libxml2
      ncurses
      stdenv.cc.cc.lib
    ];

    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath (with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      libxml2
      ncurses
    ])}:${compatLibs}/lib";

    shellHook = ''
      if [ -f "$HOME/export-esp.sh" ]; then
        source "$HOME/export-esp.sh"
      fi
      echo "ESP32 Rust development environment loaded."
    '';
  }
