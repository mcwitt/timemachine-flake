{ lib
, buildPythonPackage
, fetchPypi
, setuptools
, setuptools-scm
, wheel
, black
, ipython
, tokenize-rt
, build
, twine
, flake8
, flake8-docstrings
, flake8-import-order
, isort
, jupyterlab
, mypy
, pep8-naming
, playwright
, pytest
, tox
}:

buildPythonPackage rec {
  pname = "jupyter-black";
  version = "0.3.4";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-KjjzPUwyHrdo9CYQNjWsm4C0DJ5CqgYHKnKePK3cpMM=";
  };

  nativeBuildInputs = [
    setuptools
    setuptools-scm
    wheel
  ];

  propagatedBuildInputs = [
    black
    ipython
    tokenize-rt
  ];

  passthru.optional-dependencies = {
    dev = [
      build
      twine
      wheel
    ];
    test = [
      flake8
      flake8-docstrings
      flake8-import-order
      isort
      jupyterlab
      mypy
      pep8-naming
      playwright
      pytest
      tox
    ];
  };

  pythonImportsCheck = [ "jupyter_black" ];

  meta = with lib; {
    description = "A simple extension for Jupyter Notebook and Jupyter Lab to beautify Python code automatically using Black. Fork of dnanhkhoa/nb_black";
    homepage = "https://pypi.org/project/jupyter-black/";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
