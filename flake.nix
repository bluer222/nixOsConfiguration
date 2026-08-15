{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:epireyn/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    glaumar_repo = {
      url = "github:glaumar/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    affinity-nix.url = "github:mrshmllow/affinity-nix";
    comfyui-nix.url = "github:utensils/comfyui-nix";
    # Pin to cachix branch so binary cache hits; do not follow nixpkgs.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    nixpkgs-msi-ec.url = "github:Svenum/nixpkgs/3dec65fda85d03630173e5ab5f0eab6ae861c551";

    # Local secrets outside the flake tree (not git-filtered). Update with:
    #   nix flake update nixos-secrets
    nixos-secrets = {
      url = "path:/home/samm/.config/nixos-secrets";
      flake = false;
    };
  };


  outputs = { self, nixpkgs, home-manager, comfyui-nix, noctalia, niri, ... }@inputs: {
    nixosConfigurations = {
      samm-desktop = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ({
            nixpkgs.overlays = [
              comfyui-nix.overlays.default
              noctalia.overlays.default
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
              # Settings DSL only — do not import niri.homeModules.niri
              # (that one enables gnome-keyring / GNOME portals).
              sharedModules = [
                niri.homeModules.config
                noctalia.homeModules.default
              ];
              users.samm = import ./hosts/samm-desktop/home.nix;
            };
          }

          ./hosts/samm-desktop/default.nix
        ];
      };
    };
  };
}
