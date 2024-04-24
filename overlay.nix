{ inputs }:
final:
prev:
let
  overridePython = python: python.override (old: {
    packageOverrides = final.lib.composeExtensions (old.packageOverrides or (_: _: { }))
      (pyFinal: pyPrev:
        let inherit (pyFinal) callPackage; in {

          hilbertcurve = callPackage ./packages/hilbertcurve.nix { };

          jupyter-black = callPackage ./packages/jupyter-black.nix { };

          mdtraj = callPackage ./packages/mdtraj.nix { buildDocs = true; };

          mols2grid = callPackage ./packages/mols2grid.nix { };

          nglview = callPackage ./packages/nglview.nix { };

          openeye-toolkits = callPackage ./packages/openeye-toolkits.nix { };

          py3Dmol = callPackage ./packages/py3Dmol.nix { };

          pymbar = callPackage ./packages/pymbar { };

          pytest-resource-usage = callPackage ./packages/pytest-resource-usage.nix { };

          timemachine =
            if final.stdenv.isLinux
            then pyFinal.timemachineWithCuda
            else pyFinal.timemachineWithoutCuda.override { jaxlib = final.jaxlib-bin; };

          timemachineWithCuda = callPackage ./packages/timemachine { };

          timemachineWithoutCuda = callPackage ./packages/timemachine { enableCuda = false; };
        });
  });
in
{
  cudaPackages = prev.cudaPackages_11_7.overrideScope (final: _: {
    # The following NVIDIA packages are included in cudatoolkit
    # but no redist packages are available:
    # https://developer.download.nvidia.com/compute/cuda/redist/
    # Fetching these from github lets us avoid depending on
    # cudatoolkit, which would add substantial size to the closure
    cub = final.callPackage ./packages/cub.nix { };
    thrust = final.callPackage ./packages/thrust.nix { };
  });

  python311 = overridePython prev.python311;
}
