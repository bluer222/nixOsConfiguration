{ inputs, nixpkgs, ... }:

final: prev: {
  portmaster = inputs.nixpkgs-portmaster.legacyPackages.${prev.stdenv.hostPlatform.system}.portmaster;
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
}
