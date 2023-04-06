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
          name = "${pname}-${version}";
          src = pyFinal.fetchPypi {
            inherit pname version;
            hash = "sha256-hFjXsSh8X7EoyQ4jOBz5nc3nS+r2x/9jhM6E1v4JCts=";
          };
        });

        hilbertcurve = pyFinal.callPackage ./packages/hilbertcurve.nix { };

        jax = pyPrev.jax.overridePythonAttrs (old: rec {
          pname = "jax";
          version = "0.4.7";
          name = "${pname}-${version}";
          src = final.fetchFromGitHub {
            owner = "google";
            repo = pname;
            rev = "refs/tags/jax-v${version}";
            hash = "sha256-hjSa8DrQrvJcoITN18JJ7O833jHCTU1PFmw91+RiOwU=";
          };
          propagatedBuildInputs = old.propagatedBuildInputs ++ [ pyFinal.ml-dtypes ];
          doCheck = false;
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

        mols2grid = pyFinal.callPackage ./packages/mols2grid.nix { };

        mypy = pyPrev.mypy.overridePythonAttrs (old: rec {
          name = "${old.pname}-${version}";
          version = "1.1.1";
          src = final.fetchFromGitHub {
            owner = "python";
            repo = "mypy";
            rev = "refs/tags/v${version}";
            hash = "sha256-PKbqbGzCdeVGKu1uVhnx7+yl8M2a089qhxLctrV5Vu8=";
          };
          patches = [ ];
        });

        mypy-extensions = pyPrev.mypy-extensions.overridePythonAttrs (old: rec {
          name = "${old.pname}-${version}";
          version = "1.0.0";
          src = final.fetchFromGitHub {
            owner = "python";
            repo = "mypy_extensions";
            rev = "refs/tags/${version}";
            hash = "sha256-gOfHC6dUeBE7SsWItpUHHIxW3wzhPM5SuGW1U8P7DD0=";
          };
        });

        nglview = pyFinal.callPackage ./packages/nglview.nix { };

        openeye-toolkits = pyFinal.callPackage ./packages/openeye-toolkits.nix { };

        # Work around https://github.com/NixOS/nixpkgs/issues/224831
        openmm = pyPrev.openmm.override { inherit (final) stdenv gfortran; enableOpencl = false; };

        py3Dmol = pyFinal.callPackage ./packages/py3Dmol.nix { };

        pymbar = pyFinal.callPackage ./packages/pymbar { };

        timemachine = pyFinal.callPackage ./packages/timemachine { };
      });
  });
}
