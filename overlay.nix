{ inputs }:
final:
prev:
let inherit (final) fetchFromGitHub fetchurl lib stdenv;
in
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
          name = "${oldAttrs.pname}-${version}";
          version = "21.12b0";
          src = pyFinal.fetchPypi {
            inherit (oldAttrs) pname;
            inherit version;
            hash = "sha256-d7gPaTpWni5SeVhFljTxjfmwuiYluk4MLV2lvkLm8rM=";
          };
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pyFinal.pythonRelaxDepsHook ];
          pythonRelaxDeps = [ "tomli" ];
          doCheck = false; # requires pytest 6.X
        });

        # can remove when upgrading black
        # https://github.com/psf/black/issues/2964
        click_8_0_4 = pyPrev.click.overridePythonAttrs (oldAttrs: rec {
          name = "${oldAttrs.pname}-${version}";
          version = "8.0.4";
          src = pyFinal.fetchPypi {
            inherit (oldAttrs) pname;
            inherit version;
            hash = "sha256-hFjXsSh8X7EoyQ4jOBz5nc3nS+r2x/9jhM6E1v4JCts=";
          };
        });

        hilbertcurve = pyFinal.callPackage ./packages/hilbertcurve.nix { };

        jax = pyPrev.jax.overridePythonAttrs (oldAttrs: rec {
          name = "${oldAttrs.pname}-${version}";
          version = "0.4.7";
          src = fetchFromGitHub {
            owner = "google";
            repo = oldAttrs.pname;
            rev = "refs/tags/jax-v${version}";
            hash = "sha256-hjSa8DrQrvJcoITN18JJ7O833jHCTU1PFmw91+RiOwU=";
          };
          propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [ pyFinal.ml-dtypes ];
          doCheck = false;
        });

        jaxlib = (pyPrev.jaxlib.override { cudaSupport = false; }).overridePythonAttrs (oldAttrs: rec {
          name = "${oldAttrs.pname}-${version}";
          version = "0.4.7";
          src =
            let
              sources = {
                "x86_64-linux" = fetchurl {
                  url = "https://storage.googleapis.com/jax-releases/nocuda/jaxlib-${version}-cp310-cp310-manylinux2014_x86_64.whl";
                  hash = "sha256-2og4LmSHgFl0zqb6zGG6krWCinofLdgPdixIfYc6K0c=";
                };
                "x86_64-darwin" = fetchurl {
                  url = "https://storage.googleapis.com/jax-releases/mac/jaxlib-${version}-cp310-cp310-macosx_10_14_x86_64.whl";
                  hash = "sha256-Y8KJCXjoZGUW2z2KaAtD0r7YtjVDpwVWOR9YmiYb2F8=";
                };
              };
            in
            builtins.getAttr stdenv.system sources;

          propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [ pyFinal.ml-dtypes ];
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ final.lib.optionals stdenv.isLinux [ final.autoPatchelfHook ];
        });

        jupyter-black = pyFinal.callPackage ./packages/jupyter-black.nix { };

        # downgrade to work around
        # https://discourse.jupyter.org/t/jupyter-notebook-zmq-message-arrived-on-closed-channel-error/17869
        jupyter-client = pyPrev.jupyter-client.overridePythonAttrs (old: rec {
          version = "7.4.9";
          name = "${old.pname}-${version}";
          format = "pyproject";

          src = pyFinal.fetchPypi {
            inherit (old) pname;
            inherit version;
            hash = "sha256-Ur4o4EFx8HrtjyDhYWpaVSq5/unLvmwYlq4XDDiA05I=";
          };
        });

        ml-dtypes = pyFinal.callPackage ./packages/ml-dtypes.nix { };

        mols2grid = pyFinal.callPackage ./packages/mols2grid.nix { };

        mypy =
          let version = "1.1.1"; in
          if lib.versionAtLeast pyPrev.mypy.version version then lib.warn "Redundant overlay" pyPrev.mypy
          else
            pyPrev.mypy.overridePythonAttrs (oldAttrs: rec {
              name = "${oldAttrs.pname}-${version}";
              inherit version;
              src = fetchFromGitHub {
                owner = "python";
                repo = "mypy";
                rev = "refs/tags/v${version}";
                hash = "sha256-PKbqbGzCdeVGKu1uVhnx7+yl8M2a089qhxLctrV5Vu8=";
              };
              patches = [ ];
            });

        mypy-extensions =
          let version = "1.0.0"; in
          if lib.versionAtLeast pyPrev.mypy-extensions.version version then lib.warn "Redundant overlay" pyPrev.mypy
          else
            pyPrev.mypy-extensions.overridePythonAttrs (oldAttrs: rec {
              name = "${oldAttrs.pname}-${version}";
              inherit version;
              src = fetchFromGitHub {
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

        pymbar = pyFinal.callPackage ./packages/pymbar.nix { };

        pytest-resource-usage = pyFinal.callPackage ./packages/pytest-resource-usage.nix { };

        timemachine = pyFinal.callPackage ./packages/timemachine { };

        timemachineWithoutCuda = pyFinal.callPackage ./packages/timemachine { enableCuda = false; };
      });
  });
}
