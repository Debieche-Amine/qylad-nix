{inputs, ...}: {
  imports = [
    ./hardware.nix
    ./system.nix
    ./home-manager.nix
    inputs.home-manager.nixosModules.default
    inputs.stylix.nixosModules.stylix
  ];
}
