{ buildPythonPackage
, hilbertcurve-src
, numpy
, pytest
}:

buildPythonPackage {
  name = "hilbertcurve";
  src = hilbertcurve-src;
  buildInputs = [ numpy ];
  checkInputs = [ pytest ];
}
