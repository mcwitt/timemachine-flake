{ buildPythonPackage, fetchPypi }:

buildPythonPackage rec {
  pname = "py3Dmol";
  version = "1.8.1";
  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-ELswIsXbPl5tZvUdfUEYr6+TlybWVfCHYXCd3wMssx0=";
  };
}
