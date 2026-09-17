{
  config,
  pkgs,
  username,
  ...
}: {
  imports = [./default.nix];
  environment.systemPackages = with pkgs; [
    android-studio
  ];

  users.users.${username}.extraGroups = [
    "kvm"
  ];
}
