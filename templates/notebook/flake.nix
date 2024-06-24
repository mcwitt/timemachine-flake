{
  description = "timemachine notebook environment";

  nixConfig = {
    extra-substituters = [ "https://timemachine.cachix.org" ];
    extra-trusted-public-keys = [ "timemachine.cachix.org-1:rum4By9jtYccZdzFjb16TzwENtjmdV4al9SeOmWpw4g=" ];
  };

  inputs.timemachine-flake.url = "github:mcwitt/timemachine-flake";
  inputs.nixgl.url = "github:nix-community/nixGL";

  outputs = { self, timemachine-flake, nixgl }:
    let
      system = "x86_64-linux";

      inherit (timemachine-flake.inputs) nixpkgs;

      pkgs = import timemachine-flake.inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          nixgl.overlays.default
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
            jupyter-black
            jupytext
            matplotlib
            mdtraj
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

      devShells.${system}.default =
        let impure = builtins ? currentSystem;
        in
        pkgs.mkShell {
          packages = [
            self.packages.${system}.python
          ] ++ nixpkgs.lib.optional impure pkgs.nixgl.auto.nixGLDefault;

          # prepend nixGL library paths in impure mode
          shellHook = nixpkgs.lib.optionalString impure ''
            export LD_LIBRARY_PATH=$(${pkgs.nixgl.auto.nixGLDefault}/bin/nixGL printenv LD_LIBRARY_PATH):$LD_LIBRARY_PATH
          '';
        };
    };
}
