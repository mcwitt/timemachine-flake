{ buildPythonPackage
, fetchPypi
, numpy
, pytest
}:

buildPythonPackage rec {
  pname = "hilbertcurve";
  version = "2.0.5";
  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-ancD2aLx/nSMhthpCL8YPn0Tm5c2ReSyUm4Qs051eW0=";
  };
  buildInputs = [ numpy ];
  checkInputs = [ pytest ];
}
