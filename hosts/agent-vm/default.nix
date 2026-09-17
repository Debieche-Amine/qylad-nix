{
  inputs,
  lib,
  ...
}: {
  imports = [
    ./system.nix
    ./home-manager.nix
    inputs.home-manager.nixosModules.default
  ];
}
