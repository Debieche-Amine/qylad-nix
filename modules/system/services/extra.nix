{...}: {
  services.logind.settings.Login = {
    IdleAction = "ignore";
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    LidSwitchIgnoreInhibited = "no";
    HandlePowerKey = "ignore";
  };

  services.vnstat.enable = true;
  services.udisks2 = {
    enable = true;
    settings = {
      "mount_options.conf" = {
        defaults = {
          ntfs_drivers = "ntfs,ntfs3";
        };
      };
    };
  };
  services.davfs2.enable = true;

  # Thermal management for Intel CPUs
  services.thermald.enable = true;

  # Periodic SSD TRIM to maintain NVMe write speeds and longevity
  services.fstrim.enable = true;

  # Kill rogue runaway processes before memory/swap exhaustion locks the system
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
  };

  # Zero-configuration local network discovery (.local hostnames)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
}
