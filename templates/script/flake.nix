{
  description = "timemachine python environment";

  inputs = {
    mdtraj.url = "github:mdtraj/mdtraj";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    timemachine-flake = {
      url = "github:mcwitt/timemachine-flake";
      inputs.timemachine-src.follows = "timemachine-src";
    };

    timemachine-src = {
      url = "github:proteneer/timemachine";
      # (optional) pin to a timemachine commit
      # url = "github:proteneer/timemachine/70aef22f702112c6bb87f4ca2c7da3fe460e2b3b";
      flake = false;
    };
  };
  outputs =
    { self
    , mdtraj
    , nixpkgs
    , timemachine-flake
    , timemachine-src
    , ...
    }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          mdtraj.overlay
          timemachine-flake.overlays.default
        ];
      };

      mkCommand = name: args: namedArgs:
        let
          attrsToArgs = nixpkgs.lib.mapAttrsToList (k: v: "--${k}=${toString v}");
          command = nixpkgs.lib.concatStringsSep " " (args ++ attrsToArgs namedArgs);
        in
        pkgs.writeShellScriptBin name command;

    in
    {
      devShells.${system}.default = self.packages.${system}.python.env;

      packages.${system} = rec {
        default = python;

        python = pkgs.python3.withPackages (ps: with ps; [
          black
          isort
          jaxlibWithoutCuda
          matplotlib
          mdtraj
          mols2grid
          rich
          timemachine
        ]);

        run-rbfe = mkCommand "run-rbfe" [ "${python}/bin/python" ./rbfe_edge_list.py ] {
          ligands = "${timemachine-src}/timemachine/datasets/fep_benchmark/hif2a/ligands.sdf";
          protein = "${timemachine-src}/timemachine/testsystems/data/hif2a_nowater_min.pdb";
          results_csv = "${timemachine-src}/timemachine/datasets/fep_benchmark/hif2a/results_edges_5ns.csv";
          forcefield = "smirnoff_1_1_0_ccc.py";
          n_frames = 1000;
          n_gpus = 2;
          seed = 123;
        };
      };
    };
}
