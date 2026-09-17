{
  config,
  lib,
  pkgs,
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
}
