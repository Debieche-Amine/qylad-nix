{pkgs, ...}: {
  # Virtual filesystem daemon with MTP backend (used by Thunar & GTK apps)
  services.gvfs.enable = true;

  # Udev rules allowing non-root users to read/write MTP devices over USB
  services.udev.packages = [pkgs.libmtp];

  # System tools and KIO workers for Dolphin
  environment.systemPackages = with pkgs; [
    libmtp # Core MTP library & CLI tools (mtp-detect, etc.)
    jmtpfs # FUSE driver for mounting MTP
    kdePackages.kio-extras # Enables MTP (kio-mtp) in Dolphin
    kdePackages.kio-admin
  ];
}
