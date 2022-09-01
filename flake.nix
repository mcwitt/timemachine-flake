{
  description = "timemachine python environment";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs;

    nixos-qchem.url = github:markuskowa/NixOS-QChem;

    timemachine-src = {
      url = github:proteneer/timemachine;
      flake = false;
    };
  };
  outputs =
    { self
    , nixpkgs
    , nixos-qchem
    , timemachine-src
    , ...
    }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      pythonOverrides =
        let
          cudaPackages = pkgs.cudaPackages_11_6;
        in
        final: prev: {
          jaxlib = prev.jaxlib.override { inherit cudaPackages; };

          hilbertcurve = final.callPackage ./hilbertcurve.nix { };

          openeye-toolkits = final.callPackage ./openeye-toolkits.nix { };

          openmm = final.callPackage "${nixos-qchem}/pkgs/apps/openmm" {
            inherit (cudaPackages) cudatoolkit;
            enableCuda = false;
          };

          py3Dmol = final.callPackage ./py3Dmol.nix { };

          pymbar = final.callPackage ./pymbar.nix { };

          timemachine = final.callPackage ./timemachine {
            inherit (cudaPackages) cudatoolkit;
            inherit timemachine-src;
          };

          # Optional

          mols2grid = final.callPackage ./mols2grid.nix { };
        };

      overridePython = python: python.override (old: {
        packageOverrides = pkgs.lib.composeExtensions (old.packageOverrides or (_: _: { })) pythonOverrides;
      });

      pythonEnv =
        let python3 = overridePython pkgs.python3;
        in python3.withPackages (ps: with ps; [
          jaxlib
          mols2grid
          py3Dmol
          timemachine
        ]);

    in
    {
      overlay = _: prev: { python3 = overridePython prev.python3; };

      packages.${system} = {
        default = self.packages.${system}.timemachine;
        timemachine = pythonEnv;
      };

      devShells.${system}.default = pythonEnv.env;
    };
}
