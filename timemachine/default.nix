{ lib
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

buildPythonPackage {
  name = "timemachine";
  src = timemachine-src;

  nativeBuildInputs = [ addOpenGLRunpath cmake mypy pybind11 ];

  buildInputs = [ jaxlib ];

  propagatedBuildInputs = [
    cudatoolkit
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
  ];

  checkInputs = [ pytest pytestCheckHook ];

  dontUseCmakeConfigure = true;

  patches = [
    ./patches/update-cmake-build.patch
    ./patches/fix-interpreter.patch
    ./patches/unpin-jax.patch
    (substituteAll {
      src = ./patches/hardcode-version.patch;
      version = timemachine-src.rev or "dirty";
    })
  ];

  CMAKE_ARGS = "-DCUDA_ARCH=61";
  EIGEN_SRC_DIR = eigen;

  postFixup = ''
    find $out -type f \( -name '*.so' -or -name '*.so.*' \) | while read lib; do
      echo "setting opengl runpath for $lib"
      addOpenGLRunpath "$lib"
    done
  '';

  pythonImportsCheck = [ "timemachine" ];

  doCheck = false; # many tests currently require OE license

  meta = with lib; {
    description = "A high-performance differentiable molecular dynamics, docking and optimization engine";
    homepage = "https://github.com/proteneer/timemachine";
    license = licenses.asl20;
    maintainers = with maintainers; [ mcwitt ];
  };
}
