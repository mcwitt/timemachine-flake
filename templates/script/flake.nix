{
  description = "timemachine python environment";

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

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          nixgl.overlays.default
          timemachine-flake.overlays.default
        ];
      };
    in
    {
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

      packages.${system} = rec {
        default = python;

        python = pkgs.python3.withPackages (ps: with ps; [
          black
          isort
          matplotlib
          mols2grid
          rich
          timemachine
          typer
        ]);

        run-rbfe =
          let
            inherit (timemachine-flake.inputs) timemachine-src;
            attrsToArgs = nixpkgs.lib.mapAttrsToList (k: v: "--${k}=${toString v}");
            args = attrsToArgs {
              ligands = "${timemachine-src}/timemachine/datasets/fep_benchmark/hif2a/ligands.sdf";
              protein = "${timemachine-src}/timemachine/testsystems/data/hif2a_nowater_min.pdb";
              results_csv = "${timemachine-src}/timemachine/datasets/fep_benchmark/hif2a/results_edges_5ns.csv";
              forcefield = "smirnoff_1_1_0_ccc.py";
              n_frames = 1000;
              n_gpus = 2;
              seed = 123;
            };
          in
          pkgs.writeShellScriptBin "run-rbfe" ''
            "${python}/bin/python" ${./rbfe_edge_list.py} ${nixpkgs.lib.concatStringsSep " " args}
          '';
      };
    };
}
