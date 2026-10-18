{pkgs, ...}: {
  services.upower = {
    enable = true;
    percentageLow = 15;
    percentageCritical = 8;
    percentageAction = 5;
    criticalPowerAction = "Hibernate";
  };
}
