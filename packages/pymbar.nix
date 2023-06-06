{ buildPythonPackage
, fetchFromGitHub
, jax
, jaxlib
, numexpr
, pytestCheckHook
, scipy
, six
}:

buildPythonPackage rec {
  pname = "pymbar";
  version = "4.0.1";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "choderalab";
    repo = "pymbar";
    rev = "refs/tags/${version}";
    sha256 = "sha256-lC596TCEScxVUBX/VmDE0QrcIbDMAb0FFQEp5R3b4is=";
  };

  propagatedBuildInputs = [
    jax
    jaxlib
    numexpr
  ];

  nativeCheckInputs = [
    pytestCheckHook
  ];
}
