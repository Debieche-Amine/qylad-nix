{
  description = "qylad-nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:notashelf/nvf/v0.8";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nixpkgs-master,
    ...
  } @ inputs: let
    mkAgentVm = {
      username,
      workspaceSource,
      sshPort,
      agentArgs ? "",
      enableAgent ? true,
    }:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit inputs username workspaceSource sshPort agentArgs enableAgent;
        };

        modules = [
          ./hosts/agent-vm
          "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
        ];
      };
  in {
    overlays.default = final: _prev: {
      unstable = import nixpkgs-unstable {
        inherit (final) system;
        config.allowUnfree = true;
      };
      master = import nixpkgs-master {
        inherit (final) system;
        config.allowUnfree = true;
      };
    };

    nixosConfigurations = {
      qylad-msi = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit inputs;
          username = "qylad";
        };

        modules = [
          ./hosts/qylad-msi
        ];
      };

      vm-test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit inputs;
          username = "test";
        };

        modules = [
          ./hosts/vm-test
          "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
        ];
      };

      qylad-msi-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit inputs;
          username = "qylad";
        };

        modules = [
          ./hosts/qylad-msi-vm
          "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
        ];
      };

      just-a-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit inputs;
          username = "test";
        };

        modules = [
          ./hosts/just-a-vm
          "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
        ];
      };

      cli-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit inputs;
          username = "test";
        };

        modules = [
          ./hosts/cli-vm
          "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
        ];
      };

      hirara = mkAgentVm {
        username = "hirara";
        workspaceSource = "/home/qylad/project/hirara/hirara";
        sshPort = 2222;
        agentArgs = "600";
      };

      yss = mkAgentVm {
        username = "yss";
        workspaceSource = "/home/qylad/project/hirara/yss";
        sshPort = 2223;
        agentArgs = "--interval 30m";
        enableAgent = true;
      };

      baratis = mkAgentVm {
        username = "baratis";
        workspaceSource = "/home/qylad/project/hirara/baratis";
        sshPort = 2224;
        agentArgs = "--interval 90m";
        enableAgent = true;
      };
    };

    packages.x86_64-linux = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in {
      albion-online = pkgs.callPackage ./pkgs/albion-online {};
      albion-nix = self.packages.x86_64-linux.albion-online;
      vm-test = self.nixosConfigurations.vm-test.config.system.build.vm;
      just-a-vm = self.nixosConfigurations.just-a-vm.config.system.build.vm;
      qylad-msi-vm = self.nixosConfigurations.qylad-msi-vm.config.system.build.vm;
      cli-vm = self.nixosConfigurations.cli-vm.config.system.build.vm;
      hirara = self.nixosConfigurations.hirara.config.system.build.vm;
      yss = self.nixosConfigurations.yss.config.system.build.vm;
      baratis = self.nixosConfigurations.baratis.config.system.build.vm;
    };

    apps.x86_64-linux = {
      albion-online = {
        type = "app";
        program = "${self.packages.x86_64-linux.albion-online}/bin/albion-online";
      };
      albion-nix = self.apps.x86_64-linux.albion-online;
    };

    devShells =
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (system: let
        pkgs = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        esp32 = import ./shells/esp32.nix {inherit pkgs;};
        default = self.devShells.${system}.esp32;
      });

    templates = {
      esp32 = {
        path = ./templates/esp32;
        description = "ESP32 Rust minimal template";
      };
      default = self.templates.esp32;
    };
  };
}
