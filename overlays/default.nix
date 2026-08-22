{ inputs, nixpkgs, ... }:

final: prev: {
  # Backport nixpkgs#554373 (python3Packages.dlib after the 20.0.1 bump).
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pythonFinal: pythonPrev: {
      dlib = pythonPrev.dlib.overridePythonAttrs {
        patches = [ ./dlib-build-cores.patch ];
        format = null;
        pyproject = true;
        build-system = [
          pythonPrev.cmake
          pythonPrev.setuptools
        ];
        nativeCheckInputs = [ pythonPrev.pytestCheckHook ];
        postPatch = "";
      };
    })
  ];

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
