{
  inputs,
  username,
  ...
}: {
  nixpkgs.overlays = [inputs.nix-openclaw.overlays.default];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs username;};
    backupFileExtension = "backup";

    users.${username} = {
      imports = [
        ../../modules/users/${username}
        inputs.nvf.homeManagerModules.default
        inputs.nix-openclaw.homeManagerModules.openclaw
      ];
    };
  };
}
