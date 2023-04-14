{
  description = "timemachine notebook environment";

  inputs.timemachine-flake.url = "github:mcwitt/timemachine-flake";

  outputs = { self, timemachine-flake }:
    let
      system = "x86_64-linux";

      pkgs = import timemachine-flake.inputs.nixpkgs {
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
            altair
            black
            ipywidgets
            isort
            jaxlib
            jupyter-black
            matplotlib
            mols2grid
            nglview
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
