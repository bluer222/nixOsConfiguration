{ inputs, nixpkgs, ... }:

final: prev: {
  llama-cpp-cuda = prev.llama-cpp.override {
    cudaSupport = true;
    rocmSupport = false;
    metalSupport = false;
  };

  linuxPackages_latest = prev.linuxPackages_latest.extend (lFinal: lPrev: {
    msi-ec = lPrev.msi-ec.overrideAttrs (oldAttrs: {
      inherit (inputs.nixpkgs-msi-ec.legacyPackages.${prev.stdenv.hostPlatform.system}.linuxPackages_latest.msi-ec) version src patches;
    });
  });
  niri-helper = final.callPackage ../pkgs/niri-helper { };
}
