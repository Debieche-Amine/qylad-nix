{
  config,
  lib,
  pkgs,
  inputs ? null,
  ...
}: {
  boot.supportedFilesystems = ["ntfs" "exfat"];

  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.systemd.network.wait-online.enable = false;

  # Enable GRUB
  boot.loader.grub = {
    enable = true;
    device = lib.mkDefault "nodev";
    efiSupport = true;
    useOSProber = true;
    timeoutStyle = "menu";
  };

  boot.tmp.useTmpfs = true;

  system.nixos.label = lib.maybeEnv "NIXOS_LABEL" (
    lib.concatStringsSep "-" (
      (lib.sort (x: y: x < y) config.system.nixos.tags)
      ++ [
        (
          if inputs ? self
          then "${config.system.nixos.release}-${builtins.substring 0 8 (inputs.self.lastModifiedDate or "00000000")}.${inputs.self.shortRev or inputs.self.dirtyShortRev or "dirty"}"
          else config.system.nixos.version
        )
      ]
    )
  );
}
