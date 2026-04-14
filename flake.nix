{
  description = "Nixos config flake";
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    glaumar_repo = {
      url = "github:glaumar/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-portmaster = {
      url = "github:WitteShadovv/nixpkgs/init-portmaster";
    };

    affinity-nix.url = "github:mrshmllow/affinity-nix";

    comfyui-nix.url = "github:utensils/comfyui-nix";

    nixpkgs-nvidia.url = "github:NixOS/nixpkgs/ab9ad415916a0fb89d1f539a9291d9737e95148e";
  };
  outputs = { self, nixpkgs, home-manager, affinity-nix, nixpkgs-nvidia, comfyui-nix, nixpkgs-portmaster, ... }@inputs: {
    nixosConfigurations = {
      samm-desktop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
         ({
          nixpkgs.overlays = [
            comfyui-nix.overlays.default
            (final: prev: {
              portmaster = nixpkgs-portmaster.legacyPackages.${prev.system}.portmaster;
              glaumar_repo = inputs.glaumar_repo.packages."${prev.system}";
              llama-cpp-cuda = prev.llama-cpp.override {
                cudaSupport = true;
                rocmSupport = false;
                metalSupport = false;
              };
            })
          ];
        })

        home-manager.nixosModules.home-manager

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.samm = import ./home/home.nix;
          }

          ./hardware-configuration.nix
          ./configuration.nix

          # Import Portmaster module
          "${nixpkgs-portmaster}/nixos/modules/services/networking/portmaster.nix"
        ];
      };
    };
  };
}