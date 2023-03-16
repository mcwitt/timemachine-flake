{ inputs }:
final:
prev:
{
  cudaPackages = prev.cudaPackages.overrideScope' (final: _: {
    # The following NVIDIA packages are included in cudatoolkit
    # but no redist packages are available:
    # https://developer.download.nvidia.com/compute/cuda/redist/
    # Fetching these from github lets us avoid depending on
    # cudatoolkit, which would add substantial size to the closure
    cub = final.callPackage ./packages/cub.nix { };
    thrust = final.callPackage ./packages/thrust.nix { };
  });

  python310 = prev.python310.override (old: {
    packageOverrides = final.lib.composeExtensions (old.packageOverrides or (_: _: { }))
      (pyFinal: pyPrev: {
        black_21_12b0 = (pyPrev.black.override {
          click = pyFinal.click_8_0_4;
        }).overridePythonAttrs (oldAttrs: rec {
          pname = "black";
          version = "21.12b0";
          src = pyFinal.fetchPypi {
            inherit pname version;
            hash = "sha256-d7gPaTpWni5SeVhFljTxjfmwuiYluk4MLV2lvkLm8rM=";
          };
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pyFinal.pythonRelaxDepsHook ];
          pythonRelaxDeps = [ "tomli" ];
          doCheck = false; # requires pytest 6.X
        });

        # can remove when upgrading black
        # https://github.com/psf/black/issues/2964
        click_8_0_4 = pyPrev.click.overridePythonAttrs (_: rec {
          pname = "click";
          version = "8.0.4";
          src = pyFinal.fetchPypi {
            inherit pname version;
            hash = "sha256-hFjXsSh8X7EoyQ4jOBz5nc3nS+r2x/9jhM6E1v4JCts=";
          };
        });

        hilbertcurve = pyFinal.callPackage ./packages/hilbertcurve.nix { };

        jupyter-black = pyFinal.callPackage ./packages/jupyter-black.nix { };

        openeye-toolkits = pyFinal.callPackage ./packages/openeye-toolkits.nix { };

        openmm = (pyPrev.openmm.override {
          inherit (final) cudaPackages;
          enableCuda = false;
        }).overrideAttrs (_: rec {
          pname = "openmm";
          version = "7.7.0";
          src = final.fetchFromGitHub {
            owner = "openmm";
            repo = pname;
            rev = "refs/tags/${version}";
            hash = "sha256-2PYUGTMVQ5qVDeeABrwR45U3JIgo2xMXKlD6da7y3Dw=";
          };
        });

        py3Dmol = pyFinal.callPackage ./packages/py3Dmol.nix { };

        pymbar = pyFinal.callPackage ./packages/pymbar.nix { };

        timemachine = pyFinal.callPackage ./packages/timemachine { };

        mols2grid = pyFinal.callPackage ./packages/mols2grid.nix { };
      });
  });
}
