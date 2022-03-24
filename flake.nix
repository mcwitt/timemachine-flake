{
  description = "timemachine python environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    eigen = {
      url = "gitlab:libeigen/eigen/3.3.9";
      flake = false;
    };

    hilbertcurve-src = {
      url = "github:galtay/hilbertcurve";
      flake = false;
    };

    nixos-qchem.url = "github:markuskowa/NixOS-QChem";

    pymbar-src = {
      url = "github:choderalab/pymbar";
      flake = false;
    };

    timemachine-src = {
      url = "github:proteneer/timemachine";
      flake = false;
    };
  };
  outputs =
    { nixpkgs
    , eigen
    , hilbertcurve-src
    , nixos-qchem
    , pymbar-src
    , timemachine-src
    , ...
    }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [ nixos-qchem.overlay ];
      };

      cudatoolkit = pkgs.cudatoolkit_11_6;

      packageOverrides = final: prev: {
        inherit (pkgs.qchem.python3.pkgs) rdkit;

        hilbertcurve = prev.buildPythonPackage {
          name = "hilbertcurve";
          src = hilbertcurve-src;
          buildInputs = [ prev.numpy ];
          checkInputs = [ prev.pytest ];
        };

        openeye-toolkits =
          let
            version = "2020.2.0";
            mkUrl = pname: "https://pypi.anaconda.org/openeye/simple/${pname}/${version}/${pname}-${version}.tar.gz";
          in
          prev.buildPythonPackage rec {
            pname = "OpenEye-toolkits";
            inherit version;
            propagatedBuildInputs = let openeye-toolkits-python3-linux-x64 = prev.buildPythonPackage rec {
              pname = "OpenEye-toolkits-python3-linux-x64";
              inherit version;
              src = pkgs.fetchurl {
                url = mkUrl pname;
                sha256 = "sha256-bz+i2rX8g/QVPR30fK1m8KRb/iXz9etCKVD9DO3bVnM=";
              };
              doCheck = false;
            }; in [ openeye-toolkits-python3-linux-x64 ];
            src = pkgs.fetchurl {
              url = mkUrl pname;
              sha256 = "sha256-c7boNOV4oeJwJmQgsSoCN/tsSUcIruj97FzsFS/PRb8=";
            };
          };

        openmm = pkgs.qchem.python3.pkgs.openmm.override {
          inherit cudatoolkit;
          enableCuda = false;
        };

        pymbar = prev.buildPythonPackage {
          name = "pymbar";
          src = pymbar-src;
          buildInputs = with prev; [ numpy scipy six ];
          doCheck = false;
        };

        timemachine = prev.buildPythonPackage {
          name = "timemachine";
          src = timemachine-src;
          nativeBuildInputs = [ pkgs.cmake pkgs.xxd prev.pybind11 ];
          propagatedBuildInputs = [ cudatoolkit ] ++ (with final; [
            grpcio
            hilbertcurve
            importlib-resources
            jax
            jaxlib
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
            ./patches/CMakeLists.txt.patch
            ./patches/setup.py-remove-bootstrapped.patch
          ];
          preBuild = ''
            export CMAKE_ARGS=-DCUDA_ARCH=61
            export CMAKE_BUILD_PARALLEL_LEVEL=$(nproc)
          '';
          EIGEN_SRC_DIR = eigen;
          doCheck = false;
        };
      };

      python3 = pkgs.python3.override { inherit packageOverrides; };
    in
    {
      overlay = _: _: { inherit python3; };
    };
}
