{
  description = "timemachine notebook environment";

  inputs = {
    mdtraj.url = "github:mdtraj/mdtraj";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    timemachine-flake = {
      url = "github:mcwitt/timemachine-flake";
      # (optional) pin to a timemachine commit
      # inputs.timemachine-src.url = "github:proteneer/timemachine/70aef22f702112c6bb87f4ca2c7da3fe460e2b3b";
    };
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
        config.allowUnfree = true;
        overlays = [
          mdtraj.overlay
          timemachine-flake.overlay
        ];
      };

      python3 = pkgs.python3.override (old: {
        packageOverrides = nixpkgs.lib.composeExtensions old.packageOverrides (final: prev: {
          jupyter-black = final.callPackage ./nix/jupyter-black.nix { };
          timemachine = prev.timemachine.overrideAttrs (_: { dontUsePytestCheck = true; }); # tests are slow
        });
      });

      pythonEnv = python3.withPackages (
        ps: with ps; [
          black
          ipywidgets
          isort
          jaxlibWithoutCuda
          jupyter-black
          matplotlib
          ps.mdtraj
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
