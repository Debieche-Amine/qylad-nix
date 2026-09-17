{inputs, ...}: {
  imports = [
    ./hardware.nix
    ./power.nix
    inputs.nixos-hardware.nixosModules.msi-prestige-15-a10sc

    ./system.nix

    ./home-manager.nix
    inputs.home-manager.nixosModules.default
    inputs.stylix.nixosModules.stylix
  ];
}
