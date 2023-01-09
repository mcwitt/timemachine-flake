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
    { self
    , mdtraj
    , nixpkgs
    , timemachine-flake
    , ...
    }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays =
          let
            overlay = _: super: {
              python3 = super.python3.override (old: {
                packageOverrides = nixpkgs.lib.composeExtensions old.packageOverrides (final: _: {
                  jupyter-black = final.callPackage ./nix/jupyter-black.nix { };
                });
              });
            };
          in
          [
            mdtraj.overlay
            timemachine-flake.overlays.default
            overlay
          ];
      };

    in
    {
      packages.${system} = rec {
        default = python;

        python = pkgs.python3.withPackages (
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
      };

      devShells.${system}.default = self.packages.${system}.python.env;
    };
}
