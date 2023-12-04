{ inputs }:
final:
prev:
let inherit (final) fetchFromGitHub;
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
      (pyFinal: pyPrev:
        let inherit (pyFinal) callPackage; in {

          deeptime = callPackage ./packages/deeptime.nix { };

          hilbertcurve = callPackage ./packages/hilbertcurve.nix { };

          jupyter-black = callPackage ./packages/jupyter-black.nix { };

          mdtraj = callPackage ./packages/mdtraj.nix { buildDocs = true; };

          mols2grid = callPackage ./packages/mols2grid.nix { };

          nglview = callPackage ./packages/nglview.nix { };

          openeye-toolkits = callPackage ./packages/openeye-toolkits.nix { };

          # Work around https://github.com/NixOS/nixpkgs/issues/224831
          openmm = pyPrev.openmm.override { inherit (final) stdenv gfortran; enableOpencl = false; };

          py3Dmol = callPackage ./packages/py3Dmol.nix { };

          pyemma = callPackage ./packages/pyemma.nix { };

          pymbar = callPackage ./packages/pymbar { };

          pytest-resource-usage = callPackage ./packages/pytest-resource-usage.nix { };

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
            callPackage "${nixpkgs}/pkgs/development/python-modules/rdkit" { };

          timemachine = callPackage ./packages/timemachine { };

          timemachineWithoutCuda = callPackage ./packages/timemachine { enableCuda = false; };
        });
  });
}
