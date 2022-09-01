{ buildPythonPackage
, fetchFromGitHub
, jax
, jaxlib
, numexpr
}:

buildPythonPackage rec {
  pname = "pymbar";
  version = "4.0.1";
  src = fetchFromGitHub {
    owner = "choderalab";
    repo = "pymbar";
    rev = "4.0.1";
    sha256 = "sha256-62LzflqqSKfvH7QTmd7xN7685w0gGGYqsZc+9nkb8Jw=";
  };
  buildInputs = [ jaxlib ];
  propagatedBuildInputs = [ jax numexpr ];
  doCheck = false;
}
