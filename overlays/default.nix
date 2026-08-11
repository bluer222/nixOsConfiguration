{ inputs, nixpkgs, ... }:

final: prev: {
  glaumar_repo = inputs.glaumar_repo.packages."${prev.stdenv.hostPlatform.system}";

  llama-cpp-cuda = prev.llama-cpp.override {
    cudaSupport = true;
    rocmSupport = false;
    metalSupport = false;
  };
  openldap = prev.openldap.overrideAttrs (oldAttrs: {
    doCheck = !prev.stdenv.hostPlatform.isi686;
  });
  # gdal 3.13.1: one zarr sharding test fails on this toolchain; needed by howdy/opencv/vtk.
  # Overlay gdal itself so vtk's `gdal.override { useMinimalFeatures = true; }` also skips checks.
  gdal = prev.gdal.overrideAttrs (_: {
    doInstallCheck = false;
  });
  gdalMinimal = final.gdal.override { useMinimalFeatures = true; };
  # PDAL 2.9.3 fails to build against GDAL 3.13+ (GetMetadata returns CSLConstList).
  pdal = prev.pdal.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (final.fetchpatch {
        name = "pdal-gdal-3.13-cslconstlist.patch";
        url = "https://github.com/PDAL/PDAL/commit/eb7220a2447c5b3d208d7ef0a76c61a17a5b21da.patch";
        hash = "sha256-WJ7PeCkSl+S+qURa1X3Z6D6LiPpvIXWmEap4XcYq9bk=";
      })
    ];
  });
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pythonFinal: pythonPrev: {
      face-recognition = pythonPrev.face-recognition.overridePythonAttrs (oldAttrs: {
        doCheck = false;
      });
      # matplotlib 3.11 removed style.core; catppuccin 2.5.0 import fails when matplotlib is present.
      # catppuccin-gtk only needs the palette, so keep matplotlib out of the check env.
      catppuccin = pythonPrev.catppuccin.overridePythonAttrs (old: {
        doCheck = false;
        nativeCheckInputs = with pythonFinal; [ pytestCheckHook ]
          ++ (old.optional-dependencies.pygments or [ ])
          ++ (old.optional-dependencies.rich or [ ]);
      });
      # opencv4Full enables VTK, which fails to build against GDAL 3.13 (CSLConstList).
      # howdy / linux-enable-ir-emitter only need camera capture — plain opencv4 is enough.
      opencv4Full = pythonPrev.opencv4;
    })
  ];
  linuxPackages_latest = prev.linuxPackages_latest.extend (lFinal: lPrev: {
    msi-ec = lPrev.msi-ec.overrideAttrs (oldAttrs: {
      inherit (inputs.nixpkgs-msi-ec.legacyPackages.${prev.stdenv.hostPlatform.system}.linuxPackages_latest.msi-ec) version src patches;
    });
  });
  niri-helper = final.callPackage ../pkgs/niri-helper { };
}
