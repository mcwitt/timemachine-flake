{
  description = "timemachine python environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixgl.url = "github:nix-community/nixGL";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    { self
    , flake-utils
    , git-hooks
    , nixpkgs
    , nixgl
    } @ inputs: flake-utils.lib.eachSystem
      (with flake-utils.lib.system; [
        x86_64-linux
        x86_64-darwin
      ])
      (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowUnsupportedSystem = true; # needed for openmm on non-Linux
          };
          overlays = [
            nixgl.overlay
            (import ./overlay.nix { inherit inputs; })
          ];
        };

        python3 = pkgs.python311;

      in
      {
        packages = {

          default = self.packages.${system}.python;

          python = python3.withPackages (ps: [ ps.timemachine ]);

          inherit (python3.pkgs) mdtraj mols2grid nglview py3Dmol;

        } // nixpkgs.lib.optionalAttrs pkgs.stdenv.isLinux {

          dockerImage = nixpkgs.lib.makeOverridable pkgs.dockerTools.buildLayeredImage {
            name = "timemachine";
            contents = [
              self.packages.${system}.python

              # for debugging
              pkgs.bash
              pkgs.coreutils
              pkgs.findutils
              pkgs.glibc # required by nvidia-smi
            ];

            config.Env = [
              "LD_LIBRARY_PATH=/usr/lib64/" # nvidia-runtime mounts the host driver here
              "NVIDIA_DRIVER_CAPABILITIES=compute,utility" # selects which driver components to mount
              "NVIDIA_VISIBLE_DEVICES=all"
              "NVIDIA_REQUIRE_CUDA=cuda>=${nixpkgs.lib.versions.majorMinor pkgs.cudaPackages.cuda_cudart.version}"
            ];
          };
        };

        devShells = {

          default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            packages = self.checks.${system}.pre-commit-check.enabledPackages;
          };

          timemachine = nixpkgs.lib.makeOverridable pkgs.mkShell {

            inputsFrom = [ python3.pkgs.timemachine ];

            packages = (with python3.pkgs.timemachine.optional-dependencies; dev ++ test) ++ [
              pkgs.pyright
            ] ++ (with python3.pkgs; [
              notebook
              pytest-resource-usage
            ]) ++ nixpkgs.lib.optionals pkgs.stdenv.isLinux [
              pkgs.clang-tools
              pkgs.cudaPackages.cuda_gdb
              pkgs.cudaPackages.cuda_sanitizer_api
              pkgs.gdb
            ];

            shellHook = nixpkgs.lib.optionalString (pkgs.stdenv.isLinux && builtins ? currentSystem) ''
              export CUDAHOSTCXX=${pkgs.cudaPackages.cudatoolkit.cc}/bin/cc
              export LD_LIBRARY_PATH=$(${pkgs.nixgl.auto.nixGLDefault}/bin/nixGL printenv LD_LIBRARY_PATH):$LD_LIBRARY_PATH
            '';
          };
        };

        checks = {
          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks.nixpkgs-fmt.enable = true;
          };
        }
        // self.packages.${system} // self.devShells.${system}; # check that packages and devshells build
      }) // {
      overlays.default = import ./overlay.nix { inherit inputs; };

      templates = {
        notebook = {
          path = ./templates/notebook;
          description = "notebook environment with timemachine";
        };
        script = {
          path = ./templates/script;
          description = "python environment with timemachine";
        };
      };
    };
}
