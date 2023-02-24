{
  description = "timemachine notebook environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    timemachine-flake.url = "github:mcwitt/timemachine-flake";
  };
  outputs = { self, nixpkgs, timemachine-flake }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays =
          let
            overlay = _: super: {
              python3 = super.python3.override (old: {
                packageOverrides = nixpkgs.lib.composeExtensions (old.packageOverrides or (_: _: { })) (final: _: {
                  jupyter-black = final.callPackage ./nix/jupyter-black.nix { };
                });
              });
            };
          in
          [
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
            mols2grid
            notebook
            pandas
            py3Dmol
            seaborn
            timemachine
            tqdm
          ]
        );
      };

      devShells.${system}.default = self.packages.${system}.python.env;
    };
}
