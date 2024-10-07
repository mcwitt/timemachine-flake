{ lib
, buildPythonPackage
, fetchPypi
, setuptools
, wheel
, ipython
}:

buildPythonPackage rec {
  pname = "py3Dmol";
  version = "2.0.4";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-B5CcWHun5A0X4sqTgxk+rYB6+DT5VpsQjP94TsTPtSU=";
  };

  build-system = [
    setuptools
    wheel
  ];

  passthru.optional-dependencies = {
    ipython = [
      ipython
    ];
  };

  pythonImportsCheck = [ "py3Dmol" ];

  meta = with lib; {
    description = "An IPython interface for embedding 3Dmol.js views in Jupyter notebooks";
    homepage = "https://pypi.org/project/py3Dmol/";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
