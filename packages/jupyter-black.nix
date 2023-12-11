{ buildPythonPackage
, fetchFromGitHub
, pythonRelaxDepsHook
, black
, ipython
, setuptools-scm
, tokenize-rt
}:

buildPythonPackage rec {
  pname = "jupyter-black";
  version = "0.3.4";

  src = fetchFromGitHub {
    inherit pname version;
    owner = "n8henrie";
    repo = "jupyter-black";
    rev = "refs/tags/v${version}";
    hash = "sha256-ySy2JGF0FBKIF31BGT5eWxRpOvlcfzZmtmr1/yIQWjk=";
  };

  format = "pyproject";

  nativeBuildInputs = [
    pythonRelaxDepsHook
    setuptools-scm
  ];

  propagatedBuildInputs = [
    black
    ipython
    tokenize-rt
  ];

  pythonRelaxDeps = [ "ipython" ];
}
