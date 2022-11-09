{
  description = "timemachine python environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    timemachine-src = {
      url = "github:proteneer/timemachine";
      flake = false;
    };
  };
  outputs =
    { nixpkgs
    , timemachine-src
    , ...
    }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays =
          let
            overlay = _: prev: {
              cudaPackages = prev.cudaPackages_11_7.overrideScope'
                (final: _: {
                  # The following NVIDIA packages are included in cudatoolkit
                  # but no redist packages are available:
                  # https://developer.download.nvidia.com/compute/cuda/redist/
                  # Fetching these from github lets us avoid depending on
                  # cudatoolkit, which would add substantial size to the closure
                  cub = final.callPackage ./cub.nix { };
                  thrust = final.callPackage ./thrust.nix { };
                });
            };
          in
          [ overlay ];
      };

      packageOverrides = final: prev: {
        black_21_12b0 = (prev.black.overrideAttrs (oldAttrs: rec {
          pname = "black";
          version = "21.12b0";
          src = final.fetchPypi {
            inherit pname version;
            hash = "sha256-d7gPaTpWni5SeVhFljTxjfmwuiYluk4MLV2lvkLm8rM=";
          };
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ final.pythonRelaxDepsHook ];
          pythonRelaxDeps = [ "tomli" ];
          doInstallCheck = false;
        })).override { click = final.click_8_0_4; };

        # can remove when upgrading black
        # https://github.com/psf/black/issues/2964
        click_8_0_4 = prev.click.overrideAttrs (_: rec {
          pname = "click";
          version = "8.0.4";
          src = final.fetchPypi {
            inherit pname version;
            hash = "sha256-hFjXsSh8X7EoyQ4jOBz5nc3nS+r2x/9jhM6E1v4JCts=";
          };
          doInstallCheck = false;
        });

        hilbertcurve = final.callPackage ./hilbertcurve.nix { };

        openeye-toolkits = final.callPackage ./openeye-toolkits.nix { };

        openmm = prev.openmm.override {
          inherit (pkgs.cudaPackages) cudatoolkit;
          enableCuda = false;
        };

        py3Dmol = final.callPackage ./py3Dmol.nix { };

        pymbar = final.callPackage ./pymbar.nix { };

        timemachine = final.callPackage ./timemachine {
          inherit (pkgs.cudaPackages) cub cuda_cudart cuda_nvcc libcurand thrust;
          src = timemachine-src;
        };

        # Optional

        mols2grid = final.callPackage ./mols2grid.nix { };
      };

      overridePython = python: python.override (old: {
        packageOverrides = nixpkgs.lib.composeExtensions (old.packageOverrides or (_: _: { })) packageOverrides;
      });

      python3 = overridePython pkgs.python3;

    in
    {
      overlay = _: prev: { python3 = overridePython prev.python3; };

      packages.${system} = rec {

        default = pythonEnv;

        pythonEnv = python3.withPackages (ps: with ps; [ jaxlibWithoutCuda timemachine ]);

        inherit (python3.pkgs) timemachine;

        docker = pkgs.dockerTools.buildImage {
          name = "timemachine";
          config.Cmd = "${pythonEnv}/bin/python";
        };
      };

      devShells.${system}.default = pkgs.mkShell {

        inputsFrom = [ python3.pkgs.timemachine ];

        packages = python3.pkgs.timemachine.optional-dependencies.dev ++ (with pkgs; [
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
