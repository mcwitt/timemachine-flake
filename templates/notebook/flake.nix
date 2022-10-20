{
  description = "timemachine notebook environment";

  inputs = {
    mdtraj.url = "github:mdtraj/mdtraj";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    timemachine-flake.url = "github:mcwitt/timemachine-flake";
  };
  outputs =
    { mdtraj
    , nixpkgs
    , timemachine-flake
    , ...
    }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          mdtraj.overlay
          timemachine-flake.overlay
        ];
      };

      python3 = pkgs.python3.override (old: {
        packageOverrides = nixpkgs.lib.composeExtensions old.packageOverrides (final: _: {
          jupyter-black = final.buildPythonPackage rec {
            pname = "jupyter-black";
            version = "0.3.1";

            src = final.fetchPypi {
              inherit pname version;
              sha256 = "sha256-8LCmCo6oMCqNZZR6q2kSOK3bKAah1ljrWpgHj+tEgRw=";
            };

            format = "pyproject";

            nativeBuildInputs = [ final.pythonRelaxDepsHook ];

            propagatedBuildInputs = with python3.pkgs; [
              black
              python3.pkgs.ipython
              tokenize-rt
            ];

            pythonRelaxDeps = [ "ipython" ];
          };
        });
      });

      pythonEnv = python3.withPackages (
        ps: with ps; [
          black
          ipywidgets
          isort
          jaxlib
          jupyter-black
          matplotlib
          (ps.mdtraj.override { scikitlearn = ps.scikit-learn; })
          mols2grid
          notebook
          py3Dmol
          timemachine
          tqdm
        ]
      );

    in
    {
      devShells.${system}.default = pythonEnv.env;
    };
}
