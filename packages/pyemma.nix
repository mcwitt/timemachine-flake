{ buildPythonPackage
, cython
, decorator
, deeptime
, fetchFromGitHub
, h5py
, matplotlib
, mdtraj
, numpy
, pathos
, psutil
, pybind11
, pytestCheckHook
, pyyaml
, scipy
, setuptools
, tqdm
}:

buildPythonPackage rec {
  pname = "pyemma";
  version = "2.5.12";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "markovmodel";
    repo = "PyEMMA";
    rev = "refs/tags/v${version}";
    sha256 = "sha256-e0mBUTpsNIKgggl2wxUK9ldkUpvGDnWgAtFsFB7qdhA=";
  };

  nativeBuildInputs = [
    cython
    pybind11
    setuptools
  ];

  propagatedBuildInputs = [
    decorator
    deeptime
    h5py
    matplotlib
    mdtraj
    numpy
    pathos
    psutil
    pyyaml
    scipy
    tqdm
  ];

  nativeCheckInputs = [
    pytestCheckHook
  ];

  doCheck = false; # TODO

  pythonCheckImports = [ "pyemma" ];
}
