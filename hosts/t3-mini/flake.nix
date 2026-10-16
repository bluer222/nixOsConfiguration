{
  description = "Always-on T3 Code mini PC";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs = { self, nixpkgs, llm-agents, ... }:
    let
      system = "x86_64-linux";
      host = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit llm-agents; };
        modules = [ ./configuration.nix ];
      };
      image = import "${nixpkgs}/nixos/lib/make-disk-image.nix" {
        inherit (host) config pkgs;
        inherit (nixpkgs) lib;
        name = "t3-mini-image";
        baseName = "t3-mini";
        format = "raw";
        partitionTableType = "efi";
        bootSize = "512M";
        additionalSpace = "2G";
        memSize = 2048;
        copyChannel = false;
        contents = [ { source = self.outPath; target = "/etc/nixos"; mode = "u+w"; } ];
      };
    in {
      nixosConfigurations.t3-mini = host;
      packages.${system} = { inherit image; default = image; };
    };
}
