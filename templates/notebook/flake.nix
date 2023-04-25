{
  description = "timemachine notebook environment";

  nixConfig = {
    extra-substituters = [ "https://timemachine.cachix.org" ];
    extra-trusted-public-keys = [ "timemachine.cachix.org-1:rum4By9jtYccZdzFjb16TzwENtjmdV4al9SeOmWpw4g=" ];
  };

  inputs.timemachine-flake.url = "github:mcwitt/timemachine-flake";
  inputs.mdtraj.url = "github:mdtraj/mdtraj";

  outputs = { self, timemachine-flake, mdtraj }:
    let
      system = "x86_64-linux";

      pkgs = import timemachine-flake.inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          mdtraj.overlay
          timemachine-flake.overlays.default
        ];
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
            jupytext
            matplotlib
            ps.mdtraj
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
