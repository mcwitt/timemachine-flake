{
  description = "timemachine notebook environment";

  nixConfig = {
    extra-substituters = [ "https://timemachine.cachix.org" ];
    extra-trusted-public-keys = [ "timemachine.cachix.org-1:rum4By9jtYccZdzFjb16TzwENtjmdV4al9SeOmWpw4g=" ];
  };

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.timemachine-flake.url = "github:mcwitt/timemachine-flake";
  inputs.nixgl.url = "github:nix-community/nixGL";

  outputs = { self, flake-utils, timemachine-flake, nixgl }:
    flake-utils.lib.eachSystem
      (with flake-utils.lib.system; [
        x86_64-linux
        x86_64-darwin
      ])
      (system:
        let
          inherit (timemachine-flake.inputs) nixpkgs;

          pkgs = import timemachine-flake.inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              allowUnsupportedSystem = true; # needed for openmm on non-Linux
            };
            overlays = [
              nixgl.overlays.default
              timemachine-flake.overlays.default
            ];
          };

        in
        {
          packages = rec {
            default = python;

            python = pkgs.python3.withPackages (
              ps: with ps; [
                altair
                black
                ipywidgets
                isort
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

          devShells.default =
            let
              impure = builtins ? currentSystem;
              useNixgl = impure && pkgs.stdenv.isLinux;
            in
            pkgs.mkShell {
              packages = [
                self.packages.${system}.python
              ] ++ nixpkgs.lib.optional useNixgl pkgs.nixgl.auto.nixGLDefault;

              # prepend nixGL library paths in impure mode
              shellHook = nixpkgs.lib.optionalString useNixgl ''
                export LD_LIBRARY_PATH=$(${pkgs.nixgl.auto.nixGLDefault}/bin/nixGL printenv LD_LIBRARY_PATH):$LD_LIBRARY_PATH
              '';
            };
        });
}
