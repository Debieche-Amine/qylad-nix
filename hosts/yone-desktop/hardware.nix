# Hardware configuration for yone-desktop.
# On the target machine during a fresh installation, replace this with:
#   nixos-generate-config --show-hardware-config > hosts/yone-desktop/hardware.nix
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel" "kvm-amd"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = lib.mkDefault "/dev/disk/by-label/nixos";
    fsType = lib.mkDefault "ext4";
  };

  fileSystems."/boot" = {
    device = lib.mkDefault "/dev/disk/by-label/boot";
    fsType = lib.mkDefault "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = lib.mkDefault true;
}
