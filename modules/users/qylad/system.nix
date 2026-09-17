{
  pkgs,
  lib,
  username,
  ...
}: {
  home-manager.backupFileExtension = "backup";

  users.users.${username} = {
    isNormalUser = true;
    hashedPassword = "$y$j9T$lQO.ZhioA9oL6lXZbQ2VY1$mUxsvPPYd0lEeY3tMiHYneRlrgjAn2nq.AtU/nH7Vi3";
    shell = pkgs.fish;

    description = username;
    extraGroups = lib.mkAfter [
      "networkmanager"
      "wheel"
      "users"
    ];
    packages = with pkgs; [];
    linger = true;
  };
}
