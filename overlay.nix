{ inputs }:
final:
prev:
let inherit (final) fetchFromGitHub fetchurl stdenv;
in
{
  cudaPackages = prev.cudaPackages_11_7.overrideScope' (final: _: {
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

        deeptime = pyFinal.callPackage ./packages/deeptime.nix { };

        hilbertcurve = pyFinal.callPackage ./packages/hilbertcurve.nix { };

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

        mdtraj = pyFinal.callPackage ./packages/mdtraj.nix { buildDocs = true; };

        mols2grid = pyFinal.callPackage ./packages/mols2grid.nix { };

        nglview = pyFinal.callPackage ./packages/nglview.nix { };

        openeye-toolkits = pyFinal.callPackage ./packages/openeye-toolkits.nix { };

        # Work around https://github.com/NixOS/nixpkgs/issues/224831
        openmm = pyPrev.openmm.override { inherit (final) stdenv gfortran; enableOpencl = false; };

        py3Dmol = pyFinal.callPackage ./packages/py3Dmol.nix { };

        pyemma = pyFinal.callPackage ./packages/pyemma.nix { };

        pymbar = pyFinal.callPackage ./packages/pymbar { };

        pytest-resource-usage = pyFinal.callPackage ./packages/pytest-resource-usage.nix { };

        # Pin rdkit at 2022.03.5
        # 2023.03.1 segfaults in Chem.Draw.MolsToGridImage in some cases
        rdkit =
          let
            nixpkgs = fetchFromGitHub {
              owner = "nixos";
              repo = "nixpkgs";
              rev = "1f28f9f5d43baeb968edbae4a7f6502c9d333668";
              hash = "sha256-h87IUq5rhNJSQ98Q3k6EiVcO4CwYBakJYhMWN5C17tU=";
            };
          in
          pyFinal.callPackage "${nixpkgs}/pkgs/development/python-modules/rdkit" { };

        timemachine = pyFinal.callPackage ./packages/timemachine { };

        timemachineWithoutCuda = pyFinal.callPackage ./packages/timemachine { enableCuda = false; };
      });
  });
}
