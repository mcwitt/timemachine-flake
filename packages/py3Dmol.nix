{ buildPythonPackage, fetchPypi }:

buildPythonPackage rec {
  pname = "py3Dmol";
  version = "2.0.1.post1";
  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-rdcOz49keXCSXrjBBDxcE0OBP6SeYTt38GKOUixBSKw=";
  };
}
