{
  description = "timemachine python environment";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs;

    eigen = {
      url = gitlab:libeigen/eigen/3.3.9;
      flake = false;
    };

    hilbertcurve-src = {
      url = github:galtay/hilbertcurve?ref=v1.0.5;
      flake = false;
    };

    nixos-qchem.url = github:markuskowa/NixOS-QChem;

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
    , eigen
    , hilbertcurve-src
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

          hilbertcurve = final.buildPythonPackage {
            name = "hilbertcurve";
            src = hilbertcurve-src;
            buildInputs = [ final.numpy ];
            checkInputs = [ final.pytest ];
          };

          openeye-toolkits =
            let
              version = "2020.2.0";
              mkUrl = pname: "https://pypi.anaconda.org/openeye/simple/${pname}/${version}/${pname}-${version}.tar.gz";

              subpackage =
                let pname = "OpenEye-toolkits-python3-linux-x64";
                in final.buildPythonPackage {
                  inherit pname version;
                  src = pkgs.fetchurl {
                    url = mkUrl pname;
                    sha256 = "sha256-bz+i2rX8g/QVPR30fK1m8KRb/iXz9etCKVD9DO3bVnM=";
                  };
                  doCheck = false;
                };

              pname = "OpenEye-toolkits";
            in
            final.buildPythonPackage {
              inherit pname version;
              propagatedBuildInputs = [ subpackage ];
              src = pkgs.fetchurl {
                url = mkUrl pname;
                sha256 = "sha256-c7boNOV4oeJwJmQgsSoCN/tsSUcIruj97FzsFS/PRb8=";
              };
            };

          openmm = final.callPackage "${nixos-qchem}/pkgs/apps/openmm" {
            inherit (cudaPackages) cudatoolkit;
            enableCuda = false;
          };

          pymbar = final.buildPythonPackage {
            name = "pymbar";
            src = pymbar-src;
            buildInputs = [ final.jaxlib ];
            propagatedBuildInputs = with final; [ jax numexpr ];
            doCheck = false;
          };

          timemachine = final.callPackage ./timemachine {
            inherit (cudaPackages) cudatoolkit;
            inherit eigen timemachine-src;
          };
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
