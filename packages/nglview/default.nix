{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  ipywidgets,
  jupyter-packaging,
  jupyterlab,
  jupyterlab-widgets,
  notebook,
  numpy,
  setuptools,
  setuptools-scm,
  wheel,
}:

buildPythonPackage rec {
  pname = "nglview";
  version = "3.1.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "nglviewer";
    repo = "nglview";
    rev = "v${version}";
    hash = "sha256-QY7rn6q67noWeoLn0RU2Sn5SeJON+Br/j+aNMlK1PDo=";
  };

  build-system = [
    jupyter-packaging
    setuptools
    setuptools-scm
    wheel
  ];

  dependencies = [
    ipywidgets
    notebook
    jupyterlab
    jupyterlab-widgets
    numpy
  ];

  pythonImportsCheck = [ "nglview" ];

  meta = with lib; {
    description = "Jupyter widget to interactively view molecular structures and trajectories";
    homepage = "https://github.com/nglviewer/nglview";
    changelog = "https://github.com/nglviewer/nglview/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
