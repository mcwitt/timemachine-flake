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
        inherit (nixpkgs) lib;
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnsupportedSystem = true; # needed for openmm on non-Linux
          config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
            "cuda_cccl"
            "cuda_cudart"
            "cuda_nvcc"
            "libcurand"
            "mda-xdrlib"
            "nvidia"
            "OpenEye-toolkits"
          ];
          overlays = [
            nixgl.overlay
            (import ./overlay.nix { inherit inputs; })
          ];
        };

        python3 = pkgs.python312;

      in
      {
        packages = {

          default = self.packages.${system}.python;

          python = python3.withPackages (ps: with ps; [
            deeptime
            mdanalysis
            mols2grid
            nglview
            py3Dmol
            pymbar
            timemachine
          ]);

        } // lib.optionalAttrs pkgs.stdenv.isLinux {

          dockerImage = lib.makeOverridable pkgs.dockerTools.buildLayeredImage {
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
              "NVIDIA_REQUIRE_CUDA=cuda>=${lib.versions.majorMinor pkgs.cudaPackages.cuda_cudart.version}"
            ];
          };
        };

        devShells = {

          default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            packages = self.checks.${system}.pre-commit-check.enabledPackages;
          };

          timemachine =
            let
              mkShell =
                { extraPackages ? [ ]
                , extraPythonPackages ? (_: [ ])
                , extraShellHook ? ""
                }: pkgs.mkShell {

                  inputsFrom = [ python3.pkgs.timemachine ];

                  packages =
                    let
                      python =
                        python3.withPackages
                          (ps:
                            (with ps.timemachine.optional-dependencies; dev ++ test)
                              ++ extraPythonPackages ps);
                    in
                    [
                      python
                    ]
                    ++ extraPackages;

                  shellHook = lib.optionalString (pkgs.stdenv.isLinux && builtins ? currentSystem) ''
                    export CUDAHOSTCXX=${pkgs.cudaPackages.cudatoolkit.cc}/bin/cc
                    export LD_LIBRARY_PATH=$(${pkgs.nixgl.auto.nixGLDefault}/bin/nixGL printenv LD_LIBRARY_PATH):$LD_LIBRARY_PATH
                    ${extraShellHook}
                  '';
                };
            in
            lib.makeOverridable mkShell { };
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
