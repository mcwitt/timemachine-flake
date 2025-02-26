{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  six,
  wheel,
  numexpr,
  numpy,
  scipy,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "pymbar";
  version = "3.1.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "choderalab";
    repo = "pymbar";
    rev = version;
    hash = "sha256-7HxXK3uykftdlUrEjkl68kKQcx2KRSwfE4by3irbHd4=";
  };

  patches = [ ./0001-Fix-numpy-deprecation.patch ];

  postPatch = ''
    substituteInPlace setup.py --replace-fail 'VERSION = "3.0.5"' 'VERSION = "${version}"'
  '';

  build-system = [
    setuptools
    six
    wheel
  ];

  dependencies = [
    numexpr
    numpy
    scipy
  ];

  nativeCheckInputs = [
    pytestCheckHook
  ];

  pythonImportsCheck = [
    "pymbar"
  ];

  meta = {
    description = "Python implementation of the multistate Bennett acceptance ratio (MBAR";
    homepage = "https://github.com/choderalab/pymbar/releases/tag/3.1.1";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
  };
}
