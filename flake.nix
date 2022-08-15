{
  description = "timemachine python environment";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs;

    hilbertcurve-src = {
      url = github:galtay/hilbertcurve?ref=v1.0.5;
      flake = false;
    };

    nixos-qchem.url = github:markuskowa/NixOS-QChem;

    mdtraj-src = {
      url = github:mdtraj/mdtraj;
      flake = false;
    };

    mols2grid-src = {
      url = github:cbouy/mols2grid;
      flake = false;
    };

    pymbar-src = {
      url = github:choderalab/pymbar;
      flake = false;
    };

    timemachine-src = {
      url = github:proteneer/timemachine;
      flake = false;
    };
  };
  outputs =
    { self
    , nixpkgs
    , hilbertcurve-src
    , mdtraj-src
    , mols2grid-src
    , nixos-qchem
    , pymbar-src
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

          hilbertcurve = final.callPackage ./hilbertcurve.nix { inherit hilbertcurve-src; };

          openeye-toolkits = final.callPackage ./openeye-toolkits.nix { };

          openmm = final.callPackage "${nixos-qchem}/pkgs/apps/openmm" {
            inherit (cudaPackages) cudatoolkit;
            enableCuda = false;
          };

          pymbar = final.callPackage ./pymbar.nix { inherit pymbar-src; };

          timemachine = final.callPackage ./timemachine {
            inherit (cudaPackages) cudatoolkit;
            inherit timemachine-src;
          };

          # Optional

          mdtraj = final.callPackage ./mdtraj.nix { inherit mdtraj-src; };

          mols2grid = final.callPackage ./mols2grid.nix { inherit mols2grid-src; };
        };

      overridePython = python: python.override (old: {
        packageOverrides = pkgs.lib.composeExtensions (old.packageOverrides or (_:_: { })) pythonOverrides;
      });

      pythonEnv =
        let python3 = overridePython pkgs.python3;
        in python3.withPackages (ps: with ps; [ jaxlib timemachine ]);

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
