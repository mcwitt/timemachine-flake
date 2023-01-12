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

  python3 = prev.python3.override (old: {
    packageOverrides = final.lib.composeExtensions (old.packageOverrides or (_: _: { }))
      (pyfinal: pyprev: {
        black_21_12b0 = (pyprev.black.overrideAttrs (oldAttrs: rec {
          pname = "black";
          version = "21.12b0";
          src = pyfinal.fetchPypi {
            inherit pname version;
            hash = "sha256-d7gPaTpWni5SeVhFljTxjfmwuiYluk4MLV2lvkLm8rM=";
          };
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pyfinal.pythonRelaxDepsHook ];
          pythonRelaxDeps = [ "tomli" ];
          doInstallCheck = false;
        })).override { click = pyfinal.click_8_0_4; };

        # can remove when upgrading black
        # https://github.com/psf/black/issues/2964
        click_8_0_4 = pyprev.click.overrideAttrs (_: rec {
          pname = "click";
          version = "8.0.4";
          src = pyfinal.fetchPypi {
            inherit pname version;
            hash = "sha256-hFjXsSh8X7EoyQ4jOBz5nc3nS+r2x/9jhM6E1v4JCts=";
          };
          doInstallCheck = false;
        });

        hilbertcurve = pyfinal.callPackage ./packages/hilbertcurve.nix { };

        openeye-toolkits = pyfinal.callPackage ./packages/openeye-toolkits.nix { };

        openmm = pyprev.openmm.override {
          inherit (final) cudaPackages;
          enableCuda = false;
        };

        py3Dmol = pyfinal.callPackage ./packages/py3Dmol.nix { };

        pymbar = pyfinal.callPackage ./packages/pymbar.nix { };

        timemachine = pyfinal.callPackage ./packages/timemachine {
          inherit (final.cudaPackages) cub cuda_cudart cuda_nvcc libcurand thrust;
        };

        mols2grid = pyfinal.callPackage ./packages/mols2grid.nix { };
      });
  });
}
