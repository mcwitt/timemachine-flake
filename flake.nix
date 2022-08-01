{
  description = "timemachine python environment";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs?rev=5a0e0d73b944157328d54c4ded1cf2f0146a86a5; # last working jax

    eigen = {
      url = gitlab:libeigen/eigen/3.3.9;
      flake = false;
    };

    hilbertcurve-src = {
      url = github:galtay/hilbertcurve;
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

          timemachine = final.buildPythonPackage {
            name = "timemachine";
            src = timemachine-src;
            nativeBuildInputs = [ pkgs.cmake final.mypy final.pybind11 ];
            buildInputs = [ final.jaxlib ];
            propagatedBuildInputs = [ cudaPackages.cudatoolkit ] ++ (with final; [
              grpcio
              hilbertcurve
              importlib-resources
              jax
              matplotlib
              networkx
              numpy
              openeye-toolkits
              openmm
              pymbar
              pyyaml
              rdkit
              scipy
            ]);
            dontUseCmakeConfigure = true;
            patches = [
              ./patches/update-cmake-build.patch
              ./patches/fix-interpreter.patch
              ./patches/unpin-jax.patch
              (pkgs.substituteAll {
                src = ./patches/hardcode-version.patch;
                version = self.inputs.timemachine-src.rev or "dirty";
              })
            ];
            preBuild = ''
              export CMAKE_BUILD_PARALLEL_LEVEL=$(nproc)
            '';
            CMAKE_ARGS = "-DCUDA_ARCH=61";
            EIGEN_SRC_DIR = eigen;
            doCheck = false;
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
