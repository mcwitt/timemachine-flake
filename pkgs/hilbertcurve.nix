{ buildPythonPackage, fetchPypi }:

buildPythonPackage rec {
  pname = "hilbertcurve";
  version = "1.0.5";
  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-rvwAhZyc3v7h5TtyLDOyCRr6GKYIp+7cfuKs2/Yv6zY=";
  };
}
