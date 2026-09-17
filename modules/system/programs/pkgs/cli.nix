{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    iw
    ethtool
    traceroute
    dig
    lsof
    pciutils
    nethogs
    cacert
    sshfs
    tree
    wget
    git
    btop
    intel-gpu-tools
    zip
    unzip
    rar
  ];
}
