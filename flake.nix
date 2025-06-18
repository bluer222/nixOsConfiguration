{
  description = "Nixos config flake";

  inputs = {
      nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows =
        "nixpkgs"; # Use system packages list where available
    };
    glaumar_repo = {
    url = "github:glaumar/nur";
    inputs.nixpkgs.follows = "nixpkgs";


  };

    kwin-gestures = {
      url = "github:taj-ny/kwin-gestures";
      inputs.nixpkgs.follows = "nixpkgs";
    };

   # kwin-effects-forceblur = {
   #   url = "github:taj-ny/kwin-effects-forceblur";
   #   inputs.nixpkgs.follows = "nixpkgs";
   # };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
         ({
          nixpkgs.overlays = [
            (final: prev: {
              kwin-gestures = inputs.kwin-gestures.packages."${prev.system}";
              glaumar_repo = inputs.glaumar_repo.packages."${prev.system}";
              google-chrome = prev.google-chrome.overrideAttrs (old: {
        postInstall = ''
          wrapProgram $out/bin/google-chrome-stable \
            --add-flags "--enable-features=AcceleratedVideoDecodeLinuxZeroCopyGL,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder"
        '';
      });
            })
          ];
        })
        #nixpkgs-xr.nixosModules.nixpkgs-xr
          ./configuration.nix
        home-manager.nixosModules.home-manager

        ];
      };
    };
  };
}
