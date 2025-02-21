{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  wheel,
  numpy,
  pytest,
  sphinx,
  sphinx-autodoc-typehints,
  sphinx-rtd-theme,
}:

buildPythonPackage rec {
  pname = "hilbertcurve";
  version = "1.0.5";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-rvwAhZyc3v7h5TtyLDOyCRr6GKYIp+7cfuKs2/Yv6zY=";
  };

  build-system = [
    setuptools
    wheel
  ];

  dependencies = [
    numpy
  ];

  passthru.optional-dependencies = {
    dev = [
      pytest
      sphinx
      sphinx-autodoc-typehints
      sphinx-rtd-theme
    ];
  };

  pythonImportsCheck = [ "hilbertcurve" ];

  meta = with lib; {
    description = "Construct Hilbert Curves";
    homepage = "https://pypi.org/project/hilbertcurve/";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
