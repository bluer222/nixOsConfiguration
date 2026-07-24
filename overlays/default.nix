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
  # Python 3.14 removed type= from BooleanOptionalAction; upstream still passes type=bool.
  catppuccin-gtk = prev.catppuccin-gtk.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace sources/build/args.py \
        --replace-fail 'type=bool,' '# type=bool,  # removed for Python 3.14'
    '';
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
  hyprlandPlugins = prev.hyprlandPlugins // {
    hypr-darkwindow = prev.hyprlandPlugins.hypr-darkwindow.overrideAttrs (oldAttrs: {
      src = final.fetchFromGitHub {
        owner = "micha4w";
        repo = "Hypr-DarkWindow";
        tag = "v${oldAttrs.version}";
        hash = "sha256-91l5TD46OMfvmhd1WqWxm42cEnjR1yAj2Qk/73mr3ks=";
      };
    });
  };
}
