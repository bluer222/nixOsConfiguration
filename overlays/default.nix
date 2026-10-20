{ inputs, nixpkgs, ... }:

final: prev: {
  audacity = inputs.nixpkgs-audacity.legacyPackages.${prev.stdenv.hostPlatform.system}.audacity;

  t3code =
    let
      upstream = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system}.t3code;
    in
    upstream.override {
      t3code-unwrapped = upstream.unwrapped.overrideAttrs (oldAttrs: {
        # T3 Connect sign-in is hidden unless the JWT template is set at build time.
        env = (oldAttrs.env or { }) // {
          T3CODE_CLERK_JWT_TEMPLATE = "t3-relay";
        };
      });
    };

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
