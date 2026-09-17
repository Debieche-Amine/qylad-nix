{
  config,
  pkgs,
  username,
  ...
}: {
  environment.systemPackages = with pkgs; [
    android-tools
  ];

  users.users.${username}.extraGroups = [
    "adbusers"
  ];
}
