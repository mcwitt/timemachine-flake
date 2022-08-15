{ buildPythonPackage
, astunparse
, cython
, mdtraj-src
, numpy
, pyparsing
, scipy
, zlib
}:

buildPythonPackage {
  name = "mdtraj";
  src = mdtraj-src;
  buildInputs = [ zlib cython ];
  propagatedBuildInputs = [ astunparse numpy pyparsing scipy ];
  doCheck = false;
}
