{
  description = "timemachine python environment";

  nixConfig = {
    extra-substituters = [
      "https://ploop.cachix.org"
      "https://timemachine.cachix.org"
    ];
    extra-trusted-public-keys = [
      "timemachine.cachix.org-1:rum4By9jtYccZdzFjb16TzwENtjmdV4al9SeOmWpw4g="
      "ploop.cachix.org-1:i6+Fqarsbf5swqH09RXOEDvxy7Wm7vbiIXu4A9HCg1g="
    ];
  };

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    {
      self,
      flake-utils,
      git-hooks,
      nixpkgs,
    }@inputs:
    flake-utils.lib.eachSystem
      (with flake-utils.lib.system; [
        x86_64-linux
        x86_64-darwin
      ])
      (
        system:
        let
          inherit (nixpkgs) lib;
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnsupportedSystem = true; # needed for openmm on non-Linux
            config.allowUnfreePredicate =
              pkg:
              let
                name = lib.getName pkg;
              in
              lib.hasPrefix "cuda_" name
              || builtins.elem name [
                "cudnn"
                "libcublas"
                "libcufft"
                "libcurand"
                "libcusolver"
                "libcusparse"

                "libnvjitlink"
                "nvidia"

                "OpenEye-toolkits"
              ];
            overlays = [ (import ./overlay.nix) ];
          };

          python3 = pkgs.python312;

        in
        {
          packages =
            {
              default = self.packages.${system}.python;

              python = python3.withPackages (
                ps: with ps; [
                  deeptime
                  mdanalysis
                  mols2grid
                  nglview
                  py3Dmol
                  pymbar
                  timemachine
                ]
              );
            }
            // lib.optionalAttrs pkgs.stdenv.isLinux {

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

            timemachine = pkgs.mkShell.override { stdenv = pkgs.cudaPackages.backendStdenv; } {
              inputsFrom = [ python3.pkgs.timemachine ];
              packages = [ (python3.withPackages (ps: with ps.timemachine.optional-dependencies; dev ++ test)) ];
            };
          };

          checks = {
            pre-commit-check = git-hooks.lib.${system}.run {
              src = ./.;
              hooks.nixfmt-rfc-style.enable = true;
            };
          } // self.packages.${system} // self.devShells.${system}; # check that packages and devshells build
        }
      )
    // {
      overlays.default = import ./overlay.nix;

      templates = {
        notebook = {
          path = ./templates/notebook;
          description = "notebook environment with timemachine";
        };
      };
    };
}
