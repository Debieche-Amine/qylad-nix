{
  pkgs,
  lib,
  username ? "qylad",
  ...
}: {
  # Enable compressed in-memory swap with zstd and 100% RAM allocation
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    priority = 100;
  };

  # Kernel sysctl tuning for optimal ZRAM performance
  boot.kernel.sysctl = {
    # Prioritize compressed RAM swap over dropping filesystem caches
    "vm.swappiness" = 180;
    # Single page I/O since RAM has zero seek latency
    "vm.page-cluster" = 0;
    # Prevent unnecessary memory compaction spikes
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
  };

  fileSystems."/home/${username}/ram" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "size=50%"
      "mode=0700"
      "uid=1000"
      "gid=100"
    ];
  };
}
