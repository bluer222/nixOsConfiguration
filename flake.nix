{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    glaumar_repo = {
      url = "github:glaumar/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    affinity-nix.url = "github:mrshmllow/affinity-nix";
    comfyui-nix.url = "github:utensils/comfyui-nix";
    waybar = {
      url = "github:Alexays/Waybar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-nvidia.url = "github:NixOS/nixpkgs/ab9ad415916a0fb89d1f539a9291d9737e95148e";
    nixpkgs-msi-ec.url = "github:Svenum/nixpkgs/3dec65fda85d03630173e5ab5f0eab6ae861c551";

  };

  outputs = { self, nixpkgs, home-manager, comfyui-nix, waybar, niri, ... }@inputs: {
    nixosConfigurations = {
      samm-desktop = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ({
            nixpkgs.overlays = [
              comfyui-nix.overlays.default
              waybar.overlays.default
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
              sharedModules = [ niri.homeModules.config ];
              users.samm = import ./hosts/samm-desktop/home.nix;
            };
          }

          ./hosts/samm-desktop/default.nix
        ];
      };
    };
  };
}
