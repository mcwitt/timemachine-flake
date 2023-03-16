{ buildPythonPackage
, fetchFromGitHub
, pythonRelaxDepsHook
, black
, ipython
, tokenize-rt
, lib
}:

buildPythonPackage rec {
  pname = "jupyter-black";
  version = "0.3.3";

  src = fetchFromGitHub {
    inherit pname version;
    owner = "n8henrie";
    repo = "jupyter-black";
    rev = "refs/tags/v${version}";
    hash = "sha256-8q5GrhHrv/ZYNNqV0MeLyPPudsUNfxUDX991Qj4UrEU=";
  };

  format = "pyproject";

  nativeBuildInputs = [ pythonRelaxDepsHook ];

  propagatedBuildInputs = [
    black
    ipython
    tokenize-rt
  ];

  pythonRelaxDeps = [ "ipython" ];
}
