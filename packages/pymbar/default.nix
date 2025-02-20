{ buildPythonPackage
, fetchFromGitHub
, numexpr
, numpy
, pytestCheckHook
, scipy
}:

buildPythonPackage rec {
  pname = "pymbar";
  version = "4.0.3";

  src = fetchFromGitHub {
    owner = "choderalab";
    repo = "pymbar";
    rev = "refs/tags/${version}";
    sha256 = "sha256-14LdXYwizVxEVWYpqil54kKXTjuXWuf3MNiKmixz4cs=";
  };

  dependencies = [
    numpy
    numexpr
    scipy
  ];

  nativeCheckInputs = [
    pytestCheckHook
  ];
}
