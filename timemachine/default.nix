{ lib
, python
, buildPythonPackage
, addOpenGLRunpath
, pytestCheckHook
, substituteAll

, cmake
, cudatoolkit
, eigen

, grpcio
, hilbertcurve
, importlib-resources
, jax
, jaxlib
, matplotlib
, mypy
, networkx
, numpy
, openeye-toolkits
, openmm
, pybind11
, pymbar
, pyyaml
, rdkit
, scipy

, pytest

, timemachine-src
}:

let
  timemachine = buildPythonPackage rec {
    name = "timemachine";
    version = timemachine-src.rev or "dirty";
    src = timemachine-src;

    nativeBuildInputs = [ addOpenGLRunpath cmake mypy pybind11 ];
    buildInputs = [ eigen jaxlib ];

    propagatedBuildInputs = [
      cudatoolkit
      grpcio
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
    ];

    checkInputs = [ pytestCheckHook ] ++ timemachine.optional-dependencies.test;

    dontUseCmakeConfigure = true;

    patches = [
      ./patches/fix-interpreter.patch

      (substituteAll {
        src = ./patches/update-cmake-build.patch;
        pythonVersion = lib.versions.majorMinor python.version;
      })

      (substituteAll {
        src = ./patches/hardcode-version.patch;
        inherit version;
      })
    ];

    CMAKE_ARGS = "-DCUDA_ARCH=61";

    postFixup = ''
      find $out -type f \( -name '*.so' -or -name '*.so.*' \) | while read lib; do
        echo "setting opengl runpath for $lib"
        addOpenGLRunpath "$lib"
      done
    '';

    pythonImportsCheck = [ "timemachine" ];

    doCheck = false; # many tests currently require OE license

    passthru.optional-dependencies.test = [
      pytest
      hilbertcurve
    ];

    meta = with lib; {
      description = "A high-performance differentiable molecular dynamics, docking and optimization engine";
      homepage = "https://github.com/proteneer/timemachine";
      license = licenses.asl20;
      maintainers = with maintainers; [ mcwitt ];
    };
  };
in
timemachine
