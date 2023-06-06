{ buildPythonPackage
, fetchFromGitHub
, numpy
, pytestCheckHook
, scipy
, six
}:

buildPythonPackage rec {
  pname = "pymbar";
  version = "3.1.0";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "choderalab";
    repo = "pymbar";
    rev = "refs/tags/${version}";
    sha256 = "sha256-lyUFPvhbVsqLIYRspYd+Mk40/1rCYP2W6ESY/7UDUT4=";
  };

  patches = [ ./0001-Remove-deprecated-int-alias.patch ];

  propagatedBuildInputs = [
    numpy
    scipy
    six
  ];

  nativeCheckInputs = [
    pytestCheckHook
  ];
}
