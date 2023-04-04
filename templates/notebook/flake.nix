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
        overlays = [ timemachine-flake.overlays.default ];
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
            jaxlib
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
