{ buildPythonPackage
, fetchPypi
, astunparse
, cython
, numpy
, pyparsing
, scipy
, zlib
}:

buildPythonPackage rec{
  pname = "mdtraj";
  version = "1.9.7";
  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-ijMJ0u9t2xAj3PSDANXfmxkEabY/aa+dVUkLxHmdN1c=";
  };
  buildInputs = [ zlib cython ];
  propagatedBuildInputs = [ astunparse numpy pyparsing scipy ];
  doCheck = false;
  pythonImportsCheck = [ "mdtraj" ];
}
