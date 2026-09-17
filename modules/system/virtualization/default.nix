{
  pkgs,
  username,
  ...
}: {
  users.users.${username}.extraGroups = [
    "libvirtd"
    "docker"
  ];

  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    virtio-win
    win-spice
    adwaita-icon-theme
    quickemu
  ];

  virtualisation = {
    docker = {
      enable = true;
    };
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };
  services.spice-vdagentd.enable = true;

  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = pkgs.waydroid-nftables;
}
