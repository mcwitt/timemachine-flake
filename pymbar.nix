{ buildPythonPackage
, fetchFromGitHub
, jax
, jaxlib
, numexpr

, pytest
, pytest-cov
, pytest-runner
}:

buildPythonPackage rec {
  pname = "pymbar";
  version = "4.0.1";
  src = fetchFromGitHub {
    owner = "choderalab";
    repo = "pymbar";
    rev = version;
    sha256 = "sha256-62LzflqqSKfvH7QTmd7xN7685w0gGGYqsZc+9nkb8Jw=";
  };
  buildInputs = [ jaxlib ];
  propagatedBuildInputs = [ jax numexpr ];
  checkInputs = [ pytest pytest-cov pytest-runner ];
}
