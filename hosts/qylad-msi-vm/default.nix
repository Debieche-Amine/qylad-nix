{
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    ../qylad-msi/system.nix
    ../qylad-msi/home-manager.nix
    inputs.home-manager.nixosModules.default
    inputs.stylix.nixosModules.stylix
  ];

  networking.hostName = lib.mkForce "qylad-msi-vm";

  # Graphics / OpenGL support for VM
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa.drivers
      virglrenderer
    ];
  };

  # VM resources & QEMU options
  virtualisation.memorySize = lib.mkDefault 4096;
  virtualisation.cores = lib.mkDefault 8;
  virtualisation.qemu.options = [
    "-device"
    "virtio-vga-gl"

    "-display"
    "default,gl=on"

    "-device"
    "virtio-tablet-pci"
  ];

  # SPICE guest agent for guest/host integration
  services.spice-vdagentd.enable = true;
}
