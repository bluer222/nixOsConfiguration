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

    hyprland = {
      url = "github:hyprwm/Hyprland/v0.54.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprspace = {
      url = "github:RomeoCavazza/Hyprspace";
      inputs.hyprland.follows = "hyprland";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-msi-ec = {
      url = "github:Svenum/nixpkgs/e1dca387c47d6bb82fd563ee1ba89bb1e438c8f3";
    };
  };
  outputs = { self, nixpkgs, home-manager, affinity-nix, nixpkgs-nvidia, comfyui-nix, nixpkgs-portmaster, hyprland, hyprspace, hyprland-plugins, nixpkgs-msi-ec, ... }@inputs: {
    nixosConfigurations = {
      samm-desktop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
         ({
          nixpkgs.overlays = [
            comfyui-nix.overlays.default
            inputs.hyprland.overlays.default
            (final: prev: {
              portmaster = nixpkgs-portmaster.legacyPackages.${prev.stdenv.hostPlatform.system}.portmaster;
              glaumar_repo = inputs.glaumar_repo.packages."${prev.stdenv.hostPlatform.system}";
              llama-cpp-cuda = prev.llama-cpp.override {
                cudaSupport = true;
                rocmSupport = false;
                metalSupport = false;
              };
              openldap = prev.openldap.overrideAttrs (oldAttrs: {
                doCheck = !prev.stdenv.hostPlatform.isi686;
              });
              mcontrolcenter = prev.mcontrolcenter.overrideAttrs (oldAttrs: {
                version = "unstable-2026-05-04";
                src = final.fetchFromGitHub {
                  owner = "dmitry-s93";
                  repo = "MControlCenter";
                  rev = "618c4ec1e6f114fb309f8b8529bdf937c69b0618";
                  hash = "sha256-XNsWbrryjKAqTPpcv9cLnUzWp8Wgq8c/5E73g4ipS1s=";
                };
              });
              linuxPackages_latest = prev.linuxPackages_latest.extend (lFinal: lPrev: {
                msi-ec = lPrev.msi-ec.overrideAttrs (oldAttrs: {
                  inherit (inputs.nixpkgs-msi-ec.legacyPackages.${prev.stdenv.hostPlatform.system}.linuxPackages_latest.msi-ec) version src patches;
                });
              });
            })
          ];
        })

        home-manager.nixosModules.home-manager

          {
            home-manager = {
              backupFileExtension = "hm-backup";
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; };
              users.samm = import ./home/home.nix;
            };
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
