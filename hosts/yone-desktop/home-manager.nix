{
  inputs,
  username,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs username;};
    backupFileExtension = "backup";

    users.${username} = {
      imports = [
        ../../modules/users/${username}
      ];
    };
  };
}
