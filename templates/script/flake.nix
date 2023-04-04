{
  description = "timemachine python environment";

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
      devShells.${system}.default = self.packages.${system}.python.env;

      packages.${system} = rec {
        default = python;

        python = pkgs.python3.withPackages (ps: with ps; [
          black
          isort
          jaxlib
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
