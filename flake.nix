{
  description = "timemachine python environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixgl.url = "github:guibou/nixgl";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = inputs @ { self, nixpkgs, nixgl, pre-commit-hooks, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          nixgl.overlay
          (import ./overlay.nix { inherit inputs; })
        ];
      };

    in
    {
      overlays.default = import ./overlay.nix { inherit inputs; };

      packages.${system} = rec {

        default = python;

        python = pkgs.python3.withPackages (ps: with ps; [ jaxlibWithoutCuda timemachine ]);

        inherit (pkgs.python3Packages) timemachine;

        dockerImage = nixpkgs.lib.makeOverridable pkgs.dockerTools.buildLayeredImage {
          name = "timemachine";
          contents = [
            python

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

      devShells.${system} = {

        default = pkgs.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
        };

        timemachine = nixpkgs.lib.makeOverridable pkgs.mkShell {

          inputsFrom = [ pkgs.python3Packages.timemachine ];

          packages = pkgs.python3Packages.timemachine.optional-dependencies.dev ++ (with pkgs; [
            clang-tools
            cudaPackages.cuda_gdb
            cudaPackages.cuda_sanitizer_api
            gdb
            pkgs.nixgl.auto.nixGLDefault
            pyright
            python3Packages.jaxlibWithoutCuda
          ]);

          shellHook = ''
            export LD_LIBRARY_PATH=$(nixGL printenv LD_LIBRARY_PATH):$LD_LIBRARY_PATH
          '';
        };
      };

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

      checks.${system}.pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks.nixpkgs-fmt.enable = true;
      };
    };
}
