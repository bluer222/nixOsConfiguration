{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    glaumar_repo = {
      url = "github:glaumar/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-portmaster.url = "github:NixOS/nixpkgs/pull/442904/head";
    affinity-nix.url = "github:mrshmllow/affinity-nix";
    comfyui-nix.url = "github:utensils/comfyui-nix";
    nixpkgs-nvidia.url = "github:NixOS/nixpkgs/ab9ad415916a0fb89d1f539a9291d9737e95148e";
    nixpkgs-msi-ec.url = "github:Svenum/nixpkgs/e1dca387c47d6bb82fd563ee1ba89bb1e438c8f3";

    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = { self, nixpkgs, home-manager, comfyui-nix, nixpkgs-portmaster, ... }@inputs: {
    nixosConfigurations = {
      samm-desktop = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ({
            nixpkgs.overlays = [
              comfyui-nix.overlays.default
              (import ./overlays/default.nix { inherit inputs nixpkgs; })
            ];
          })

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              backupFileExtension = "hm-backup";
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; };
              users.samm = import ./hosts/samm-desktop/home.nix;
            };
          }

          ./hosts/samm-desktop/default.nix

          # Import Portmaster module from input
          "${nixpkgs-portmaster}/nixos/modules/services/networking/portmaster.nix"
        ];
      };
    };
  };
}
