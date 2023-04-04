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
        hilbertcurve = pyFinal.callPackage ./packages/hilbertcurve.nix { };

        jax = pyPrev.jax.overridePythonAttrs (old: rec {
          pname = "jax";
          version = "0.4.8";
          name = "${pname}-${version}";
          src = final.fetchFromGitHub {
            owner = "google";
            repo = pname;
            rev = "refs/tags/jax-v${version}";
            hash = "sha256-Z8JccGhvDUGh8qw7K5mscLvF7JDQQFsTXPypngQS0TM=";
          };
          propagatedBuildInputs = old.propagatedBuildInputs ++ [ pyFinal.ml-dtypes ];
        });

        jaxlib = (pyPrev.jaxlib.override { cudaSupport = false; }).overridePythonAttrs (old: rec {
          version = "0.4.7";
          name = "jaxlib-${version}";
          src = final.fetchurl {
            url = "https://storage.googleapis.com/jax-releases/nocuda/jaxlib-${version}-cp310-cp310-manylinux2014_x86_64.whl";
            hash = "sha256-2og4LmSHgFl0zqb6zGG6krWCinofLdgPdixIfYc6K0c=";
          };
          propagatedBuildInputs = old.propagatedBuildInputs ++ [ pyFinal.ml-dtypes ];
          nativeBuildInputs = old.nativeBuildInputs ++ [ final.autoPatchelfHook ];
        });

        jupyter-black = pyFinal.callPackage ./packages/jupyter-black.nix { };

        ml-dtypes = pyFinal.callPackage ./packages/ml-dtypes.nix { };

        nglview = pyFinal.callPackage ./packages/nglview.nix { };

        openeye-toolkits = pyFinal.callPackage ./packages/openeye-toolkits.nix { };

        py3Dmol = pyFinal.callPackage ./packages/py3Dmol.nix { };

        pymbar = pyFinal.callPackage ./packages/pymbar { };

        timemachine = pyFinal.callPackage ./packages/timemachine { };

        mols2grid = pyFinal.callPackage ./packages/mols2grid.nix { };
      });
  });
}
