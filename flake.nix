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
    # Add nixpkgs-xr input
    nixpkgs-xr = {
      url = "github:nix-community/nixpkgs-xr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-howdy = {
      url = "github:fufexan/nixpkgs/howdy";
    };

        affinity-nix.url = "github:mrshmllow/affinity-nix";


   # kwin-effects-forceblur = {
   #   url = "github:taj-ny/kwin-effects-forceblur";
   #   inputs.nixpkgs.follows = "nixpkgs";
   # };
  };
  outputs = { self, nixpkgs, home-manager, nixpkgs-howdy, affinity-nix, nixpkgs-xr, devenv, ... }@inputs: {
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
         ({
          nixpkgs.overlays = [
            # Add nixpkgs-xr overlay
            nixpkgs-xr.overlays.default
            (final: prev: {
              howdy = nixpkgs-howdy.legacyPackages.${prev.system}.howdy;
                linux-enable-ir-emitter = nixpkgs-howdy.legacyPackages.${prev.system}.linux-enable-ir-emitter;
              })

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

        # Disable the default PAM module
        ({ disabledModules = [ "security/pam.nix" ]; })

            # Import the Howdy modules from nixpkgs-howdy
          "${nixpkgs-howdy}/nixos/modules/services/security/howdy"
          "${nixpkgs-howdy}/nixos/modules/services/misc/linux-enable-ir-emitter.nix"
    "${nixpkgs-howdy}/nixos/modules/security/pam.nix"
        ];
      };
    };
     # Add this if you want a devenv shell via `devenv shell`
    devShells = {
      x86_64-linux = {
        default = devenv.lib.mkShell {
          inherit inputs;
          # devenv.yaml is read automatically
        };
      };
    };
  };
}