{
  description = "timemachine python environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixgl.url = "github:guibou/nixgl";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , nixgl
    , pre-commit-hooks
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

        python = pkgs.python310;

        getTimemachinePackage = ps:
          if pkgs.stdenv.isLinux
          then ps.timemachine
          else ps.timemachineWithoutCuda.override { jaxlib = ps.jaxlib-bin; };

      in
      {
        packages = {

          default = self.packages.${system}.python;

          python = python.withPackages (ps: [ (getTimemachinePackage ps) ]);

          inherit (python.pkgs) jupyter-black mdtraj mols2grid nglview py3Dmol;

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
          };

          timemachine = nixpkgs.lib.makeOverridable pkgs.mkShell {

            inputsFrom =
              let timemachine = getTimemachinePackage python.pkgs;
              in [ timemachine ];

            packages = (with python.pkgs.timemachine.optional-dependencies; dev ++ test) ++ [
              pkgs.pyright
              python.pkgs.pytest-resource-usage
            ] ++ nixpkgs.lib.optionals pkgs.stdenv.isLinux [
              pkgs.clang-tools
              pkgs.cudaPackages.cuda_gdb
              pkgs.cudaPackages.cuda_sanitizer_api
              pkgs.gdb
            ];

            shellHook = nixpkgs.lib.optionalString (pkgs.stdenv.isLinux && builtins ? currentSystem) ''
              export LD_LIBRARY_PATH=$(${pkgs.nixgl.auto.nixGLDefault}/bin/nixGL printenv LD_LIBRARY_PATH):$LD_LIBRARY_PATH
            '';
          };
        };

        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
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
