{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  tomli,
  wheel,
  pytest,
}:

buildPythonPackage rec {
  pname = "mda-xdrlib";
  version = "0.2.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "MDAnalysis";
    repo = "mda-xdrlib";
    rev = "v${version}";
    hash = "sha256-FEgkW5dBFgQqlPk0Da8xnQP8A5KhvR5rSrJWFx11CPM=";
  };

  nativeBuildInputs = [
    setuptools
    tomli
    wheel
  ];

  passthru.optional-dependencies = {
    testing = [
      pytest
    ];
  };

  pythonImportsCheck = [ "mda_xdrlib" ];

  meta = with lib; {
    description = "Stand-alone XDRLIB module (from cpython 3.10.8";
    homepage = "https://github.com/MDAnalysis/mda-xdrlib";
    changelog = "https://github.com/MDAnalysis/mda-xdrlib/blob/${src.rev}/CHANGES";
    license = licenses.psfl;
    maintainers = with maintainers; [ ];
  };
}
