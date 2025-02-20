{ lib
, buildPythonPackage
, fetchFromGitHub
, cmake
, cython
, ninja
, numpy
, pybind11
, scikit-build
, scipy
, setuptools
, tomli
, versioneer
, wheel
, scikit-learn
, threadpoolctl
, torch
, matplotlib
, networkx
, tqdm
, coverage
, flaky
, pytest
, pytest-cov
, pytest-xdist
, pint
}:

buildPythonPackage rec {
  pname = "deeptime";
  version = "0.4.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "deeptime-ml";
    repo = "deeptime";
    rev = "v${version}";
    hash = "sha256-oLBGyhRyIDFj6fK4OlTOfugPPnmv2yZ3M+BjccbuwDQ=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'scipy==1.9.3' 'scipy>=1.9.3' \
      --replace-fail 'versioneer[toml]==0.28' 'versioneer[toml]>=0.28'
  '';

  nativeBuildInputs = [
    cmake
    cython
    ninja
    numpy
    pybind11
    scikit-build
    scipy
    setuptools
    tomli
    versioneer
    wheel
  ];

  dontUseCmakeConfigure = true;

  dependencies = [
    numpy
    scikit-learn
    scipy
    threadpoolctl
  ];

  passthru.optional-dependencies = {
    deep-learning = [
      torch
    ];
    plotting = [
      matplotlib
      networkx
    ];
    tests = [
      cmake
      coverage
      cython
      flaky
      matplotlib
      networkx
      ninja
      pybind11
      pytest
      pytest-cov
      pytest-xdist
      torch
      tqdm
    ];
    units = [
      pint
    ];
  };

  pythonImportsCheck = [ "deeptime" ];

  meta = with lib; {
    description = "Python library for analysis of time series data including dimensionality reduction, clustering, and Markov model estimation";
    homepage = "https://github.com/deeptime-ml/deeptime";
    license = licenses.lgpl3;
    maintainers = with maintainers; [ ];
  };
}
