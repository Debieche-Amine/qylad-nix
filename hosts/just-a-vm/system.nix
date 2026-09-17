{
  pkgs,
  username,
  ...
}: {
  imports = [
    ../../modules/system/nix.nix
    ../../modules/system/locale.nix
    ../../modules/system/desktops/gnome.nix
  ];

  networking.hostName = "just-a-vm";

  # Graphics / OpenGL support for Wayland in QEMU VM
  hardware.graphics.enable = true;

  # VM resources & QEMU options
  virtualisation.memorySize = 4096;
  virtualisation.cores = 12;
  virtualisation.qemu.options = [
    "-device"
    "virtio-tablet-pci"
  ];

  # SPICE guest agent for guest/host integration (clipboard, resolution adjustment, etc.)
  services.spice-vdagentd.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    initialPassword = "test";
  };

  system.stateVersion = "25.11";
}
