{ buildPythonPackage
, cmake
, cython
, fetchFromGitHub
, ninja
, numpy
, pybind11
, pythonOlder
, scikit-build
, scikit-learn
, scipy
, setuptools
, threadpoolctl
, versioneer
}:

buildPythonPackage rec {
  pname = "deeptime";
  version = "0.4.4";
  format = "pyproject";

  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "deeptime-ml";
    repo = "deeptime";
    rev = "refs/tags/v${version}";
    sha256 = "sha256-oLBGyhRyIDFj6fK4OlTOfugPPnmv2yZ3M+BjccbuwDQ=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace 'scipy==1.9.3' 'scipy>=1.9.3' \
      --replace 'versioneer[toml]==0.28' 'versioneer[toml]>=0.28'
  '';

  nativeBuildInputs = [
    cmake
    cython
    ninja
    pybind11
    scikit-build
    setuptools
    versioneer
  ];

  dontUseCmakeConfigure = true;

  propagatedBuildInputs = [
    numpy
    scikit-learn
    scipy
    threadpoolctl
  ];

  doCheck = false; # TODO

  pythonImportsCheck = [ "deeptime" ];
}
