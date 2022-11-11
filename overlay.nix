{ inputs }:
self:
super:
{
  cudaPackages = super.cudaPackages.overrideScope' (final: _: {
    # The following NVIDIA packages are included in cudatoolkit
    # but no redist packages are available:
    # https://developer.download.nvidia.com/compute/cuda/redist/
    # Fetching these from github lets us avoid depending on
    # cudatoolkit, which would add substantial size to the closure
    cub = final.callPackage ./pkgs/cub.nix { };
    thrust = final.callPackage ./pkgs/thrust.nix { };
  });

  python3 = super.python3.override (old: {
    packageOverrides = self.lib.composeExtensions (old.packageOverrides or (_: _: { }))
      (final: prev: {
        black_21_12b0 = (prev.black.overrideAttrs (oldAttrs: rec {
          pname = "black";
          version = "21.12b0";
          src = final.fetchPypi {
            inherit pname version;
            hash = "sha256-d7gPaTpWni5SeVhFljTxjfmwuiYluk4MLV2lvkLm8rM=";
          };
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ final.pythonRelaxDepsHook ];
          pythonRelaxDeps = [ "tomli" ];
          doInstallCheck = false;
        })).override { click = final.click_8_0_4; };

        # can remove when upgrading black
        # https://github.com/psf/black/issues/2964
        click_8_0_4 = prev.click.overrideAttrs (_: rec {
          pname = "click";
          version = "8.0.4";
          src = final.fetchPypi {
            inherit pname version;
            hash = "sha256-hFjXsSh8X7EoyQ4jOBz5nc3nS+r2x/9jhM6E1v4JCts=";
          };
          doInstallCheck = false;
        });

        hilbertcurve = final.callPackage ./pkgs/hilbertcurve.nix { };

        openeye-toolkits = final.callPackage ./pkgs/openeye-toolkits.nix { };

        openmm = prev.openmm.override {
          inherit (self.cudaPackages) cudatoolkit;
          enableCuda = false;
        };

        py3Dmol = final.callPackage ./pkgs/py3Dmol.nix { };

        pymbar = final.callPackage ./pkgs/pymbar.nix { };

        timemachine = final.callPackage ./pkgs/timemachine {
          inherit (self.cudaPackages) cub cuda_cudart cuda_nvcc libcurand thrust;
          src = inputs.timemachine-src;
        };

        mols2grid = final.callPackage ./pkgs/mols2grid.nix { };
      });
  });
}
