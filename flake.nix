{
  description = "timemachine python environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    timemachine-src = {
      url = "github:proteneer/timemachine";
      flake = false;
    };
  };

  outputs = inputs @ { nixpkgs, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ (import ./overlay.nix { inherit inputs; }) ];
      };

    in
    {
      overlay = import ./overlay.nix { inherit inputs; };

      packages.${system} = rec {

        default = python;

        python = pkgs.python3.withPackages (ps: with ps; [ jaxlibWithoutCuda timemachine ]);

        inherit (pkgs.python3.pkgs) timemachine;

        docker = pkgs.dockerTools.buildLayeredImage {
          name = "timemachine";
          contents = [
            python

            # for debugging
            pkgs.bash
            pkgs.coreutils
            pkgs.findutils
            pkgs.glibc # required by nvidia-smi
          ];
        };

        config.Env = [
          "LD_LIBRARY_PATH=/usr/lib64/" # nvidia-runtime mounts the host driver here
          "NVIDIA_DRIVER_CAPABILITIES=compute,utility" # selects which driver components to mount
          "NVIDIA_VISIBLE_DEVICES=all"
          "NVIDIA_REQUIRE_CUDA=cuda>=${nixpkgs.lib.versions.majorMinor pkgs.cudaPackages.cuda_cudart.version}"
        ];
      };

      devShells.${system}.default = pkgs.mkShell {

        inputsFrom = [ pkgs.python3.pkgs.timemachine ];

        packages = pkgs.python3.pkgs.timemachine.optional-dependencies.dev ++ (with pkgs; [
          clang-tools
          cudaPackages.cuda_gdb
          cudaPackages.cuda_sanitizer_api
          gdb
          hadolint
          pyright
          python3Packages.jaxlibWithoutCuda
        ]);

        shellHook = ''
          # needed to find the NVIDIA driver at runtime on NixOS
          export LD_LIBRARY_PATH=${pkgs.linuxPackages.nvidia_x11}/lib
        '';
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
    };
}
