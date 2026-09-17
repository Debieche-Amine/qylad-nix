{
  description = "ESP32 Rust Project";

  inputs = {
    qylad-nix.url = "github:Debieche-Amine/qylad-nix";
  };

  outputs = {qylad-nix, ...}: {
    devShells = qylad-nix.devShells;
  };
}
